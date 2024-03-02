% Function for internal use only...
    
function success = wtExtractConditions(subject)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkIsOpen()
        return
    end

    ioProc = wtProject.Config.IOProc;
    conditions = wtProject.Config.Conditions.ConditionsList;
    nConditions = length(conditions);
    outFilesPrefix = wtProject.Config.Prefix.FilesPrefix;

    [success, EEG, ALLEEG] = ioProc.loadProcessedImport(outFilesPrefix, subject);
    if ~success 
        wtProject.notifyErr([], 'Failed to load processed import for subject ''%s''', subject);
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
            success = false;
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to process/save condition ''%s'' for subject ''%s''', condition, subject);
            wtLog.popStatus();
            return
        end      
    end 
    
    wtLog.popStatus();
end