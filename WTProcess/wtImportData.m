function wtImportData() 
    ioProc = WTProject().Config.IOProc;
    wtLog = WTLog();
    importDir = ioProc.ImportDir;
    notImportedFiles = {};

    % This message is perhaps too annoying...
    % WTUtils.eeglabMsgDlg('Info', 'NOTE: only files with name format ''%s'' can be imported...', ioProc.ImportFileRe);

    while true
        [srcFiles, srcDir, ~] = WTUtils.uiGetFiles('*.mat', ...
            'Select all the files to import (EGI, EEP, ...)', 'MultiSelect', 'on');

        if isempty(srcFiles)
            return
        end

        for srcFile = srcFiles 
            srcFile = char(srcFile);
            srcPath = fullfile(srcDir, srcFile);

            if isempty(ioProc.getSubjectsFromImportFiles(srcFile))
                wtLog.err('Not a valid file name for import: %s', srcFile);
                notImportedFiles = [notImportedFiles srcPath];
                continue
            end 

            srcPath = fullfile(srcDir, srcFile);
            [copied, msg, ~] = copyfile(srcPath, importDir, 'f');

            if ~copied 
                wtLog.err('File ''%s'' could not be copied to ''%s'': %s', srcPath, importDir, msg);
                notImportedFiles = [notImportedFiles srcPath];
                continue
            end

            wtLog.info('File ''%s'' imported successfully', srcPath);
        end

        if ~WTUtils.eeglabYesNoDlg('Other imports', 'Continue to import?')
            break;
        end            
    end

    if ~isempty(notImportedFiles) 
        WTUtils.eeglabMsgDlg('Errors', 'The following files could not be imported. Check the log...\n%s', ... 
            char(join(notImportedFiles, '\n')));
    end
end