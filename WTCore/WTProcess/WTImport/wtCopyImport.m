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

function copiedCount = wtCopyImport() 
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

    [~, subjects] = ioProc.enumImportFiles(system); 
    subjecsMap = WTCodingUtils.ifThenElse(isempty(subjects), @()containers.Map(), ...
        @()containers.Map(subjects, ones(1, length(subjects))));

    while true
        fileExt = ['*.' WTIOProcessor.getSystemImportFileExtension(system)];
        fileFilter = {fileExt, sprintf('%s (%s)', system, fileExt)};

        [srcFiles, srcDir, ~] = WTDialogUtils.uiGetFiles(fileFilter, -1, -1, ...
            sprintf('Select all the files to copy from %s system',  system), 'MultiSelect', 'on');

        if isempty(srcFiles) 
            if WTEEGLabUtils.eeglabYesNoDlg('Confirm', 'Quit copy?')
                return
            end
            continue
        end

        for srcFileCell = srcFiles 
            srcFile = char(srcFileCell);
            srcPath = fullfile(srcDir, srcFile);

            overwrite = false;
            [dstFile, ~] = ioProc.getImportFile(srcFile);
            if WTIOUtils.fileExist(dstFile) && ~WTEEGLabUtils.eeglabYesNoDlg('Overwrite', ...
                    'It looks like file ''%s'' has been already imported. Overwrite?', srcFile)
                wtLog.warn('File ''%s'' skipped by user as already imported', srcPath);
                continue
            else
                wtLog.warn('User chose to overwrite file ''%s'', with the one from directory ''%s''', srcFile, srcPath);
                overwrite = true;
            end

            subj = ioProc.getSubjectsFromImportFiles(system, srcFile);

            if isempty(subj)
                wtLog.err('Not a valid %s file name: ''%s''', system, srcFile);
                notCopiedFiles = [notCopiedFiles srcPath];
                continue
            end 

            subj = char(subj{1});

            if ~overwrite && subjecsMap.isKey(subj)
                wtLog.err('A file related to subject ''%s'' has already been copied. Rejected %s file: ''%s''', subj, system, srcFile);
                notCopiedFiles = [notCopiedFiles srcPath];
                continue
            end

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
                wtLog.warn('File ''%s'' skipped as missing auxiliary file(s)', srcPath); 
                notCopiedFiles = [notCopiedFiles srcPath];
                continue
            end

            copyFailed = false;
            copiedFiles = {};

            for file = filesToCopy
                [copied, msg, ~] = copyfile(file{1}, importDir, 'f');

                if ~copied 
                    wtLog.err('File ''%s'' could not be copied to ''%s'': %s', file{1}, importDir, msg);
                    copyFailed = true;
                    break
                end

                copiedFiles(end+1) = file;
            end

            if copyFailed
                wtLog.err('File ''%s'' (and/or an auxiliary file, if any) could not be copied successfully', srcPath);
                notCopiedFiles = [notCopiedFiles srcPath];

                for file = copiedFiles
                    wtLog.info('Removing file ''%s'' because failed to copy all the auxiliaries', srcPath);
                    delete(file{1});
                end
            else
                wtLog.info('File ''%s'' copied successfully', srcPath);
                copiedCount = copiedCount + 1;
                subjecsMap(subj) = 1;
            end
        end

        if ~WTEEGLabUtils.eeglabYesNoDlg('Other copies', 'Continue to copy source data?')
            break;
        end            
    end

    if ~isempty(notCopiedFiles) 
        WTEEGLabUtils.eeglabMsgDlg('Errors', 'The following files could not be copied. Check the log...\n%s', ... 
            char(join(notCopiedFiles, '\n')));
    end

    if copiedCount > 0 && ~basicPrms.persist()
        wtProject.notifyErr([], 'Failed to save basic configuration params');
    end
end