classdef WTGraphicUtils

    methods(Static)
        function valid = isValidColorMap(colorMap)
            % colormap need a figure or it will open one
            hFigure = figure('Visible', 'off');
            currentColorMap = colormap();
            try
                colormap(colorMap);
                valid = true;   
            catch
                valid = false;      
            end
            colormap(currentColorMap);
            delete(hFigure)
        end

        function colorMaps = getColorMaps() 
            persistent colorMapsInternal

            if ~isempty(colorMapsInternal)
                colorMaps = colorMapsInternal;
                return
            end

            colorMapDir = fullfile(matlabroot, '/toolbox/matlab/graphics/color');
            dirContent = dir(fullfile(colorMapDir, '*.m'));
            colorMapsInternal = cell(length(dirContent), 1);
            nValid = 0;

            for i = 1:length(dirContent)
                if dirContent(i).isdir
                    continue
                end
                colorMap = dirContent(i).name;
                % strip the '.m'
                colorMap = colorMap(1:length(colorMap)-2); 
                if WTGraphicUtils.isValidColorMap(colorMap)
                    nValid = nValid + 1;
                    colorMapsInternal{nValid} = colorMap;
                end
            end

            colorMapsInternal = colorMapsInternal(1:nValid);
            colorMaps = colorMapsInternal;
        end
    end
end