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
        end

        function d = getToolsPicturesDir() 
            d = fullfile(WTLayout.getToolsDir(), WTLayout.ResourcesSubDir, WTLayout.PicturesSubDir);
        end

        function d = getToolsDevicesDir() 
            d = fullfile(WTLayout.getToolsDir(), WTLayout.ResourcesSubDir, WTLayout.DevicesSubDir);
        end
    end
end