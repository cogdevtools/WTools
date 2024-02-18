% eggl2eegl.m
% Created by Eugenio Parise
% Lancaster University 2017
% Function to import segmented EEGLAB datasets in EEGLAB/WTools. Files must be
% in .set format (including a separate .fdt), and already segmented/cleaned. Only
% good segments are assumed to be in the dataset. After importing the original dataset in
% EEGLAB/WTools, the script will segmented the file into multiple EEGLAB datasets:
% one for each experimental condition.
% Call the script from the main WTools GUI.
% NON GUI USAGE (not tested!):
% To set this script to process the whole final sample of subjects in a study,
% edit 'subj.m' in the 'cfg' folder and digit wtEEGLabToEEGLab() (with no argument) at
% the console prompt.
% 
% Usage:
% 
% wtEEGLabToEEGLab(subjects)
% 
% wtEEGLabToEEGLab('01');
% wtEEGLabToEEGLab();

function wtEEGLabToEEGLab()
    wtProject = WTProject();
    wtLog = WTLog();
    wtLog.pushStatus().ctxOn('EEGLabToEEGLab');

    if ~wtProject.checkIsOpen()
        wtLog.popStatus();
        return
    end

    interactive = wtProject.Interactive;
    system = WTIOProcessor.SystemEEGLab;

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

    if ~wtSetSampleRate(system, subjectFileNames{1})
         return
    end

    for sbj = 1:nSubjects 
        subject = subjects{sbj};
        subjFileName = subjectFileNames{sbj}; 
        wtLog.info('Processing import file %s', subjFileName);

        [success, ALLEEG, ~, ~] =  WTUtils.eeglabRun(WTLog.LevelDbg, true);
        if ~success 
            wtProject.notifyErr([], 'Failed to run eeglab');  
            wtLog.popStatus();      
            return
        end

        [success, EEG] = ioProc.loadImport(system, subjFileName);
        if ~success 
            wtProject.notifyErr([], 'Failed to load import: ''%s''', ioProc.getImportFile(subjFileName));
            wtLog.popStatus();
            return   
        end

        [success, ALLEEG, EEG, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'eeg_store', ALLEEG, EEG, 0);
        if ~success 
            wtProject.notifyErr([], 'Failed to create store data in eeglab');
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

        if ~isempty(channelsPrms.CutChannels)
            wtLog.info('Cutting channels: %s', char(join(channelsPrms.CutChannels, ',')));
            [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_select', EEG, 'nochannel', channelsPrms.CutChannels);
            if ~success 
                wtProject.notifyErr([], 'Failed cut channels');
                wtLog.popStatus();
                return   
            end
            EEG.nbchan = size(EEG.data, 1);
        end

        try 
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
                        { channelsPrms.ChannelsLocationFile, 'filetype', channelsPrms.ChannelsLocationFileType });
            end
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to perform channels re-referencing for subject ''%s''', subject);
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
    wtProject.notifyInf([], 'EEGLab -> EEGLab import completed!');
end

