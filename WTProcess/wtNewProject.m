% wtNewProject.m
% Created by Eugenio Parise
% CDC CEU 2011
% Create a new project/folder for a WTools project. Subfolders pop_cfg and
% Export are created as well; exported.m and filenm.m stored in pop_cfg folder.
% A variable called PROJECTPATH is created in the 'base' Wokspace.
%
% Usage: wtNewProject()

function success = wtNewProject
    success = false;
    wtProject = WTProject();
    prjName = '';

    while true 
        prms = { { 'style' 'text' 'string' 'New project name:' } ...
                 { 'style' 'edit' 'string' prjName } };
        answer = WTUtils.eeglabInputMask( 'geometry', { [1 2] }, 'uilist', prms, 'title', '[WTools] Set project name');

        if isempty(answer)
            return % quit on cancel button
        end

        prjName = strip(answer{1});
        if WTProject.checkIsValidName(prjName, true)
            break;
        end
    end

    prjParentDir = WTUtils.uiGetDir('.', 'Select the project parent directory...');
    if ~ischar(prjParentDir)
        return
    end

    prjPath = fullfile(prjParentDir, prjName);
    if  WTUtils.dirExist(prjPath)
        [~, ~, strHalt] = WTUtils.eeglabMsgDlg('Warning', ['Project directory already exists!\n' ...
            'Directory: %s\n' ...
            'Do you want to overwrite it?\n' ...
            '[Cancel = No]      [Ok = Yes]'], prjPath);
        if ~strcmp(strHalt,'retuninginputui')
            return;
        end            
    end

    if ~wtProject.new(prjPath)
        WTUtils.eeglabMsgDlg('Error', 'Failed to create project! Check the log...');
        return
    end

    WTUtils.eeglabMsgDlg('Project created', ['New WTools project created successfully!\n'...
        'As next step you''ll be asked to select the files to import...']);

    importDataFiles()
    success = true;
end

function importDataFiles()
    ioProc = WTProject().Config.IOProc;
    wtLog = WTLog();
    importDir = ioProc.getImportDir();
    notImportedFiles = {};

    WTUtils.eeglabMsgDlg('Info', 'NOTE: only files with name format ''%s'' can be imported...', ioProc.ImportFileRe);

    while true
        [srcFiles, srcDir, ~] = WTUtils.uiGetFile('*.mat', ...
            'Select all the files to import (EGI, EEP, ...)', 'MultiSelect', 'on');

        for srcFile = srcFiles 
            srcFile = char(srcFile);
            srcPath = fullfile(srcDir, srcFile);

            if ~ioProc.isValidImportFile(srcFile)
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

        [~, ~, strHalt] = WTUtils.eeglabMsgDlg('Other imports?', ['Continue to import?\n'...
            '[Cancel = No]      [Ok = Yes]']);
        if ~strcmp(strHalt, 'retuninginputui')
            break;
        end            
    end

    if ~isempty(notImportedFiles) 
        WTUtils.eeglabMsgDlg('Errors', 'The following files could not be imported. Check the log...\n%s', ... 
            char(join(notImportedFiles, '\n')));
    end
end