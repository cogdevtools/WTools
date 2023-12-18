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
    prjName = '';
    while isempty(prjName) 
        prms = { { 'style' 'text' 'string' 'New project name:' } ...
                 { 'style' 'edit' 'string' '' } };
        answer = WTUtils.eeglabInputGui( 'geometry', { [1 2] }, 'uilist', prms, 'title', '[WTools] Set project name');

        if isempty(answer)
            return % quit on cancel button
        end

        prjName = strip(answer{1});
        if ~WTProject.checkIsValidName(prjName, true)
            prjName = '';
        end
    end

    prjParentDir = WTUtils.uiGetDir('.', 'Select the project parent directory...');
    if isempty(prjParentDir)
        return
    end

    prjPath = fullfile(prjParentDir, prjName);

    if ~WTProject().new(prjPath)
        WTUtils.eeglabMsgGui('Error', 'Failed to create project! Check the log...');
        return
    end

    WTUtils.eeglabMsgGui('Project created', ['New WTools project created!\n'...
        'Please, copy all the files to transform (EGI, EEP, ... XYZ system)\n'... 
        'in the Export subfolder, then import them into eeglab.']);
    success = true;
end