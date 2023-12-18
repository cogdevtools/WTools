% wtOpenProject.m
% Created by Eugenio Parise
% CDC CEU 2011
% Define the project path for a WTools project. In this way the folder
% WTools and its subfolder sh (containing all the functions) can be a Matlab
% toolbox folder (e.g. in Documents/MATLAB/Toolboxes) and does not need to
% be copied in each individual project/study. The cfg folder still need to
% be copied in each individual project/study flder.
% Call wtOpenProject as very first step, before to work on each project, but
% after the files in the cfg folder are fully edited. Calling wtOpenProject()
% will ask the user to select its project folder and will create a variable
% called PROJECTPATH in the 'base' Wokspace.
%
% Usage: wtOpenProject();

function success = wtOpenProject
    success = false;

    prjPath = WTUtils.uiGetDir('.', 'Select the project directory...');
    if isempty(prjPath)
        return
    end

    wtProject = WTProject();
    
    if ~wtProject.open(prjPath) 
        WTUtils.eeglabMsgGui('Error', 'Failed to open project! Check the log...');
        return
    end

    WTLog().warn('Check that the files in ''%s'' are up to date before to begin the processing!', wtProject.Config.getConfigDir());
    success = true;
end