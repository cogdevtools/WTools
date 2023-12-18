function list = wtStrCellsSelectGUI(list, prompt)
    if ~WTValidations.isALinearCellArrayOfNonEmptyString(list)
        WTLog.expt('BadArg', 'Bad argument type or value: list');
    end
    if length(list) < 2
        return
    end
    [indxs, ok] = listdlg('PromptString',prompt,'SelectionMode','multiple','ListString',list);
    if ~ok
        list = {};
        return 
    end
    list = list(indxs);
end 