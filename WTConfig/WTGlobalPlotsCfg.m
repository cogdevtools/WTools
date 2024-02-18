classdef WTGlobalPlotsCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        TimeMin(1,1) int32
        TimeMax(1,1) int32
        FreqMin(1,1) uint32
        FreqMax(1,1) uint32
        Scale(1,2) single  
        Contours(1,1) uint8 {WTValidations.mustBeZeroOrOne}
        AllChannels(1,1) uint8 {WTValidations.mustBeZeroOrOne}
    end

    methods
        function o = WTGlobalPlotsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'xavr_cfg.m');
            o.default();
        end

        function default(o) 
            o.TimeMin = 0;
            o.TimeMax = 0;
            o.FreqMin = 0;
            o.FreqMax = 0;
            o.Scale = [-10.0 10.0];
            o.Contours = 0;
            o.AllChannels = 1;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                o.TimeMin = WTUtils.str2double(cells{1});
                o.TimeMax = WTUtils.str2double(cells{2});
                o.FreqMin = WTUtils.str2double(cells{3});
                o.FreqMax = WTUtils.str2double(cells{4});
                o.Scale = WTUtils.str2double(cells{5});
                o.Contours = WTUtils.str2double(cells{6});
                o.AllChannels = WTUtils.str2double(cells{7});
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.GenericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTFormatter.FmtIntStr, o.TimeMin, ...
                WTFormatter.FmtIntStr, o.TimeMax, ...
                WTFormatter.FmtIntStr, o.FreqMin, ...
                WTFormatter.FmtIntStr, o.FreqMax, ...
                WTFormatter.FmtArrayStr, num2str(o.Scale), ...
                WTFormatter.FmtInt, o.Contours, ...
                WTFormatter.FmtInt, o.AllChannels);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
