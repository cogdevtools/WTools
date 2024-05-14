function success = wtConvert()
    success = false;
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;

    if ~wtProject.checkIsOpen()
        return
    end

    if ioProc.countImportFiles() == 0 
        wtProject.notifyWrn([], 'There are no imported files yet in this project');
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
        success = wtEEPToEEGLab();
    elseif importTypePrms.EGIFlag 
        success = wtEGIToEEGLab();
    elseif importTypePrms.BRVFlag 
        success = wtBRVToEEGLab();
    elseif importTypePrms.EEGLabFlag 
        success = wtEEGLabToEEGLab();
    end
end