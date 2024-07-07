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

classdef WTLayout

    properties (Constant, Access=private)
        ResourcesSubDir = 'WTResources'
        PicturesSubDir = 'WTPictures'
        CoreSubDir = 'WTCore'
        DevicesSubDir = 'WTDevices'
    end

    methods (Static)
        function d = getToolsDir() 
            persistent toolsDir

            if isempty(toolsDir)
                thisFileName = mfilename('fullpath');
                thisFileDir = fileparts(thisFileName);
                [~, parentDirAttr] = fileattrib(fullfile(thisFileDir, '..'));
                toolsDir = parentDirAttr.Name;
            end
            d = toolsDir;
        end

        function d = getResourcesDir() 
            persistent resourcesDir

            if isempty(resourcesDir)
                resourcesDir = fullfile(WTLayout.getToolsDir(), WTLayout.ResourcesSubDir);
            end
            d = resourcesDir;
        end

        function d = getPicturesDir() 
            persistent picturesDir

            if isempty(picturesDir)
                picturesDir = fullfile(WTLayout.getResourcesDir(), WTLayout.PicturesSubDir);
            end
            d = picturesDir;
        end

        function d = getDevicesDir() 
            persistent devicesDir

            if isempty(devicesDir)
                devicesDir = fullfile(WTLayout.getResourcesDir(), WTLayout.DevicesSubDir);
            end
            d = devicesDir;
        end

        function d = getAppConfigDir() 
            d = WTLayout.getResourcesDir();
        end
    end
end