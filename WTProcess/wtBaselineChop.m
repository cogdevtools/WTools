% wtBaselineChop.m
% Created by Eugenio Parise
% CDC CEU 2010 - 2011
% Function to baseline correct and chop ERPWAVELABv1.1 compatible data files.
% To set this script to process the whole final sample of subjects in a study,
% edit 'subj.m' in the 'cfg' folder and digit wtBaselineChop([],...); ([]=empty).
% Add 'evok' as last argument to compute baseline correction of evoked
% oscillations (of course, if they have been previously computed).
%
% Usage:
%
% wtAverage(subject,timewindow begin,timewindow end,baseline begin,baseline end,higher...
% frequency,lower frequency,log-transformation,no baseline correction);
%
% wtBaselineChop('01',-200,1200,-200,0,0,0);
% wtBaselineChop([],-200,1200,-200,0,1,0);
% wtBaselineChop([],-200,1200,[],[],0,1,'evok');

function success = wtBaselineChop()
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkIsOpen()
        return
    end

    interactive = wtProject.Interactive;
    ioProc = wtProject.Config.IOProc;
    subjectsGrandParams = wtProject.Config.SubjectsGrand;
    conditionsGrandParams = wtProject.Config.ConditionsGrand;
    waveletTransformParams = wtProject.Config.WaveletTransform;
    baselineChopParams = wtProject.Config.BaselineChop;
    subjects = subjectsGrandParams.SubjectsList;
    conditions = conditionsGrandParams.ConditionsList;

    if ~subjectsGrandParams.exist() || ~waveletTransformParams.exist()
        wtProject.notifyWrn([], 'Before to execute baseline correction & edges chopping, apply wavelet transformation...');
        return
    end

    if interactive 
        subjects = WTUtils.stringsSelectDlg('Select subjects:', subjects);
    end

    if isempty(subjects)
        wtLog.warn('User selected no subjects to process!'); 
        return
    end

    if interactive 
        conditions = WTUtils.stringsSelectDlg('Select conditions:', conditions);
    end

    if isempty(conditions)
        wtLog.warn('User selected no conditions to process!'); 
        return
    end

    baselineChopParams = copy(baselineChopParams);
    
    while true
        if interactive 
            if ~WTBaselineChopGUI.defineBaselineChopParams(waveletTransformParams, baselineChopParams)
                return
            end
        elseif ~baselineChopParams.validate()
            wtLog.err('Baseline chopping params are not valid');
            return
        end

        measure = WTUtils.ifThenElse(baselineChopParams.EvokedOscillations, ...
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
    latencies = baselineChopParams.ChopMin : timeRes : baselineChopParams.ChopMax;
    frequencies = data.Fa;
    chopMinIdx = find(data.tim == baselineChopParams.ChopMin);
    chopMaxIdx = find(data.tim == baselineChopParams.ChopMax);

    if baselineChopParams.Log10Enable
        wtLog.info('Data will be log-transformed before baseline correction');
    end

    if baselineChopParams.NoBaselineCorrection
        wtLog.info('No baseline correction will be performed');
    else
        baselineMinIdx = find(data.tim == baselineChopParams.BaselineMin);
        baselineMaxIdx = find(data.tim == baselineChopParams.BaselineMax);
    end

    wtLog.pushStatus().ctxOn().setHeaderOn(false);

    for s = 1:length(subjects)
        for c = 1:length(conditions)
            wtLog.info('Processing subject %s, condition %s, measure %s', subjects{s}, conditions{c}, measure);
            
            [success, data] = ioProc.loadWaveletsAnalysis(subjects{s}, conditions{c}, measure);
            if ~success 
                wtProject.notifyErr([],'Failed to load dataset for subject ''%s'', condition: ''%s''', subjects{s}, conditions{c});
                wtLog.popStatus();
                return
            end
            
            if ~baselineChopParams.Log10Enable 
                awt = data.WT(:,1:length(data.Fa),:);            
            else            
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
    wtProject.notifyInf([], 'Baseline correction and edges chopping processing completed!');
    success = true;
end


function success = checkAndAdjustBaselineChopParams(baselineChopParams, data)
    success = false;
    wtProject = WTProject();
    timeRes = data.tim(2) - data.tim(1); 
    chopMin = baselineChopParams.ChopMin;
    chopMax = baselineChopParams.ChopMax;
    baselineMin = baselineChopParams.BaselineMin;
    baselineMax = baselineChopParams.BaselineMax;
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

    baselineChopParams.ChopMin = chopMin;
    baselineChopParams.ChopMax = chopMax;
    baselineChopParams.BaselineMin = baselineMin;
    baselineChopParams.BaselineMax = baselineMax;
    success = true;
end