% wtConvert.m
% Created by Eugenio Parise
% CDC CEU 2012
% Function to select the eeg system to import. It only works from GUI.
%
% Usage: wtConvert();

function success = wtConvert()
    success = false;
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;

    if ~wtProject.checkIsOpen()
        return
    end

    if ioProc.countImportFiles() == 0 
        wtProject.notifyWrn([], 'There are no imported files yet in this project')
        return
    end

    basicPrms = copy(wtProject.Config.Basic); 
    importTypePrms = copy(wtProject.Config.ImportType);

    if ~WTConvertGUI.selectImportType(importTypePrms, basicPrms, true)
        return
    end

    if ~importTypePrms.persist()
        wtProject.notifyErr([], 'Failed to save convert to EEGLAB params');
        return
    end

    wtProject.Config.ImportType = importTypePrms;

    if importTypePrms.EEPFlag 
        wtEEPToEEGLab();
    elseif importTypePrms.EGIFlag 
        wtEGIToEEGLab();
    elseif importTypePrms.BRVFlag 
        wtBRVToEEGLab();
    elseif importTypePrms.EEGLabFlag 
        wtEEGLabToEEGLab();
    end
    success = true;
end