classdef WTCommonScalpMapPlotsCfg < matlab.mixin.Copyable

    properties
        Time(1,:) {WTValidations.mustBeALimitedLinearArray(Time, 1, 3, 1)}
        Frequency(1,:) {WTValidations.mustBeALimitedLinearArray(Frequency, 1, 3, 1)}
        Scale(1,:) single {WTValidations.mustBeALimitedLinearArray(Scale, 1, 2, 1)} 
    end

    methods
        function o = WTCommonScalpMapPlotsCfg()
            o.default();
        end

        function default(o) 
            o.Time = [];
            o.Frequency = [];
            o.Scale = [];
        end

        function success = validate(o, throwExcpt)
            throwExcpt = nargin > 1 && any(logical(throwExcpt)); 
            success = true;

            nTime = numel(o.Time);
            nFreq = numel(o.Frequency);

            if nTime == 0
                WTUtils.throwOrLog(WTException.badValue('Field Time should conatain between 1 and 3 values'), ~throwExcpt);
                success = false;
            end
            if nFreq == 0
                WTUtils.throwOrLog(WTException.badValue('Field Frequency should conatain between 1 and 3 values'), ~throwExcpt);
                success = false;
            end
            if nTime == 3 && nFreq == 3 
                WTUtils.throwOrLog(WTException.badValue('Field Frequency & Time cannot both have 3 values (i.e. both define series)'), ~throwExcpt);
                success = false;
            end
            if nTime == 2 && o.Time(1) >= o.Time(2)
                WTUtils.throwOrLog(WTException.badValue('Field Time(2) <= Time(1)'), ~throwExcpt);
                success = false;
            end
            if nTime == 3 && nelem(o.Time(1):o.Time(2):o.Time(3)) == 0 
                WTUtils.throwOrLog(WTException.badValue('Field Time defines an empty time serie'), ~throwExcpt);
                success = false;
            end
            if o.Frequency(1) == 0 
                WTUtils.throwOrLog(WTException.badValue('Field Frequency(1) cannot be 0'), ~throwExcpt);
                success = false;
            end
            if nFreq == 2 && o.Frequency(1) >= o.Frequency(2)
                WTUtils.throwOrLog(WTException.badValue('Field Frequency(2) <= Frequency(1)'), ~throwExcpt);
                success = false;
            end
            if nFreq == 3 && nelem(o.Frequency(1):o.Frequency(2):o.Frequency(3)) == 0 
                WTUtils.throwOrLog(WTException.badValue('Field Frequency defines an empty time serie'), ~throwExcpt);
                success = false;
            end
            if o.Scale(1) >= o.Scale(2) 
                WTUtils.throwOrLog(WTException.badValue('Field Scale(2) <= Scale(1)'), ~throwExcpt);
                success = false;
            end
        end
    end
end
