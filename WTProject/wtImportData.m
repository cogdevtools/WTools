function wtImportData() 
    ioProc = WTProject().Config.IOProc;
    wtLog = WTLog();
    importDir = ioProc.ImportDir;
    notImportedFiles = {};

    % This message is perhaps too annoying...
    % WTUtils.eeglabMsgDlg('Info', 'NOTE: only files with name format ''%s'' can be imported...', ioProc.ImportFileRe);

    systemTypes = WTIOProcessor.getSystemTypes();
    system = WTUtils.stringsSelectDlg('Source system', systemTypes, true, false, 'ListSize', [200,100]);
    if isempty(system) 
        return
    end

    system = char(system);
    wtLog.info('User selected system ''%s''', system);

    while true
        fileExt = ['*.' WTIOProcessor.getSystemImportFileExtension(system)];
        fileFilter = {fileExt, sprintf('%s (%s)', system, fileExt)};

        [srcFiles, srcDir, ~] = WTUtils.uiGetFiles(fileFilter, ...
            sprintf('Select all the files to import from %s system',  system), ...
            'MultiSelect', 'on');

        if isempty(srcFiles) 
            if WTUtils.eeglabYesNoDlg('Confirm', 'Quit import?')
                return
            end
            continue
        end

        for srcFileCell = srcFiles 
            srcFile = char(srcFileCell);
            srcPath = fullfile(srcDir, srcFile);

            if isempty(ioProc.getSubjectsFromImportFiles(system, srcFile))
                wtLog.err('Not a valid %s file name for import: %s', system, srcFile);
                notImportedFiles = [notImportedFiles srcPath];
                continue
            end 

            srcPath = fullfile(srcDir, srcFile);
            filesToCopy = {srcPath};
            extraImportFiles = WTIOProcessor.getSystemExtraImportFiles(system, srcFile);
    
            for extraDataFile = extraImportFiles
                extraDataFile = char(extraDataFile);
                extraDataPath = fullfile(srcDir, extraDataFile);

                if ~WTUtils.fileExist(extraDataPath) 
                    wtLog.err('File ''%s'' needs extra file ''%s'', which is missing', srcPath, extraDataFile);
                    notImportedFiles = [notImportedFiles srcPath];
                    break
                end
                filesToCopy = [filesToCopy extraDataPath];
            end
            
            if length(filesToCopy) < length(extraImportFiles)+1 
                continue
            end

            copyFailed = false;

            for file = filesToCopy
                [copied, msg, ~] = copyfile(file{1}, importDir, 'f');

                if ~copied 
                    wtLog.err('File ''%s'' could not be copied to ''%s'': %s', file{1}, importDir, msg);
                    copyFailed = true;
                    break
                end
            end

            if copyFailed
                wtLog.err('File ''%s'' (and/or an auxiliary file, if any) could not be imported successfully', srcPath);
                notImportedFiles = [notImportedFiles srcPath];
            else
                wtLog.info('File ''%s'' imported successfully', srcPath);
            end
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