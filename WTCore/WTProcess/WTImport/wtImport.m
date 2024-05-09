
function wtImport(forceCopy)
    forceCopy = nargin > 1 && forceCopy;
    wtProject = WTProject();

    if ~wtProject.checkIsOpen()
        return
    end
    
    if forceCopy || WTEEGLabUtils.eeglabYesNoDlg('Import', 'Do you want to import new data files?')
        nCopied = wtCopyData();
        if nCopied == 0 && ...
            ~WTEEGLabUtils.eeglabYesNoDlg('Import', 'No new files were imported. Continue anyway with data conversion?')
            return
        end
    end

    wtConvert();
end