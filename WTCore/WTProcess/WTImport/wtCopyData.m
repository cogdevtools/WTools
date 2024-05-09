function copiedCount = wtCopyData() 
    copiedCount = 0;
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;
    basicPrms = wtProject.Config.Basic;
    wtLog = WTLog();
    importDir = ioProc.ImportDir;
    notCopiedFiles = {};
    systemTypes = WTIOProcessor.getSystemTypes();

    if ~isempty(basicPrms.SourceSystem) && ~any(cellfun(@(x)strcmp(x, basicPrms.SourceSystem), systemTypes))
        wtLog.err('Unknown source system type: ''%s''', basicPrms.SourceSystem);
        if ~WTEEGLabUtils.eeglabYesNoDlg('Error', 'Unknown source system type ''%s''. Reset?', basicPrms.SourceSystem)
            return
        end
        wtLog.wrn('User reset source system type because unknown: ''%s''',  basicPrms.SourceSystem);
        basicPrms.SourceSystem = '';
    end

    system = basicPrms.SourceSystem;

    if isempty(system)
        % This message is perhaps too annoying...
        % WTEEGLabUtils.eeglabMsgDlg('Info', 'NOTE: only files with name format ''%s'' can be imported...', ioProc.ImportFileRe);
        systemTypes = WTIOProcessor.getSystemTypes();
        system = WTDialogUtils.stringsSelectDlg('Source system', systemTypes, true, false, 'ListSize', [200,100]);
        if isempty(system) 
            return
        end
        system = char(system);
        basicPrms.SourceSystem = system;
        wtLog.info('User selected system ''%s''', system);
    end

    while true
        fileExt = ['*.' WTIOProcessor.getSystemImportFileExtension(system)];
        fileFilter = {fileExt, sprintf('%s (%s)', system, fileExt)};

        [srcFiles, srcDir, ~] = WTDialogUtils.uiGetFiles(fileFilter, -1, -1, ...
            sprintf('Select all the files to import from %s system',  system), 'MultiSelect', 'on');

        if isempty(srcFiles) 
            if WTEEGLabUtils.eeglabYesNoDlg('Confirm', 'Quit import?')
                return
            end
            continue
        end

        for srcFileCell = srcFiles 
            srcFile = char(srcFileCell);
            srcPath = fullfile(srcDir, srcFile);

            if isempty(ioProc.getSubjectsFromImportFiles(system, srcFile))
                wtLog.err('Not a valid %s file name for import: %s', system, srcFile);
                notCopiedFiles = [notCopiedFiles srcPath];
                continue
            end 

            srcPath = fullfile(srcDir, srcFile);
            filesToCopy = {srcPath};
            extraImportFiles = WTIOProcessor.getSystemExtraImportFiles(system, srcFile);
    
            for extraDataFile = extraImportFiles
                extraDataFile = char(extraDataFile);
                extraDataPath = fullfile(srcDir, extraDataFile);

                if ~WTIOUtils.fileExist(extraDataPath) 
                    wtLog.err('File ''%s'' needs extra file ''%s'', which is missing', srcPath, extraDataFile);
                    notCopiedFiles = [notCopiedFiles srcPath];
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

                copiedCount = copiedCount + 1;
            end

            if copyFailed
                wtLog.err('File ''%s'' (and/or an auxiliary file, if any) could not be imported successfully', srcPath);
                notCopiedFiles = [notCopiedFiles srcPath];
            else
                wtLog.info('File ''%s'' imported successfully', srcPath);
            end
        end

        if ~WTEEGLabUtils.eeglabYesNoDlg('Other imports', 'Continue to import?')
            break;
        end            
    end

    if ~isempty(notCopiedFiles) 
        WTEEGLabUtils.eeglabMsgDlg('Errors', 'The following files could not be imported. Check the log...\n%s', ... 
            char(join(notCopiedFiles, '\n')));
    end

    if copiedCount > 0 && ~basicPrms.persist()
        wtProject.notifyErr([], 'Failed to save basic configuration params');
    end
end