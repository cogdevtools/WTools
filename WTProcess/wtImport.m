% wtImport.m
% Created by Eugenio Parise
% CDC CEU 2012
% Function to select the eeg system to import. It only works from GUI.
%
% Usage: wtImport();

function wtImport()
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkIsOpen()
        return
    end
    
    importToEEGLabData = wtProject.Config.ImportToEEGLab;

    if ~wtImportFromSelectGUI(importToEEGLabData)
        return
    end

    if ~importToEEGLabData.persist()
        wtLog.err('Failed to save import to EEGLAB params');
    end

    if importToEEGLabData.EEPFlag 
        eep2eegl;
    elseif importToEEGLabData.EGIFlag 
        wtEGIToEEGLab;
    elseif importToEEGLabData.BRVFlag 
        brv2eegl;
    elseif importToEEGLabData.EEGLabFlag 
        eegl2eegl;
    end
end