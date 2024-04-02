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
    if ~ischar(prjPath)
        return
    end

    wtProject = WTProject();
    
    if ~wtProject.open(prjPath) 
        return
    end

    wtAppConfig = WTAppConfig();

    if wtAppConfig.ProjectLog
        ioProc = wtProject.Config.IOProc;
        wtLog = WTLog();
        [~, opened] = wtLog.openStream(ioProc.getLogFile(wtProject.Config.getName()));
        wtLog.MuteStdStreams = WTUtils.ifThenElse(opened, wtAppConfig.MuteStdLog, false);
    end
    
    if WTUtils.eeglabYesNoDlg('Update import', 'Do you want to import new data files?')
        wtImportData();
    end

    success = true;
end