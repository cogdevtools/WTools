classdef WTEEPToEEGLabCfg < WTConfigStorage & matlab.mixin.Copyable & WTEpochLimitsAndFreqFilterCfg

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    methods
        function o = WTEEPToEEGLabCfg(ioProc)
            o@WTConfigStorage(ioProc, 'eep2eegl_cfg.m');
            o@WTEpochLimitsAndFreqFilterCfg();
            o.default();
        end

        function default(o)  
            default@WTEpochLimitsAndFreqFilterCfg(o);
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 3 
                    o.EpochLimits =  WTUtils.str2nums(cells{1});
                    o.HighPassFilter = WTUtils.str2double(cells{2});
                    o.LowPassFilter = WTUtils.str2double(cells{3});
                    o.validate(true)
                else
                    WTLog().err('EEP to EEGLab conversion (%s): wrong number of parameters (should be 3)', o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                o.default()
                success = false;
            end 
        end

        function success = validate(o, throwExcpt) 
            success = validate@WTEpochLimitsAndFreqFilterCfg(o, throwExcpt);
        end

        function success = persist(o)
            txt = WTFormatter.GenericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTFormatter.FmtArrayStr, num2str(o.EpochLimits), ...
                WTFormatter.FmtFloatStr, o.HighPassFilter, ...
                WTFormatter.FmtFloatStr, o.LowPassFilter);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
