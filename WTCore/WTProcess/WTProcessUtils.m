% Copyright (C) 2024 Eugenio Parise, Luca Filippin
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.

classdef WTProcessUtils

    properties(Constant, Access = private)
        DCShiftMinimumFactor    = 0.01;
        DCShiftEpsilonAmplitude = 10^-6;
        DCShiftEpsilonPower     = 10^-12;
    end

    methods(Static)
        function success = sanitizeSubjectsLists()
            success = false;
            wtProject = WTProject();
            wtLog = WTLog().contextOn('SubjectsListSanitation');
            ioProc = wtProject.Config.IOProc;
            sbjsPrms = copy(wtProject.Config.Subjects);
            sbjsGrdPrms = copy(wtProject.Config.SubjectsGrand);

            sbjsImp = sbjsPrms.ImportedSubjectsList;
            sbjsSel = sbjsPrms.SubjectsList;
            sbjsGrd = sbjsGrdPrms.SubjectsList;
            updSbjs = false;
            updSbjsGrd = false;

            sbjsAll = ioProc.getImportedSubjects();
            sbjsImpNew = intersect(sbjsImp, sbjsAll);

            if length(sbjsImpNew) ~= length(sbjsImp)
                wtLog.info('Imported subjects list will be sanitized. Pruned subjects: [%s]', ...
                    char(join(setdiff(sbjsImp, sbjsAll), ',')));
                sbjsPrms.ImportedSubjectsList = sbjsImpNew;
                updSbjs = true;
            end
    
            sbjsSelNew = intersect(sbjsSel, sbjsImpNew);
            sbjsGrdNew = intersect(sbjsGrd, sbjsSelNew);

            if length(intersect(sbjsSel, sbjsSelNew)) ~= length(sbjsSel)
                wtLog.info('Subjects list will be sanitized. Pruned subjects: [%s]', ...
                    char(join(setdiff(sbjsSel, sbjsSelNew), ',')));
                sbjsPrms.SubjectsList = sbjsSelNew;
                updSbjs = true;
            end
            
            if length(intersect(sbjsGrd, sbjsGrdNew)) ~= length(sbjsGrd)
                wtLog.info('Subjects grand list will be sanitized. Pruned subjects: [%s]', ...
                    char(join(setdiff(sbjsGrd, sbjsGrdNew), ',')));
                sbjsGrdPrms.SubjectsList = sbjsGrdNew;
                updSbjsGrd = true;
            end

            success = true;

            if updSbjs
                if  ~sbjsPrms.persist()
                    wtLog.err('Failed to save sanitized subjects lists');
                    success = false;
                else
                    wtProject.Config.Subjects = sbjsPrms;
                    updSbjsGrd = false;
                end
            end

            if updSbjsGrd 
                if ~sbjsGrdPrms.persist()
                    wtLog.err('Failed to save sanitized subjects grand list');
                    success = false;
                else
                    wtProject.Config.SubjectsGrand = sbjsGrdPrms;
                end
            end

            wtLog.contextOff();
        end

        % subject empty => load grand average
        function [success, data] = loadAnalyzedData(perSubject, subject, condition, measure) 
            wtProject = WTProject();
            ioProc = wtProject.Config.IOProc;
            grandAverage = isempty(subject);
        
            if grandAverage
                [success, data] = ioProc.loadGrandAverage(condition, measure, perSubject);
            else
                [success, data] = ioProc.loadBaselineCorrection(subject, condition, measure);
            end
            if ~success 
                wtProject.notifyErr([], 'Failed to load data for condition ''%s''', condition);
            end
        end

        % Users should pay attention to edge effects when applying wavelet analysis. Wavelet coefficients are computed 
        % by convolving the wavelet kernel with the time series. Similarly to any convolution of signals, there is zero 
        % or other kind of padding at the edges of the time series and therefore the wavelet coefficients are weaker at 
        % the beginning and end of the time series.
        % More precisely, if f is your frequency of interest, you can expect the edge effects to span over FWHM_t secs:
        %
        % FWHM_t = (FWHM_tc * Fc / f) / 2. 
        %
        % WTools generates a set of Morlet wavelets such that Fc = f for each frequence of interest, so FWHM_t equals
        % FWHM_tc / 2. FWHM_tc is the temporal resolution of the wavelet, that is the Full Width Half Maximum of the 
        % Gaussian kernel of the wavelet. The function below returns exatcly that value.
        %
        % References: 
        % - https://neuroimage.usc.edu/brainstorm/Tutorials/TimeFrequency
        % - https://www.sciencedirect.com/science/article/abs/pii/S1053811919304409
        function FWHM = morletKernelFWHM(signalSamplingRate, timeResolution, normalizedWavelet, waveletFreq, waveletCycles)
            Fs = double(signalSamplingRate) / double(timeResolution);

            function FWHMf = FWHMAtFreq(wvFreq)
                sigmaT = double(waveletCycles) / (2*double(wvFreq)*pi);
                expFact = 1/(Fs*sigmaT*sqrt(pi));
                if normalizedWavelet 
                    expFact = sqrt(expFact);
                end
                y = expFact/2; % expFact is the max amplitude (occurring at time 0)
                FWHMf = 2*sqrt(-2*(sigmaT^2)*log(1/expFact * y));
            end

            if isscalar(waveletFreq) 
                FWHM = FWHMAtFreq(waveletFreq);
            else
                FWHM = arrayfun(@FWHMAtFreq, waveletFreq);
            end
        end


        % CWTDCShift takes a CWT matrix of size (channels, frequencies, time) and applies a DC shift to ensure that the 
        % resulting signal has values > 0.
        function [WT, dc] = CWTDCShift(WT, isPower, perChannel, perFrequency, perTime)
            epsilon = WTCodingUtils.ifThenElse(isPower, WTProcessUtils.DCShiftEpsilonPower, WTProcessUtils.DCShiftEpsilonAmplitude);
            [WT, dc] = wtDCShift(WT, WTProcessUtils.DCShiftMinimumFactor,  epsilon, perChannel, perFrequency, perTime);
        end

        % ToDecibel takes a matrix convert it in Decibel value. The matrix must contain only positive values. If the 
        % values represent power, then the isPower parameter must be set to true.
        function data = ToDecibel(data, isPower)
            data = WTCodingUtils.ifThenElse(isPower, @()10*log(data), @()20*log(data));
        end

        function [data, dc] = DCShiftAndConvertToDecibel(data, isPower)
            minVal = min(data);
            epsilon = WTCodingUtils.ifThenElse(isPower, WTProcessUtils.DCShiftEpsilonPower, WTProcessUtils.DCShiftEpsilonAmplitude); 
            dc = WTCodingUtils.ifThenElse(minVal <= 0, @()-minVal + max(WTProcessUtils.DCShiftMinimumFactor * abs(minVal), epsilon), 0);
            data = WTProcessUtils.ToDecibel(data + dc, isPower);
        end        
    end
end
