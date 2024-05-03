classdef WTChansAvgStdErrPlotsCfg < WTConfigStorage & matlab.mixin.Copyable & WTTimeFreqCfg

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    methods
        function o = WTChansAvgStdErrPlotsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'xavrse_cfg.m');
            o@WTTimeFreqCfg();
            o.default()
        end

        function default(o) 
            default@WTTimeFreqCfg(o)
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 4
                    o.TimeMin = WTUtils.str2double(cells{1});
                    o.TimeMax = WTUtils.str2double(cells{2});
                    o.FreqMin = WTUtils.str2double(cells{3});
                    o.FreqMax = WTUtils.str2double(cells{4});
                    o.validate();
                else
                    o.default()
                    WTLog().warn(['The parameters for channels average & standard error plots (%s) were set by a\n' ...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTConfigFormatter.FmtIntStr, o.TimeMin, ...
                WTConfigFormatter.FmtIntStr, o.TimeMax, ...
                WTConfigFormatter.FmtIntStr, o.FreqMin, ...
                WTConfigFormatter.FmtIntStr, o.FreqMax);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end