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