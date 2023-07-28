function PROJECTPATH=openproject

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
PROJECTPATH=uigetdir('.', 'Select a Folder/Project/Study');
if ispc
    sla='\';
else
    sla='/';
end
if ~PROJECTPATH
    %'Cancel' has been pressed on the ui
    clear;
    return
end
cfg=strcat(PROJECTPATH,'/pop_cfg');
dirstart=max(findstr(PROJECTPATH,sla));
dirname=PROJECTPATH(dirstart+1:end);
if ismac
    minfiles=3;
elseif ispc
    minfiles=2;
end
if ~exist(cfg,'dir')
    fprintf(2,'\nThe folder %s does not contain a pop_cfg folder!!!\n', dirname);
    fprintf(2,'Please, open a valid project folder.\n');
    fprintf('\n');
    clear;
    return
elseif length(dir(cfg))<=minfiles
    fprintf(2,'\nThe pop_cfg folder in the  project folder %s is empty!!!\n', dirname);
    fprintf(2,'Please, put all necessary configuration files in the cfg folder.\n');
    fprintf('\n');
    clear;
    return
else
    assignin('base','PROJECTPATH',PROJECTPATH);
    clear dirstart;
    fprintf('\nProject in folder %s open!!!\n', dirname);
    fprintf('There are %i files in the pop_cfg folder.\n', length(dir(cfg))-minfiles);
    fprintf('Check that these configuration files are up to date,\n');
    fprintf('then you can use signal processing and plotting functions.\n');
    fprintf('\n');
    clear cfg dirname minfiles sla;
    cd (PROJECTPATH);
end