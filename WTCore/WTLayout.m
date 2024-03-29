classdef WTLayout
    properties (Constant, Access=private)
        ResourcesSubDir = 'WTResources'
        PicturesSubDir = 'WTPictures'
        DevicesSubDir = 'WTDevices'
    end

    methods (Static)
        function d = getToolsDir() 
            persistent toolsDir

            if isempty(toolsDir)
                fn = mfilename('fullpath');
                d = WTUtils.getPathPrefix(fn);
                toolsDir = WTUtils.getAbsPath(fullfile(d, '..'));
            end
            d = toolsDir;
        end

        function d = getToolsPicturesDir() 
            persistent picturesDir

            if isempty(picturesDir)
                picturesDir = fullfile(WTLayout.getResourcesDir(), WTLayout.PicturesSubDir);
            end
            d = picturesDir;
        end

        function d = getToolsDevicesDir() 
            persistent devicesDir

            if isempty(devicesDir)
                devicesDir = fullfile(WTLayout.getResourcesDir(), WTLayout.DevicesSubDir);
            end
            d = devicesDir;
        end

        function d = getResourcesDir() 
            persistent resourcesDir

            if isempty(resourcesDir)
                resourcesDir = fullfile(WTLayout.getToolsDir(), WTLayout.ResourcesSubDir);
            end
            d = resourcesDir;
        end
    end
end