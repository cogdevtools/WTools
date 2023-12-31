function wtChangeGUIColors(guiObj, bgColor, fgColor)
    if ~isscalar(guiObj)
        for i = 1:length(guiObj)
            wtChangeGUIColors(guiObj(i), bgColor, fgColor); 
        end
    elseif ~isempty(guiObj) && isvalid(guiObj) 
        trySetObjectProperty(guiObj, 'Color', bgColor); 
        trySetObjectProperty(guiObj, 'BackgroundColor', bgColor); 
        trySetObjectProperty(guiObj, 'ForegroundColor', fgColor); 
        wtChangeGUIColors(allchild(guiObj), bgColor, fgColor)
    end
end

function trySetObjectProperty(guiObj, property, color)
    try 
        set(guiObj, property, color); 
    catch 
    end
end