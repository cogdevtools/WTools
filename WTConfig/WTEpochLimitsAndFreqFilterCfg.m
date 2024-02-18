classdef WTEpochLimitsAndFreqFilterCfg < matlab.mixin.Copyable

    properties
        EpochLimits(1,:) single {mustBeFinite, WTValidations.mustBeALimitedLinearArray(EpochLimits, 2, 2, 1)}
        LowPassFilter single {WTValidations.mustBeGTE(LowPassFilter, 0)}
        HighPassFilter single {WTValidations.mustBeGT(HighPassFilter, 0)}
    end

    methods
        function o = WTEpochLimitsAndFreqFilterCfg()
            o.default();
        end

        function default(o)  
            o.EpochLimits = [];
            o.LowPassFilter = NaN;
            o.HighPassFilter = NaN;
        end

        function success = validate(o, throwExcpt) 
            throwExcpt = nargin > 1 && any(logical(throwExcpt)); 
            success = true;

            if ~isempty(o.EpochLimits) && o.EpochLimits(0) >= o.EpochLimits(1)
                WTUtils.throwOrLog(WTException.badValue('Field EpochLimits[2] < EpochLimits[1]'), ~throwExcpt);
                success = false;
            end

            if ~isnan( o.LowPassFilter) && ~isnan(o.HighPassFilter) && o.LowPassFilter >= o.HighPassFilter
                WTUtils.throwOrLog(WTException.badValue('Field HighPassFilter <= LowPassFilter'), ~throwExcpt);
                return
            end
            success = true;
        end
    end
end
