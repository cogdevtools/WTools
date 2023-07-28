function import2eegl()

%import2eegl.m
%Created by Eugenio Parise
%CDC CEU 2012
%Function to select the eeg system to import. It only works from GUI.
%
%Usage:
%
%import2eegl();
%

if ~exist('inputgui.m','file')
    
    fprintf(2,'\nPlease, start EEGLAB first!!!\n');
    fprintf('\n');
    return
    
end

if ispc
    sla='\';
else
    sla='/';
end

try
    PROJECTPATH=evalin('base','PROJECTPATH');
    cd (PROJECTPATH);
    addpath(strcat(PROJECTPATH,sla,'pop_cfg'));
catch
    fprintf(2,'\nPlease, create a new project or open an existing one.\n');
    fprintf('\n');
    return
end


%SET defaultanswer0
defaultanswer0={0,0,0,0};
systemsN=length(defaultanswer0);

%Load previously called parameters if existing
pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'import2eegl_cfg.m');
if exist(pop_cfgfile,'file')
    import2eegl_cfg;
    try
        defaultanswer=defaultanswer;
        defaultanswer{1,systemsN};
    catch
        fprintf('\n');
        fprintf(2, 'The import2eegl_cfg.m file in the pop_cfg folder was created by a previous version\n');
        fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
        fprintf('\n');
        defaultanswer=defaultanswer0;
    end
else
    defaultanswer=defaultanswer0;
end

cb_radiobutton1 = [ ...
    'get(gcbf, ''userdata'');' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton1''), ''Value'', 1);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton2''), ''Value'', 0);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton3''), ''Value'', 0);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton4''), ''Value'', 0);' ];

cb_radiobutton2 = [ ...
    'get(gcbf, ''userdata'');' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton1''), ''Value'', 0);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton2''), ''Value'', 1);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton3''), ''Value'', 0);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton4''), ''Value'', 0);' ];

cb_radiobutton3 = [ ...
    'get(gcbf, ''userdata'');' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton1''), ''Value'', 0);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton2''), ''Value'', 0);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton3''), ''Value'', 1);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton4''), ''Value'', 0);' ];

cb_radiobutton4 = [ ...
    'get(gcbf, ''userdata'');' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton1''), ''Value'', 0);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton2''), ''Value'', 0);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton3''), ''Value'', 0);' ...
    'set(findobj(gcbf, ''tag'', ''radiobutton4''), ''Value'', 1);' ];

parameters = { ...
    { 'style' 'text'            'string'    'Import segmented files from the following system:' } ...
    { 'style' 'text'            'string'    '' } ...
    { 'style' 'radiobutton'     'tag'       'radiobutton1' 'string' 'EEP'       'value'  defaultanswer{1,1} 'callback' cb_radiobutton1 } ...
    { 'style' 'radiobutton'     'tag'       'radiobutton2' 'string' 'EGI'       'value'  defaultanswer{1,2} 'callback' cb_radiobutton2 } ...
    { 'style' 'radiobutton'     'tag'       'radiobutton3' 'string' 'BRV'       'value'  defaultanswer{1,3} 'callback' cb_radiobutton3 } ...
    { 'style' 'radiobutton'     'tag'       'radiobutton4' 'string' 'EEGLAB'    'value'  defaultanswer{1,4} 'callback' cb_radiobutton4 } };

geometry = { [1] [1] [1] [1] [1] [1] };

[answer userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Import segmented EEG');

if ~strcmp(strhalt,'retuninginputui')
    return;
end

eepflag=answer{1,1};
egiflag=answer{1,2};
brvflag=answer{1,3};
eeglabflag=answer{1,4};

if ~eepflag && ~egiflag && ~brvflag && ~eeglabflag
    fprintf(2, '\nPlease select one EEG system!!!\n');
    fprintf('\n');
    return;
end

%Save the user input parameters in the pop_cfg folder
fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
fprintf(fid, 'defaultanswer={%i %i %i %i};',...
    eepflag, egiflag, brvflag, eeglabflag);
fclose(fid);

rehash;

%IMPORT EEP
if eepflag
    eep2eegl;
end

%IMPORT EGI
if egiflag
    egi2eegl;
end

%IMPORT BRV
if brvflag
    brv2eegl;
end

%IMPORT EEGLAB
if eeglabflag
    eegl2eegl;
end