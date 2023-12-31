function subjects = wtImportSubjectsSelectGUI() 
    ioProc = WTProject().Config.IOProc;
    wtLog = WTLog();
    subjects = [];

    fileNames = ioProc.getImportFiles();
    if isempty(fileNames) 
        WTUtils.eeglabMsgDlg('Warn', 'No import files found');
        return
    end

    fileNames = WTUtils.stringsSelectDlg('Select subjects\nfiles to import', fileNames, false, true);
    if isempty(fileNames) 
        wtLog.warn('No subject selected as no import files have been selected');
        return
    end

    subjectsNum = WTIOProcessor.getSubjectNumberFromImport(fileNames{:});
    if isempty(subjectsNum)
        wtLog.warn('No subject numbers could be found');
        return
    end
    formatNum = @(n)(sprintf('%02d', n)); 
    subjects = arrayfun(formatNum, subjectsNum, 'UniformOutput', false);
end    