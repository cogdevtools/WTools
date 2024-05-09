classdef WTTimeFreqCfg < matlab.mixin.Copyable

    properties
        TimeMin(1,1) single
        TimeMax(1,1) single
        FreqMin(1,1) uint32
        FreqMax(1,1) uint32
    end

    methods
        function o = WTTimeFreqCfg()
            o.default();
        end

        function default(o) 
            o.TimeMin = 0;
            o.TimeMax = 0;
            o.FreqMin = 0;
            o.FreqMax = 0;
        end

        function success = validate(o, throwExcpt)
            throwExcpt = nargin > 1 && throwExcpt; 
            success = true;

            if o.TimeMin > o.TimeMax 
                WTCodingUtils.throwOrLog(WTException.badValue('Field TimeMax < TimeMin'), ~throwExcpt);
                success = false;
            end
            if o.FreqMin > o.FreqMax 
                WTCodingUtils.throwOrLog(WTException.badValue('Field FreqMax < FreqMin'), ~throwExcpt);
                success = false;
            end
        end
    end
end
