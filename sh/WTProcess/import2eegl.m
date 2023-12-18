% import2eegl.m
% Created by Eugenio Parise
% CDC CEU 2012
% Function to select the eeg system to import. It only works from GUI.
%
% Usage: import2eegl();

function import2eegl()
    wt = WTProject();

    if ~wtProject.checkIsOpen()
        return
    end

    wtLog = WTLog();
    importToEEGLabData = wtProject.Config.ImportToEEGLab;

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
        { 'style' 'text'        'string' 'Import segmented files from the following system:' } ...
        { 'style' 'text'        'string' '' } ...
        { 'style' 'radiobutton' 'tag'    'radiobutton1' 'string' 'EEP'    'value'  importToEEGLabData.EEPFlag    'callback' cb_radiobutton1 } ...
        { 'style' 'radiobutton' 'tag'    'radiobutton2' 'string' 'EGI'    'value'  importToEEGLabData.EGIFlag    'callback' cb_radiobutton2 } ...
        { 'style' 'radiobutton' 'tag'    'radiobutton3' 'string' 'BRV'    'value'  importToEEGLabData.BRVFlag    'callback' cb_radiobutton3 } ...
        { 'style' 'radiobutton' 'tag'    'radiobutton4' 'string' 'EEGLAB' 'value'  importToEEGLabData.EEGLabFlag 'callback' cb_radiobutton4 } };

    geometry = { 1 1 1 1 1 1 };

    while true
        [answer userdat strhalt] = WTUtils.eeglabInputGui('geometry', geometry, 'uilist', parameters,'title', 'Import segmented EEG');

        if ~strcmp(strhalt,'retuninginputui')
            wtLog.dbg('User quitted import configuration dialog')
            return;
        end

        importToEEGLabData.EEPFlag=answer{1,1};
        importToEEGLabData.EGIFlag=answer{1,2};
        importToEEGLabData.BRVFlag=answer{1,3};
        importToEEGLabData.EEGLabFlag=answer{1,4};

        % This is a double check, if for any reason the configuration file was changed manually
        if sum(cellfun(@(e) e, answer)) ~= 0
            break
        end

        WTUtils.eeglabMsgGui('Warning', 'You must select one EEG system among EEP, EGI, BRV, EEGLAB')
    end

    if ~importToEEGLabData.persist()
        wtLog.err('Failed to save import to EEGLAB params')
    end

    rehash;

    if importToEEGLabData.EEPFlag %IMPORT EEP
        eep2eegl;
    elseif importToEEGLabData.EGIFlag %IMPORT EGI
        egi2eegl;
    elseif importToEEGLabData.BRVFlag %IMPORT BRV
        brv2eegl;
    elseif importToEEGLabData.EEGLabFlag %IMPORT EEGLAB
        eegl2eegl;
    end
end