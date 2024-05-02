classdef WT3DScalpMapPlotsCfg < WTConfigStorage & matlab.mixin.Copyable & WTCommonScalpMapPlotsCfg

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    methods
        function o = WT3DScalpMapPlotsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'smavr3d_cfg.m');
            o@WTCommonScalpMapPlotsCfg();
            o.AllowTimeResolution = false;
            o.AllowFreqResolution = false;
            o.default()
        end

        function default(o) 
            default@WTCommonScalpMapPlotsCfg(o)
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 3
                    o.Time = cells{1};
                    o.Frequency = cells{2};
                    o.Scale = WTUtils.str2nums(cells{3});
                    o.validate();
                else
                    o.default()
                    WTLog().warn(['The parameters for 3D scalp map plots (%s) were set by a\n' ...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTFormatter.FmtArrayStr, num2str(o.Time), ...
                WTFormatter.FmtArrayStr, num2str(o.Frequency), ...
                WTFormatter.FmtArrayStr, num2str(o.Scale));
            success = ~isempty(txt) && o.write(txt);
        end
    end
end