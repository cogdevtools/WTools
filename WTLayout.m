classdef WTLayout
    properties (Constant, Access=private)
        ResourcesSubDir = 'WTResources'
        PicturesSubDir = 'WTPictures'
        SplineSubDir = 'WTSplines'
    end

    methods (Static)
        function d = getToolsDir() 
            fn = mfilename('fullpath');
            d = WTUtils.getPathPrefix(fn);
        end

        function d = getToolsPicturesDir() 
            d = fullfile(WTLayout.getToolsDir(), WTLayout.ResourcesSubDir, WTLayout.PicturesSubDir);
        end

        function d = getToolsSplinesDir() 
            d = fullfile(WTLayout.getToolsDir(), WTLayout.ResourcesSubDir, WTLayout.SplineSubDir);
        end
    end
end