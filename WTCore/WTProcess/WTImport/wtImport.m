
function success = wtImport(forceCopy)
    success = false;
    forceCopy = nargin > 0 && forceCopy;
    wtProject = WTProject();

    if ~wtProject.checkIsOpen()
        return
    end

    nCopied = 0;

    if forceCopy || WTEEGLabUtils.eeglabYesNoDlg('Import', 'Would you like to copy new source data files?')
        nCopied = wtCopyData();
        if nCopied == 0 && ...
            ~WTEEGLabUtils.eeglabYesNoDlg('Import', 'No new files were copied. Continue with the import?')
            return
        end
    end

    if wtProject.checkWaveletAnalysisDone(true)
        if nCopied == 0 && ~WTEEGLabUtils.eeglabYesNoDlg('Import', ...
            'An analysis has been already performed on the current imported data. Proceed anyway?')
            return
        end 
        if ~WTEEGLabUtils.eeglabYesNoDlg('Import', ...
            ['After data conversion, you MUST run again the entire analysis. Data will be re-processed, although\n' ...
             'the parameters set in the previous analysis will be retained and can be changed. Continue?'])
            return
        end
    end

    if wtConvert() 
        basicPrms = wtProject.Config.Basic;
        basicPrms.WaveletAnalysisDone = 0;
        basicPrms.ChopAndBaselineCorrectionDone = 0;
        basicPrms.ConditionsDifferenceDone = 0;
        basicPrms.GrandAverageDone = 0;

        if ~basicPrms.persist()
            wtProject.notifyErr([], 'Failed to save basic configuration params related to the processing status.');
            return
        end
        success = true;
    end
end