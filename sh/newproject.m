function PROJECTPATH=newproject

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

if ~exist('inputgui.m','file')
    
    fprintf(2,'\nPlease, start EEGLAB first!!!\n');
    fprintf('\n');
    return
    
end

defaultanswer={''};

parameters    = { { 'style' 'text'       'string' 'New project name:' } ...
    { 'style' 'edit'       'string' defaultanswer{1,1} } };

geometry = { [1 2] };

answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set parameters');

if isempty(answer)
    clear ans answer defaultanswer geometry parameters;
    return %quit on cancel button
end

prname=(answer{1,1});

if isempty(prname)
    
    parameters    = { { 'style' 'text' 'string' 'Please, assign a valid name to the new project!!!' } };
    
    geometry = { [1] };
    
    inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Error');
    
    clear ans answer defaultanswer geometry parameters prname;
    
    return
    
elseif ~isempty(findstr(prname,'\')) || ~isempty(findstr(prname,'/'))
    
    parameters    = { { 'style' 'text' 'string' 'The characters / and \ are forbidden!!!' } };
    
    geometry = { [1] };
    
    inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Error');
    
    clear ans answer defaultanswer geometry parameters prname;
    
    return
    
end

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

prdir=strcat(PROJECTPATH,sla,prname);

if ~exist(prdir,'dir')
    assignin('base','PROJECTPATH',PROJECTPATH);
    mkdir (PROJECTPATH,prname);
    prdir=strcat(PROJECTPATH,sla,prname);
    mkdir (prdir,'pop_cfg');
    mkdir (prdir,'Export');
    %expdir = strcat(prdir,sla,'Export');
    
    %Save the export path and filename config files in the pop_cfg folder
    pop_cfgfile = strcat(prdir,sla,'pop_cfg/exported.m');
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'exportvar = { ''%sExport'' };',sla);
    fclose(fid);
    
    pop_cfgfile = strcat(prdir,sla,'pop_cfg/filenm.m');
    filename = strcat(prname,'_');
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'filename = { ''%s'' };',filename);
    fclose(fid);

    rehash;
    
else
    fprintf(2,'\nThe project %s already exists in this location!!!\n',prname);
    fprintf('\n');
    return
end

PROJECTPATH=prdir;
clear prdir;
cd (PROJECTPATH);

parameters    = { { 'style' 'text' 'string' 'New WT project created!' } ...
    { 'style' 'text' 'string' 'Please, copy all the files to transform (EGI, EEP, ... XYZ system)' } ...
    { 'style' 'text' 'string' 'in the Export subfolder, then import them into EEGLab.' } };

geometry = { [1] [1] [1] };

inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Project created');

clear ans answer defaultanswer geometry parameters sla fid pop_cfgfile prname filename;

assignin('base','PROJECTPATH',PROJECTPATH);

end