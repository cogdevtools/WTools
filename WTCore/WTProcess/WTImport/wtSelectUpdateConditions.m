function success = wtSelectUpdateConditions(system, anImportedFile) 
    wtProject = WTProject();
    wtLog = WTLog();
    ioProc = wtProject.Config.IOProc;

    [success, conditions, ~] = ioProc.getConditionsFromImport(system, anImportedFile);
    if ~success
        wtLog.err('Failed to get conditions from imported file ''%s''', anImportedFile);
        return
    end

    success = false;
    conditions = WTDialogUtils.stringsSelectDlg('Select conditions', conditions, false, true);
    if isempty(conditions) 
        wtLog.warn('No conditions selected');
        return
    end

    conditionsPrms = copy(wtProject.Config.Conditions);
    conditionsPrms.ConditionsList = conditions;
    conditionsPrms.ConditionsDiff = {};

    if ~conditionsPrms.persist() 
        wtProject.notifyErr([], 'Failed to save import conditions params');
        return
    end

    wtProject.Config.Conditions = conditionsPrms;
    success = true;
end