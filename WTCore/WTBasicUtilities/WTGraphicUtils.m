% Copyright (C) 2024 Eugenio Parise, Luca Filippin
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.

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