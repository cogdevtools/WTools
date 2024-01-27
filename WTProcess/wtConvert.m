% wtConvert.m
% Created by Eugenio Parise
% CDC CEU 2012
% Function to select the eeg system to import. It only works from GUI.
%
% Usage: wtConvert();

function success = wtConvert()
    success = false;
    wtProject = WTProject();

    if ~wtProject.checkIsOpen()
        return
    end
    
    convertToEEGLabData = copy(wtProject.Config.ConvertToEEGLab);

    if ~WTConvertGUI.sourceDataFormatSelect(convertToEEGLabData)
        return
    end

    if ~convertToEEGLabData.persist()
        wtProject.notifyErr([], 'Failed to save convert to EEGLAB params');
        return
    end

    wtProject.Config.ConvertToEEGLab = convertToEEGLabData;

    if convertToEEGLabData.EEPFlag 
        eep2eegl;
    elseif convertToEEGLabData.EGIFlag 
        wtEGIToEEGLab;
    elseif convertToEEGLabData.BRVFlag 
        brv2eegl;
    elseif convertToEEGLabData.EEGLabFlag 
        wtEGIToEEGLab;
    end
    success = true;
end