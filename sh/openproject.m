%openproject.m
%Created by Eugenio Parise
%CDC CEU 2011
%Define the project path for a WTools project. In this way the folder
%WTools and its subfolder sh (containing all the functions) can be a Matlab
%toolbox folder (e.g. in Documents/MATLAB/Toolboxes) and does not need to
%be copied in each individual project/study. The cfg folder still need to
%be copied in each individual project/study flder.
%Call openproject as very first step, before to work on each project, but
%after the files in the cfg folder are fully edited. Calling openproject()
%will ask the user to select its project folder and will create a variable
%called PROJECTPATH in the 'base' Wokspace.
%
%Usage:
%
%openproject();

%function openproject()

%global PROJECTPATH;
function success=openproject
    success = false;

    prjPath = WTUtils.uigetdir('.', 'Select the project directory...');
    if isempty(prjPath)
        return
    end
    
    crntPrjPath = WTProject.getRootDir();
    WTProject.setRootDir(prjPath);

    if ~WTProject.openProject() 
        WTLog.err('Failed to open project ''%s''', prjPath);
        WTUtils.msggui('Error', 'Failed to open project! Check the log...');
        WTProject.setRootDir(crntPrjPath);
        return
    end

    WTLog.info('Project ''%s'' opened successfully', WTProject.getProjectName());
    WTLog.warn('Check that the files in ''%s'' are up to date before to begin the processing!', WTProject.getCfgDir());
    success = true;
end