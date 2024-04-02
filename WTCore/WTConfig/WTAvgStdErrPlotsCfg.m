classdef WTAvgStdErrPlotsCfg < WTConfigStorage & matlab.mixin.Copyable & WTCommonPlotsCfg

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        AllChannels(1,1) uint8 {WTValidations.mustBeZeroOrOne}
    end


    methods
        function o = WTAvgStdErrPlotsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'xavrse_cfg.m');
            o@WTCommonPlotsCfg();
            o.default()
        end

        function default(o) 
            default@WTCommonPlotsCfg(o)
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 5
                    o.TimeMin = WTUtils.str2double(cells{1});
                    o.TimeMax = WTUtils.str2double(cells{2});
                    o.FreqMin = WTUtils.str2double(cells{3});
                    o.FreqMax = WTUtils.str2double(cells{4});
                    o.AllChannels = cells{5};
                    o.validate();
                else
                    o.default()
                    WTLog().warn(['The  parameters for average & standard error plots (%s) were set by a\n' ...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
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
                WTFormatter.FmtIntStr, o.FreqMax, .....
                WTFormatter.FmtInt, o.AllChannels);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end