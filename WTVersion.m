classdef WTVersion
    properties(Constant)
        Maj   = 2
        Min   = 0
        Patch = 0
        ReleaseDate = datetime(2023,12,31,0,0,0)
    end

    methods
        function val = getVersionShortStr(o) 
            val = sprintf('%d.%d', o.Maj,  o.Min);
        end

        function val = getVersionStr(o) 
            val = sprintf('%d.%d.%d',  o.Maj,  o.Min, o.Patch);
        end

        function val = getReleaseDateStr(o) 
            val = char(datetime(o.ReleaseDate, 'Format', 'MMMM y'));
        end
    end
end