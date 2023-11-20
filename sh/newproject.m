%newproject.m
%Created by Eugenio Parise
%CDC CEU 2011
%Create a new project/folder for a WTools project. Subfolders pop_cfg and
%Export are created as well; exported.m and filenm.m stored in pop_cfg folder.
%A variable called PROJECTPATH is created in the 'base' Wokspace.
%
%Usage:
%
%newproject();
function success = newproject
    success = false;
    prjName = '';
    while isempty(prjName) 
        prms = { { 'style' 'text' 'string' 'New project name:' } ...
                 { 'style' 'edit' 'string' '' } };
        answer = WTUtils.inputgui( 'geometry', { [1 2] }, 'uilist', prms, 'title', '[WTools] Set project name');

        if isempty(answer)
            return %quit on cancel button
        end

        prjName = strip(answer{1});

        if length(split(prjName)) > 1 || length(split(prjName,'\')) > 1 || length(split(prjName,'/')) > 1
            WTUtils.msggui('Error', ['Invalid project name!\n'...
                'Remove blanks and / \\ chars from the name.']);
            prjName = '';
        end
    end

    prjParentDir = WTUtils.uigetdir('.', 'Select the project parent directory...');
    if isempty(prjParentDir)
        return
    end

    crntPrjPath = WTProject.getRootDir();
    prjPath = fullfile(prjParentDir, prjName);

    if ~WTProject.setRootDir(prjPath, false)
        WTLog.err('Project path ''%s'' already exists', prjPath)
        WTUtils.msggui('Error', 'Project path already exists!');
        WTProject.setRootDir(crntPrjPath)
        return
    elseif ~WTProject.newProject()
        WTLog.err('Failed to create project ''%s'' in dir', prjName, prjParentDir);
        WTUtils.msggui('Error', 'Failed to create project! Check the log...');
        WTProject.resetRootDir()
        WTProject.setRootDir(crntPrjPath)
        return
    end

    WTLog.info('New project ''%s'' created in''%s''', prjName, prjParentDir);
    WTUtils.msggui('Project created', ['New WTools project created!\n'...
        'Please, copy all the files to transform (EGI, EEP, ... XYZ system)\n'... 
        'in the Export subfolder, then import them into eeglab.']);
    success = true;
end