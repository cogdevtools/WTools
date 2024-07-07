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
        subjects = WTDialogUtils.stringsSelectDlg('Select subjects:', subjects);
    end

    if isempty(subjects)
        wtLog.warn('User selected no subjects to process!'); 
        return
    end

    if interactive 
        conditions = WTDialogUtils.stringsSelectDlg('Select conditions:', conditions);
    end

    if isempty(conditions)
        wtLog.warn('User selected no conditions to process!'); 
        return
    end

    baselineChopParams = copy(baselineChopParams);
    
    while true
        if interactive
            logFlag = baselineChopParams.LogarithmicTransform;
            evokFlag = baselineChopParams.EvokedOscillations;

            if waveletTransformParams.exist() 
                logFlag = waveletTransformParams.LogarithmicTransform;
                evokFlag = waveletTransformParams.EvokedOscillations;
            end

            if ~WTBaselineChopGUI.defineBaselineChopParams(baselineChopParams, logFlag, evokFlag)
                return
            end
        elseif ~baselineChopParams.validate()
            wtLog.err('Baseline chopping params are not valid');
            return
        end

        measure = WTCodingUtils.ifThenElse(baselineChopParams.EvokedOscillations, ...
                    WTIOProcessor.WaveletsAnalisys_evWT, ...
                    WTIOProcessor.WaveletsAnalisys_avWT);

        % Load the first data set to get information like 'Fa' and 'tim'
        [success, data] = ioProc.loadWaveletsAnalysis(subjects{1}, conditions{1}, measure);
        if ~success 
            wtProject.notifyErr([],'Failed to load dataset for subject ''%s'', condition: ''%s''', subjects{1}, conditions{1});
            return
        end

        if checkAndAdjustBaselineChopParams(baselineChopParams, data)
            break
        end

        if ~interactive 
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
    logarithmicTransform = baselineChopParams.LogarithmicTransform && ~waveletTransformParams.LogarithmicTransform;

    if logarithmicTransform
        wtLog.info('Data will be log-transformed before baseline correction');
    end

    if baselineChopParams.NoBaselineCorrection
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
            
            if ~logarithmicTransform
                % Data must not be log10-ed or they have been already during Wavelet transform
                awt = data.WT(:,1:length(data.Fa),:);            
            else  
                % Data must not be log10-ed as they have not been during Wavelet transform and 
                % the user want so during chop & baseline correction         
                awt = log10(data.WT(:,1:length(data.Fa),:));            
            end
            
            if baselineChopParams.NoBaselineCorrection           
                subjMatrix = awt(:,:,chopMinIdx:chopMaxIdx);            
            else            
                bv = mean(awt(:,:,baselineMinIdx:baselineMaxIdx),3);            
                base = repmat(bv,[1,1,length(chopMinIdx:chopMaxIdx)]);           
                subjMatrix = awt(:,:,chopMinIdx:chopMaxIdx) - base;           
            end
            
            % In agreement to ERPWAVELAB file structure:
            data.WT = subjMatrix;
            data.tim = latencies;
            data.Fa = frequencies;

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

    if ~baselineChopParams.NoBaselineCorrection
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