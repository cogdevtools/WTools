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

        % Recusively set the properties defined in varargin for handle and all
        % the children handles. 
        % Ex: recursivePropertySet(h, 'FontName', 'Helvetica', 'FontSize', 10)
        function recursivePropertySet(handle, varargin)
            function trySetProperty(handle, property, value)
                try 
                    set(handle, property, value); 
                catch 
                end
            end
            if ~isscalar(handle)
                for i = 1:length(handle)
                    WTGraphicUtils.recursivePropertySet(handle(i), varargin{:}); 
                end
            elseif ~isempty(handle) && isvalid(handle) 
                for i = 0:(nargin-1)/2-1
                    trySetProperty(handle, varargin{i*2+1}, varargin{i*2+2}); 
                end
                WTGraphicUtils.recursivePropertySet(allchild(handle), varargin{:})
            end
        end
    end
end