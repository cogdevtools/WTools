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

function success = wtPerformCWT()
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkImportDone() || ...
        ~wtProject.checkRepeatedWaveletAnalysis()
        return
    end

    interactive = wtProject.Interactive;

    if interactive || isempty(wtProject.Config.WaveletTransform.ChannelsList)
        [success, timeRange, maxFreq, maxChans] = getTransformDomain(); 
        if ~success 
            return
        end
    end

    if interactive
        if ~selectUpdateSubjectsGrand() || ~selectUpdateConditionsGrand()
            return
        end
        if ~setTransformPrms(timeRange, maxFreq, maxChans)
            return
        end
    end

    ioProc = wtProject.Config.IOProc;
    basicParams = wtProject.Config.Basic;
    waveletTransformParams = wtProject.Config.WaveletTransform;
    
    timeMin = single(waveletTransformParams.TimeMin);
    timeMax = single(waveletTransformParams.TimeMax);
    channelsList = waveletTransformParams.ChannelsList;

    if isempty(channelsList)
        channelsList = 1:maxChans;
    end

    subjects = wtProject.Config.SubjectsGrand.SubjectsList;
    conditions = wtProject.Config.ConditionsGrand.ConditionsList;
    subjectsCount = length(subjects);
    conditionsCount = length(conditions);

    wtLog.info('Performing time/frequency analysis...');

    for i = 1:subjectsCount
        for j = 1:conditionsCount
            wtLog.info('Processing subject/condition: %d/%d', i, j);
            wtLog.pushStatus().contextOn('Subj(%s)/Cond(%s)', subjects{i}, conditions{j});
            doItOnce = i == 1 && j == 1;

            [success, EEG] = ioProc.loadCondition(basicParams.FilesPrefix, subjects{i}, conditions{j});
            if ~success
                wtLog.popStatus();
                return
            end 

            % Adjust ecpochs list
            nEpochs = size(EEG.data, 3);
            adjEpochsList = waveletTransformParams.EpochsList(waveletTransformParams.EpochsList <= nEpochs);
    
            % Round times to 0 in case they are in floating point format
            EEG.times = round(EEG.times);
                
            if waveletTransformParams.EvokedOscillations
                EEG.data = mean(EEG.data,3);
                EEG.trials = 1;
                EEG.epoch = EEG.epoch(1);
                EEG.event = EEG.event(1);
            end
    
            % Extend the edges before starting the wavelet transformation
            if (waveletTransformParams.EdgePadding / waveletTransformParams.FreqMin) >= 1 % There is edges padding
                timeToAdd = single(waveletTransformParams.EdgePadding);
                % To avoid distortions the padding will be performed to the left and to the right of the epoch.
                try
                    timeRes = EEG.times(2) - EEG.times(1); % find time resolution
                catch % Find time resolution and restore EEG.times when there is only one trial (e.g. for evoked oscillations).
                    EEG.times = (EEG.xmin*1000) : (1000/EEG.srate) : ((EEG.xmax*1000)+(1000/EEG.srate));
                    timeRes = EEG.times(2) - EEG.times(1);
                end
                
                pointsToAdd = floor(timeToAdd/timeRes); % Number of points to add to the left and to the right
                timeToAdd = pointsToAdd * timeRes;

                leftEdge = EEG.data(:,1:pointsToAdd,:); % We double the edges of the actual signal...
                leftEdge = leftEdge(:,end:-1:1,:);      % ... and revert them
                rightEdge = EEG.data(:,end-pointsToAdd+1:end,:);
                rightEdge = rightEdge(:,end:-1:1,:);
                
                EEGtemp = EEG.data;
                EEGnew = cat(2, leftEdge, EEGtemp); % add to the left
                EEGnew = cat(2, EEGnew, rightEdge);  % add to the right
                EEG.data = EEGnew;
                
                % Adjust other EEGlab variables accordingly (for consistency)
                EEG.times = min(EEG.times)-timeToAdd : timeRes : max(EEG.times)+timeToAdd;
                EEG.xmin = EEG.times(1)/1000;
                EEG.xmax = EEG.times(end)/1000;
                EEG.pnts = EEG.pnts + 2*pointsToAdd; % 2 because we add both to left and right of the segment
                
                % Adjust times limits according to the sampling and the new edges
                % and find them as timepoints in EEG.times
                if doItOnce 
                    timeMin = floor(timeMin/timeRes) * timeRes;
                    timeMin = timeMin - timeToAdd;
                    timeMax = ceil(timeMax/timeRes) * timeRes;
                    timeMax = timeMax + timeToAdd;
                end
                
            else % There is no edges padding
                try
                    timeRes = EEG.times(2) - EEG.times(1); % find time resolution
                catch % Find time resolution and restore EEG.times when there is only one trial (e.g. for evoked oscillations).
                    EEG.times = (EEG.xmin*1000) : (1000/EEG.srate) : ((EEG.xmax*1000)+(1000/EEG.srate));
                    timeRes = EEG.times(2) - EEG.times(1);
                end
                
                EEG.times = min(EEG.times) : timeRes : max(EEG.times);
                
                % Adjust times limits according to the sampling and the new edges
                % and find them as timepoints in EEG.times
                if doItOnce 
                    timeMin = floor(timeMin/timeRes) * timeRes;   
                    timeMax = ceil(timeMax/timeRes) * timeRes;                
                end
            end
    
            % Calculate wavelets at each frequency (once)
            if doItOnce
                timeMinIdx = find(EEG.times == timeMin);
                timeMaxIdx = find(EEG.times == timeMax);  
                [cwMatrix, Fa] = generateMorletWavelets(EEG.srate);   
                
                if waveletTransformParams.LogarithmicTransform 
                    wtLog.warn('Epochs will be log-transformed after wavelet transformation!');
                end
            end
            
            [success, ~] = wtAverage(EEG, waveletTransformParams, subjects{i}, conditions{j}, Fa, timeMinIdx, timeMaxIdx, 'cwt', ...
                channelsList, {WTIOProcessor.WaveletsAnalisys_avWT}, 0, adjEpochsList, cwMatrix);

            if ~success
                wtLog.popStatus(); 
                return
            end

            WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
            wtLog.popStatus(); 
        end
    end

    basicParams.WaveletAnalysisDone = 1;
    basicParams.ChopAndBaselineCorrectionDone = 0;
    basicParams.ConditionsDifferenceDone = 0;
    basicParams.GrandAverageDone = 0;

    if ~basicParams.persist()
        wtProject.notifyErr([], 'Failed to save basic configuration params related to the processing status.');
        return
    end

    wtProject.notifyInf([], 'Time/Frequency analysis completed!');
    success = true;
end

function success = selectUpdateSubjectsGrand() 
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();

    subjectsGrand = copy(wtProject.Config.SubjectsGrand);
    subjectsList = wtProject.Config.Subjects.SubjectsList;

    if isempty(subjectsList)
        wtProject.notifyWrn([], 'Empty subjects list');
        return
    end 

    subjectsList = WTDialogUtils.stringsSelectDlg('Select subjects\nto transform:', subjectsList);
    if isempty(subjectsList)
        wtLog.warn('User selected no subjects to process!'); 
        return
    end

    subjectsGrand.SubjectsList = subjectsList;

    if ~subjectsGrand.persist()
        wtProject.notifyErr([],'Failed to save subjects grand params');
        return
    end

    wtProject.Config.SubjectsGrand = subjectsGrand;
    success = true;
end

function success = selectUpdateConditionsGrand() 
    success = false;
    wtProject = WTProject();

    condsGrand = wtProject.Config.ConditionsGrand;
    conditionsList = wtProject.Config.Conditions.ConditionsList;

    if isempty(conditionsList)
        wtProject.notifyWrn([],'Empty conditions list');
        return
    end

    conditionsList = WTDialogUtils.stringsSelectDlg('Select conditions to\ntransform:', conditionsList);
    if isempty(conditionsList)
        wtLog.warn('User selected no conditions to process!'); 
        return
    end

    condsGrand.ConditionsList = conditionsList;
    condsGrand.ConditionsDiff = {};

    if ~condsGrand.persist() 
        wtProject.notifyErr([],'Failed to save conditions grand params');
        return
    end

    wtProject.Config.ConditionsGrand = condsGrand;
    success = true;
end

function [success, timeRange, maxFreq, maxChans] = getTransformDomain() 
    success = false;
    timeRange = [];
    maxFreq = 0;
    maxChans = 0;
    
    wtProject = WTProject();
    subjectsPrms = wtProject.Config.Subjects;
    conditionsPrms = wtProject.Config.Conditions;
    
    if numel(subjectsPrms.SubjectsList) == 0
        wtProject.notifyErr([],'Empty subjects list');
        return
    end

    if numel(conditionsPrms.ConditionsList) == 0
        wtProject.notifyErr([],'Empty conditions list');
        return
    end

    [success, EEG] = wtProject.Config.IOProc.loadCondition(wtProject.Config.Basic.FilesPrefix, ...
        subjectsPrms.SubjectsList{1}, conditionsPrms.ConditionsList{1}, false);

    if ~success 
        wtProject.notifyErr([],'Can''t determine CWT transform domain');
        return 
    end

    timeRange = int64([EEG.xmin*1000 EEG.xmax*1000]);
    maxFreq = EEG.srate/2;
    maxChans = size(EEG.data, 1);
end

function success = setTransformPrms(timeRange, maxFreq, maxChans) 
    success = false;
    wtProject = WTProject();

    waveletTransformParams = copy(wtProject.Config.WaveletTransform);
    baselineChopParams = wtProject.Config.BaselineChop;

    if waveletTransformParams.exist()
        if baselineChopParams.exist() && ... 
            waveletTransformParams.LogarithmicTransform && ...
            ~baselineChopParams.LogarithmicTransform
            wtProject.notifyErr([], 'Inconsistent Log10 flag in %s & %s configuration files', ...
                waveletTransformParams.getFileName(), baselineChopParams.getFileName());
            return
        end
    end

    if ~WTTransformGUI.defineCWTParams(waveletTransformParams, timeRange, maxFreq, maxChans)
        return
    end

    if ~waveletTransformParams.persist() 
        wtProject.notifyErr([],'Failed to save complex Morlet transform params');
        return
    end

    wtProject.Config.WaveletTransform = waveletTransformParams;
    success = true;
end

function [cwMatrix, scales] = generateMorletWavelets(samplingRate)
    waveletTransformParams = WTProject().Config.WaveletTransform;
    scales = (waveletTransformParams.FreqMin : waveletTransformParams.FreqRes : waveletTransformParams.FreqMax);
    normalized = waveletTransformParams.NormalizedWavelets;
    Fs = double(samplingRate) / double(waveletTransformParams.TimeRes);
    cwMatrix = cell(length(scales),2);
    wtLog = WTLog();

    % Calculate CWT at each frequency.
    wtLog.info('Computing Morlet complex wavelets with %d cycles...', ...
        waveletTransformParams.WaveletsCycles);
    wtLog.pushStatus().contextOn('Complex Wavelets').HeaderOn = false;

    for iFreq=1:(length(scales))
        freq = double(scales(iFreq));
        sigmaT = double(waveletTransformParams.WaveletsCycles) / (2*freq*pi);
        % The exponentialFactor is set depending on if we want to enerate wavelets with unit energy (normalized) or not
        exponentialFact = WTCodingUtils.ifThenElse(normalized, ...
            @()1/sqrt(Fs*sigmaT*sqrt(pi)), @()1/(Fs*sigmaT*sqrt(pi)));
        % Calculate the time at which the wavelet certainly goes below the value 0.00001, to set its extension
        timeToZero = sigmaT * sqrt(-2*log(0.00001/exponentialFact)); 
        timeToZero = ceil(timeToZero * Fs) / Fs;
        time = -timeToZero : 1/Fs : timeToZero;
        waveletScale = exponentialFact.*exp(((time.^2)/(-2*(sigmaT^2))));
        waveletRe = waveletScale.*cos(2*pi*freq*time);
        waveletIm = waveletScale.*sin(2*pi*freq*time);
        cwMatrix{iFreq,1} = waveletRe(1,:);
        cwMatrix{iFreq,2} = waveletIm(1,:);

        [success, FWHMTime] = findMorletFWHM(time, waveletRe);
        FWHMStr = WTCodingUtils.ifThenElse(success, @()sprintf(', FWHM-Time = %.3f secs', FWHMTime), '');
        wtLog.info('Fc = %.2f Hz, #samples = %d, time range = [ -%.2f/Fc, +%.2f/Fc ] = [-%.3f, +%.3f] secs, %s...', ... 
            freq, length(time), timeToZero * freq, timeToZero * freq, timeToZero, timeToZero, FWHMStr);
    end

    wtLog.popStatus().info('Wavelets saved in cell array matrix');
end

% findMorletFWHM() assumes fx to be a Morlet Wavelet real component and find the relative FWHM.
% Credits: https://fr.mathworks.com/matlabcentral/fileexchange/16130-findfwhm
function [success, FWHM] = findMorletFWHM(x, fx)
    success = false;
    FWHM = [];
    nX = length(fx);
    hMax = max(fx) / 2;
    idxs = find(fx >= hMax);
    idxLM = min(idxs);			
    idxRM = max(idxs);
   
    if fx(idxLM) == hMax
        xL = x(idxLM);
    elseif idxLM > 1 && fx(idxLM-1) <= hMax % interpolate assuming decreasing values on decreasing x
        xL = (x(idxLM)-x(idxLM-1))*(hMax-fx(idxLM-1))/(fx(idxLM)-fx(idxLM-1))+x(idxLM-1);
    else
        return
    end
    if fx(idxRM) == hMax
        xR = x(idxRM);
    elseif idxRM < nX  && fx(idxRM+1) <= hMax  % interpolate assuming decreasing values on increasing x
        xR = (x(idxRM+1)-x(idxRM))*(fx(idxRM+1)-hMax)/(fx(idxRM+1)-fx(idxRM))+x(idxRM);
    else
        return
    end

    FWHM = abs(xR-xL);
    success = true;
end