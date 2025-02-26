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

function success = wtBaselineChop()
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkWaveletAnalysisDone() || ...
        ~wtProject.checkRepeatedChopAndBaselineCorrection()
        return
    end

    interactive = wtProject.Interactive;
    ioProc = wtProject.Config.IOProc;
    basicPrms = wtProject.Config.Basic;
    subjectsGrandParams = wtProject.Config.SubjectsGrand;
    conditionsGrandParams = wtProject.Config.ConditionsGrand;
    waveletTransformParams = wtProject.Config.WaveletTransform;
    baselineChopParams = wtProject.Config.BaselineChop;
    subjects = subjectsGrandParams.SubjectsList;
    conditions = conditionsGrandParams.ConditionsList;

    if interactive
        selectSubjectAndConditions = true;

        while true
            baselineChopParams = WTConfigUtils.sigprocConfigPreset(wtProject.Config, baselineChopParams);

            if waveletTransformParams.exist() && ~baselineChopParams.exist()
                % Estimation of the segment to chop, based on Eugenio Parise suggestion
                segmentToChop = 2000 / waveletTransformParams.FreqMin; 
                maxSegmentToChop = (waveletTransformParams.TimeMax - waveletTransformParams.TimeMin) / 2;

                if segmentToChop < maxSegmentToChop
                    baselineChopParams.ChopTimeMin = waveletTransformParams.TimeMin + segmentToChop;
                    baselineChopParams.ChopTimeMax = waveletTransformParams.TimeMax - segmentToChop;
                else
                    wtLog.warn('Chop segment estimation above data length: will be ignored!');
                    baselineChopParams.ChopTimeMin = waveletTransformParams.TimeMin;
                    baselineChopParams.ChopTimeMax = waveletTransformParams.TimeMax;
                end

                baselineChopParams.BaselineTimeMin = waveletTransformParams.TimeMin;
                baselineChopParams.BaselineTimeMax = baselineChopParams.ChopTimeMin;
                sampleRatePrms = wtProject.Config.Sampling;
                
                    % Estimation of the baseline segment, based on Eugenio Parise suggestion (100 samples)
                if sampleRatePrms.exist()
                    baselineTimeMax = baselineChopParams.BaselineTimeMin + (100*1000) / sampleRatePrms.SamplingRate;

                    if baselineTimeMax < baselineChopParams.ChopTimeMax
                        if baselineChopParams.BaselineTimeMin < 0 && baselineTimeMax > 0
                            baselineChopParams.BaselineTimeMax = 0; % set the time 0 as max extension
                        end
                        baselineChopParams.BaselineTimeMax = baselineTimeMax;
                    end
                end
            end
    
            if ~WTBaselineChopGUI.defineBaselineChopParams(baselineChopParams, true, true)
                return
            end
            
            if selectSubjectAndConditions
                selectSubjectAndConditions = false;

                measure = WTCodingUtils.ifThenElse(baselineChopParams.EvokedOscillations, ...
                            WTIOProcessor.WaveletsAnalisys_evWT, ...
                            WTIOProcessor.WaveletsAnalisys_avWT);
        
                subjects = WTDialogUtils.stringsSelectDlg('Select subjects:', subjects);
                if isempty(subjects)
                    wtLog.warn('User selected no subjects to process!'); 
                    return
                end
                
                conditions = WTDialogUtils.stringsSelectDlg('Select conditions:', conditions);
                if isempty(conditions)
                    wtLog.warn('User selected no conditions to process!'); 
                    return
                end

                % Load the first data set to get information like 'Fa' and 'tim'
                [success, data] = ioProc.loadWaveletsAnalysis(subjects{1}, conditions{1}, measure);
                if ~success 
                    wtProject.notifyErr([],'Failed to load dataset for subject ''%s'', condition: ''%s''', subjects{1}, conditions{1});
                    return
                end
            end

            if checkAndAdjustBaselineChopParams(baselineChopParams, data)
                break
            end
        end
    else
        if ~baselineChopParams.validate()
            wtLog.err('Baseline and/or chopping params are not valid');
            return
        end

        measure = WTCodingUtils.ifThenElse(baselineChopParams.EvokedOscillations, ...
                        WTIOProcessor.WaveletsAnalisys_evWT, ...
                        WTIOProcessor.WaveletsAnalisys_avWT);

        [success, data] = ioProc.loadWaveletsAnalysis(subjects{1}, conditions{1}, measure);
        if ~success 
            wtProject.notifyErr([],'Failed to load dataset for subject ''%s'', condition: ''%s''', subjects{1}, conditions{1});
            return
        end

        if ~checkAndAdjustBaselineChopParams(baselineChopParams, data)
            return
        end
    end

    if ~baselineChopParams.persist()
        wtProject.notifyErr([], 'Failed to save baseline corrections & edges chopping params');
        return
    end

    wtProject.Config.BaselineChop = baselineChopParams;
    wtLog.info('Baseline correction and edges chopping processing begin...');

    timeRes = data.tim(2) - data.tim(1); 
    latencies = baselineChopParams.ChopTimeMin : timeRes : baselineChopParams.ChopTimeMax;
    frequencies = data.Fa;
    chopMinIdx = find(data.tim == baselineChopParams.ChopTimeMin);
    chopMaxIdx = find(data.tim == baselineChopParams.ChopTimeMax);

    if ~baselineChopParams.BaselineSubtraction && ~baselineChopParams.BaselineNormalization
        wtLog.info('No baseline correction will be performed');
    else
        baselineMinIdx = find(data.tim == baselineChopParams.BaselineTimeMin);
        baselineMaxIdx = find(data.tim == baselineChopParams.BaselineTimeMax);
    end

    wtLog.pushStatus().contextOn().HeaderOn = false;

    for s = 1:length(subjects)
        for c = 1:length(conditions)
            wtLog.info('Processing subject %s, condition %s, measure %s', subjects{s}, conditions{c}, measure);
            
            [success, data] = ioProc.loadWaveletsAnalysis(subjects{s}, conditions{c}, measure);
            if ~success 
                wtProject.notifyErr([],'Failed to load dataset for subject ''%s'', condition: ''%s''', subjects{s}, conditions{c});
                wtLog.popStatus();
                return
            end

            wt = data.WT(:,1:length(data.Fa),:); 
            baseline = [];

            if waveletTransformParams.TransformPower 
                wt = wt .^ 2;
            end

            if ~baselineChopParams.BaselineSubtraction && ~baselineChopParams.BaselineNormalization
                wtLog.info('Chopping data: keeping time interval [%f, %f]...', ...
                    baselineChopParams.ChopTimeMin, baselineChopParams.ChopTimeMax);
                wt = wt(:,:,chopMinIdx:chopMaxIdx);
            else
                wtLog.info('Calculating baseline by averaging on time interval [%f, %f]', ...
                    baselineChopParams.BaselineTimeMin, baselineChopParams.BaselineTimeMax);

                baseline = mean(wt(:,:,baselineMinIdx:baselineMaxIdx),3);

                wtLog.info('Chopping data outside time interval [%f, %f] ...', ...
                    baselineChopParams.ChopTimeMin, baselineChopParams.ChopTimeMax); 

                if baselineChopParams.BaselineSubtraction
                    wtLog.info('Subtracting baseline...');
                    wt = wt(:,:,chopMinIdx:chopMaxIdx) - repmat(baseline,[1,1,length(chopMinIdx:chopMaxIdx)]);
                end

                if baselineChopParams.BaselineNormalization
                    if all(baseline ~= 0)
                        wtLog.info('Applying baseline based normalization...');
                        wt = wt ./ abs(baseline);
                    else
                        wtProject.notifyErr([],'Some baseline value is 0: normalization is not possible: subject ''%s'', condition: ''%s''', ... 
                            subjects{s}, conditions{c});
                        wtLog.popStatus();
                        return
                    end
                end
            end

            % In agreement to ERPWAVELAB file structure:
            data.WT = wt;
            data.tim = latencies;
            data.Fa = frequencies;
            % Additional information
            data.Power = logical(waveletTransformParams.TransformPower);
            data.Baseline = baseline;
            data.Normalized = logical(baselineChopParams.BaselineNormalization);
           
            [success, filePath] = ioProc.writeBaselineCorrection(subjects(s), conditions(c), measure, '-struct', 'data');
            if ~success 
                wtProject.notifyErr([], 'Failed to save basaline corrected & edge chopped data to ''%s''', filePath);
                wtLog.popStatus();
                return
            end
        end 
    end

    wtLog.popStatus();
    basicPrms.ChopAndBaselineCorrectionDone = 1;
    basicPrms.ConditionsDifferenceDone = 0;
    basicPrms.GrandAverageDone = 0;

    if ~basicPrms.persist()
        wtProject.notifyErr([], 'Failed to save basic configuration params related to the processing status.');
        return
    end

    wtProject.notifyInf([], 'Baseline correction and edges chopping processing completed!');
    success = true;
end


function success = checkAndAdjustBaselineChopParams(baselineChopParams, data)
    success = false;
    wtProject = WTProject();
    timeRes = data.tim(2) - data.tim(1); 
    chopMin = baselineChopParams.ChopTimeMin;
    chopMax = baselineChopParams.ChopTimeMax;
    baselineMin = baselineChopParams.BaselineTimeMin;
    baselineMax = baselineChopParams.BaselineTimeMax;
    timeMin = min(data.tim);
    timeMax = max(data.tim);

    errNotify = @(fmt, varargin)wtProject.notifyErr('Review parameter', fmt, varargin{:});

    if chopMin < timeMin || chopMin >= timeMax
        errNotify(['Then minimum of the chopping window, %.2f ms, is out of boundaries! ' ...
                   'Choose a value in [%.2f, %.2f) ms'], chopMin, timeMin, timeMax);
        return
    else
        chopMin = chopMin - mod(chopMin,timeRes);
        timeGTE = data.tim(data.tim >= chopMin);
        chopMin = timeGTE(1);
    end

    if chopMax > timeMax
        errNotify(['Then maximum of the chopping window, %.2f ms, is out of boundaries! ' ...
                   'Choose a value in (%.2f, %.2f] ms'], chopMax, timeMin, timeMax);
        return
    else
        chopMax = chopMax - mod(chopMax,timeRes);
        timeGTE = data.tim(data.tim >= chopMax);
        chopMax = timeGTE(1);
    end

    if baselineChopParams.BaselineSubtraction
        if baselineMin < timeMin || baselineMin >= timeMax
            errNotify(['Then minimum of the baseline window, %.2f ms, is out of boundaries! ' ...
                        'Choose a value in [%.2f, %.2f) ms'], baselineMin, timeMin, timeMax);
            return
        else
            baselineMin = baselineMin - mod(baselineMin,timeRes);
            timeGTE = data.tim(data.tim >= baselineMin);
            baselineMin = timeGTE(1);
        end
        if baselineMax > timeMax
            errNotify(['Then maximum of the baseline window, %.2f ms, is out of boundaries! ' ...
                   'Choose a value in (%.2f, %.2f] ms'], baselineMax, timeMin, timeMax);
            return
        else
            baselineMax = baselineMax - mod(baselineMax,timeRes);
            timeGTE = data.tim(data.tim >= baselineMax);
            baselineMax = timeGTE(1);
        end
    end

    baselineChopParams.ChopTimeMin = chopMin;
    baselineChopParams.ChopTimeMax = chopMax;
    baselineChopParams.BaselineTimeMin = baselineMin;
    baselineChopParams.BaselineTimeMax = baselineMax;
    success = true;
end