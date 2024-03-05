classdef WTLayout
    properties (Constant, Access=private)
        ResourcesSubDir = 'WTResources'
        PicturesSubDir = 'WTPictures'
        DevicesSubDir = 'WTDevices'
    end

    methods (Static)
        function d = getToolsDir() 
            fn = mfilename('fullpath');
            d = WTUtils.getPathPrefix(fn);
            d = WTUtils.getAbsPath(fullfile(d, '..'));
        end

        function d = getToolsPicturesDir() 
            d = fullfile(WTLayout.getToolsDir(), WTLayout.ResourcesSubDir, WTLayout.PicturesSubDir);
        end

        function d = getToolsDevicesDir() 
            d = fullfile(WTLayout.getToolsDir(), WTLayout.ResourcesSubDir, WTLayout.DevicesSubDir);
        end

        function d = getResourcesDir() 
            d = fullfile(WTLayout.getToolsDir(), WTLayout.ResourcesSubDir);
        end
    end
end