% wtEGIToEEGLab.m
% Created by Eugenio Parise
% CDC CEU 2010
% Function to import netstation files in EEGLAB. Netstation files must be
% previously exported in .mat format, each trial in individual array. Only
% good segments must be exported. After importing the original dataset in
% one EEGLAB file, the script will segmented such file into multiple EEGLAB datasets:
% one for each experimental condition.
% To set this script to process the whole final sample of subjects in a study,
% edit 'subj.m' in the 'cfg' folder and digit wtEGIToEEGLab() (with no argument) at
% the console prompt.
%
% Usage:
%   wtEGIToEEGLab(subjects)
%   wtEGIToEEGLab('01');
%   wtEGIToEEGLab();

function wtEGIToEEGLab()
    wtProject = WTProject();
    wtLog = WTLog();
    wtLog.pushStatus().ctxOn('EGIToEEGLab');

    if ~wtProject.checkIsOpen()
        wtLog.popStatus();
        return
    end

    interactive = wtProject.Interactive;
    system = WTIOProcessor.SystemEGI;

    if interactive  
        [success, sbjFileNames] = wtSelectUpdateSubjects(system);
        if ~success
            wtLog.popStatus();
            return
        end  
        if ~wtSelectUpdateConditions(system, sbjFileNames{1}) || ~wtSelectUpdateChannels(system)
            wtLog.popStatus();
            return
        end
    else
        if ~wtProject.Config.Subjects.validate()
            wtProject.notifyErr('Subjects params are not valid');
            wtLog.popStatus();
            return
        end
    end

    ioProc = wtProject.Config.IOProc;
    subjectsPrms = wtProject.Config.Subjects;
    subjects = subjectsPrms.SubjectsList;
    subjectFileNames = subjectsPrms.FilesList;
    nSubjects = length(subjects);
    conditionsPrms = wtProject.Config.Conditions;
    conditions = conditionsPrms.ConditionsList;
    nConditions = length(conditions);
    channelsPrms = wtProject.Config.Channels;
    outFilesPrefix = wtProject.Config.Prefix.FilesPrefix;

    if nSubjects == 0 
        wtLog.warn('No subjects to process');
        wtLog.popStatus();
        return 
    end

    if ~wtSetSampleRate(system, subjectFileNames{1}) || ...
        ~setTriggerLatency() || ... 
        ~setMinMaxTrialId()
         return
    end

    [success, EGI2EEGLabPrms] = autoSetTriggerLatency(subjectFileNames{1});
    if ~success 
        return
    end

    samplingPrms = wtProject.Config.Sampling;

    for sbj = 1:nSubjects 
        subject = subjects{sbj};
        subjFileName = subjectFileNames{sbj}; 
        wtLog.info('Processing import file %s', subjFileName);

        [success, ALLEEG, EEG, ~] =  WTUtils.eeglabRun(WTLog.LevelDbg, true);
        if ~success 
            wtProject.notifyErr([], 'Failed to run eeglab');  
            wtLog.popStatus();      
            return
        end

        try
            eeg_getversion; % Introduced in EEGLAB v9.0.0.0b
            fileToImport = ioProc.getImportFile(subjFileName);
            deleteFileToImport = false;
        catch
            wtLog.info('Import file needs trial adjustment...');
            [success, data] = filterAndRenameDataFields(subjFileName); 
            if ~success 
                wtLog.popStatus();
                return
            end
            
            fileToImport = ioProc.getTemporaryFile();
            deleteFileToImport = true;

            if ~WTUtils.saveTo([], tempFileName, '-struct', 'data')
                wtProject.notifyErr([], 'Failed to save temporary data file with trial ajustments (%s)', subjFileName)
                wtLog.popStatus();
                return
            end
        end

        [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_importegimat', ...
            fileToImport, samplingPrms.SamplingRate, EGI2EEGLabPrms.TriggerLatency);

        if deleteFileToImport
            wtLog.dbg('Deleting temporary adjusted import file ''%s''', fileToImport);
            delete(fileToImport);
        end

        if ~success 
            wtProject.notifyErr([], 'Failed to import %s data file in eeglab:\n%s', ...
               fastif(deleteFileToImport, 'ADJUSTED ', ''), subjFileName);
            wtLog.popStatus();
            return   
        end

        [success, ALLEEG, EEG, CURRENTSET] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_newset', ...
            ALLEEG, EEG, 0, 'setname', subjects, 'gui', 'off');

        if ~success 
            wtProject.notifyErr([], 'Failed to create new eeglab set');
            wtLog.popStatus();
            return   
        end
        
        try
            if channelsPrms.ReReference ~= channelsPrms.ReReferenceNone
                EEG = restoreCzChannel(EEG, channelsPrms);
            end

            if ~isempty(channelsPrms.CutChannels)
                wtLog.info('Cutting channels: %s', char(join(channelsPrms.CutChannels, ',')));
                EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_select', EEG, 'nochannel', channelsPrms.CutChannels);
                EEG.nbchan = size(EEG.data, 1);
            end

            switch channelsPrms.ReReference
                case channelsPrms.ReReferenceWithAverage
                    wtLog.info('Re-referencing with average...');
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_reref', EEG, []);
                case channelsPrms.ReReferenceWithChannels
                    wtLog.info('Re-referencing with channels...');
                    chansIntersect = intersect(channelsPrms.CutChannels, channelsPrms.NewChannelsReference);
                    if ~isempty(chansIntersect)
                        wtProject.notifyErr([], 'Reference channels contains cut channel(s): %s', char(join(chansIntersect)));
                        wtLog.popStatus();
                        return
                    end
                    newRef = [];
                    for ch = 1:length(channelsPrms.NewChannelsReference)
                        actualChan = char(channelsPrms.NewChannelsReference(ch));
                        chanLabels = cat(1, {}, EEG.chanlocs(1,:).labels);
                        chanIdx = find(strcmp(chanLabels, actualChan));
                        newRef = cat(1, newRef, chanIdx);         
                    end
                    
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_reref', EEG, newRef ,'keepref','on');
                otherwise
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_chanedit', EEG, 'load', ...
                        { channelsPrms.ChannelsLocationFile, 'filetype', channelsPrms.ChannelsLocationFileType }, ...
                        'delete', 1, 'delete', 1, 'delete', 1, 'delete', 129);
            end
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to perform channels adjustment for subject ''%s''', subject);
            wtLog.popStatus();
            return
        end

        try 
            % Not sure that the instruction below is useful as repeated just after writeProcessedImport...
            [ALLEEG, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);
            
            [success, ~, EEG] = ioProc.writeProcessedImport(outFilesPrefix, subject, EEG);
            if ~success
                wtProject.notifyErr([], 'Failed to save processed import for subject ''%s''', subject);
                wtLog.popStatus();
                return
            end

            [ALLEEG, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to store EEGLAB data set for ''%s''', subject);
            wtLog.popStatus();
            return
        end

        [success, EEG] = ioProc.loadProcessedImport(outFilesPrefix, subject);
        if ~success 
            wtProject.notifyErr([], 'Failed to load processed import for subject ''%s''', subject);
            wtLog.popStatus();
            return
        end
        
        wtLog.info('Processing conditions...');
        wtLog.pushStatus().ctxOn().setHeaderOn(false);

        for cnd = 1:nConditions
            condition = conditions{cnd};
            wtLog.info('Condition ''%s''', condition);

            try
                cndSet = ioProc.getConditionSet(outFilesPrefix, subject, condition);
                [cndFileFullPath, ~, ~] = ioProc.getConditionFile(outFilesPrefix, subject, condition);

                EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_selectevent', ...
                    EEG,  'type', { condition }, 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');
                [ALLEEG, EEG, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_newset', ...
                    ALLEEG, EEG, 1, 'setname', cndSet, 'savenew', cndFileFullPath, 'gui', 'off');
                [ALLEEG, EEG, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_newset', ...
                    ALLEEG, EEG, cnd+1, 'retrieve', 1, 'study', 0);
                EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);  
            catch me
                wtLog.except(me);
                wtProject.notifyErr([], 'Failed to process/save condition ''%s'' for subject ''%s''', condition, subject);
                wtLog.popStatus(2);
                return
            end      
        end  

        wtLog.popStatus();
    end

    wtLog.popStatus();
    wtProject.notifyInf([], 'EGI -> EEGLab import completed!');
end

function success = setTriggerLatency()
    success = false;
    wtProject = WTProject();
    EGI2EEGLabPrms = copy(wtProject.Config.EGIToEEGLab);

    if ~WTConvertGUI.defineTriggerLatency(EGI2EEGLabPrms)
        return
    end
    
    if ~EGI2EEGLabPrms.persist()
        wtProject.notifyErr([], 'Failed to save trigger latency params');
        return
    end

    wtProject.Config.EGIToEEGLab = EGI2EEGLabPrms;
    success = true;
end

function [success, EGI2EEGLabPrms] = autoSetTriggerLatency(subjFileName)
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;
    EGI2EEGLabPrms = copy(wtProject.Config.EGIToEEGLab);
    samplingPrms = wtProject.Config.Sampling;

    if EGI2EEGLabPrms.TriggerLatency > 0
        success = true;
        return
    end
    % Set trigger latency from the exported .mat file (automatic time lock to the stimulus onset).
    [success, eciTCPIP] = ioProc.loadImport(WTIOProcessor.SystemEGI, subjFileName, 'ECI_TCPIP_55513');
    if ~success 
        wtProject.notifyErr([], 'Failed to read ECI_TCPIP_55513 from %s', subjFileName);
        return
    end
    EGI2EEGLabPrms.TriggerLatency = cell2mat(eciTCPIP(4,1))*(1000/samplingPrms.SamplingRate);
end

function success = setMinMaxTrialId()
    success = false;
    wtProject = WTProject();
    minMaxTrialIdPrms = copy(wtProject.Config.MinMaxTrialId);

    if ~WTConvertGUI.defineTrialsRangeId(minMaxTrialIdPrms)
        return
    end
    
    if ~minMaxTrialIdPrms.persist()
        wtProject.notifyErr([], 'Failed to save min/max trial id params');
        return
    end

    wtProject.Config.MinMaxTrialId = minMaxTrialIdPrms;
    success = true;
end

function [success, dataOut] = filterAndRenameDataFields(subjFileName)
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;
    dataOut = struct();

    [success, data] = ioProc.loadImport(WTIOProcessor.SystemEGI, subjFileName);
    if ~success 
        wtProject.notifyErr([], 'Failed to read subject data from %s', subjFileName);
        return
    end

    ioProc = wtProject.IOProc;
    selectedConditions = wtProject.Config.ConditionsList;
    minMaxTrialIdPrms = wtProject.Config.MinMaxTrialId;
    minMaxTrialIdPrms = minMaxTrialIdPrms.interpret();

    dataOut = struct();
    allTrials = minMaxTrialIdPrms.allTrials();
    minTrial = minMaxTrialIdPrms.MinTrialId;
    maxTrial = minMaxTrialIdPrms.MaxTrialId;

    data = orderfields(data);
    dataFields = fieldnames(data);
    % find the <condition>_Segment<#> fields
    reResult = regexp(dataFields, ioProc.EGIConditionSegmentFldRe, 'once', 'tokens');
    selected = ~cellfun(@isempty, reResult); 
    selectedIdxs = find(selected);
    % extract conditions name
    matches = reResult(selection);
    cndSeg = cat(1, matches{:});  % {{'cnd'}, {'seg'}}
    conditions = unique(cndSeg(:,1));
    % create a counters for each condition
    counters = cell2struct(repmat({zeros(1)}, 1, length(conditions)), conditions, 2);
    
    for i = 1:length(selectedIdxs)
        fldIdx = idxs(i);
        cndName = reResult{fldIdx}{1};
        if ~any(strcmp(cndName, selectedConditions)) % ignore unselected conditions
            continue
        end
        segNum = WTUtils.str2double(reResult{fldIdx}{2});
        if ~allTrials && (segNum < minTrial || segNum > maxTrial) % ignore trials out of rangre
            % not sure why when allTrials we should rename fields...
            continue
        end
        cndName = reResult{fldIdx}{1};
        newSegNum = counters.(fldName)+1;
        counters.(cndName) = newSegNum;
        newFieldName = [cndName '_Segment' num2str(newSegNum)];
        dataOut.(newFieldName) = data.(dataFields{fldIdx});
    end

    invariantFields = char(dataFields(~selected));
    dataOut.(invariantFields) = data.(invariantFields);
end


% Restore reference back (as if EEG was loaded with pop_importegimat.m, it was cut)
function EEG = restoreCzChannel(EEG, channelsPrms) 
    WTLog().info('Restoring Cz channel to apply re-referencing...');
    ref = zeros(1, size(EEG.data, 2), size(EEG.data, 3)); 
    EEG.data = cat(1, EEG.data, ref);
    EEG.nbchan = size(EEG.data, 1);
    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_chanedit', EEG,  'load', ...
        { channelsPrms.ChannelsLocationFile, 'filetype', channelsPrms.ChannelsLocationFileType }, ...
        'delete', 1, 'delete', 1, 'delete', 1);
end