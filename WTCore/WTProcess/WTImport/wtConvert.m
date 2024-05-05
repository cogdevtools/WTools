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
    
    convertToEEGLabData = copy(wtProject.Config.ImportType);

    if ~WTConvertGUI.selectImportType(convertToEEGLabData)
        return
    end

    if ~convertToEEGLabData.persist()
        wtProject.notifyErr([], 'Failed to save convert to EEGLAB params');
        return
    end

    wtProject.Config.ImportType = convertToEEGLabData;

    if convertToEEGLabData.EEPFlag 
        wtEEPToEEGLab();
    elseif convertToEEGLabData.EGIFlag 
        wtEGIToEEGLab();
    elseif convertToEEGLabData.BRVFlag 
        wtBRVToEEGLab();
    elseif convertToEEGLabData.EEGLabFlag 
        wtEEGLabToEEGLab();
    end
    success = true;
end