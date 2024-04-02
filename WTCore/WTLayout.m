classdef WTLayout
    properties (Constant, Access=private)
        ResourcesSubDir = 'WTRsrcs'
        PicturesSubDir = 'WTPictures'
        CoreSubDir = 'WTCore'
        DevicesSubDir = 'WTDevices'
        AppConfSubDir = 'WTAppConf'
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
                devicesDir = fullfile(WTLayout.getToolsDir(), WTLayout.CoreSubDir, WTLayout.DevicesSubDir);
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

        function d = getAppConfigDir() 
            persistent resourcesDir

            if isempty(resourcesDir)
                resourcesDir = fullfile(WTLayout.getResourcesDir(), WTLayout.AppConfSubDir);
            end
            d = resourcesDir;
        end
    end
end