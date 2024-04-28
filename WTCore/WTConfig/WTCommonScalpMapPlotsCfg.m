classdef WTCommonScalpMapPlotsCfg < matlab.mixin.Copyable

    properties
        Time(1,:) {WTValidations.mustBeALimitedLinearArray(Time, 1, 3, 1)}
        Frequency(1,:) {WTValidations.mustBeALimitedLinearArray(Frequency, 1, 3, 1)}
        Scale(1,:) single {WTValidations.mustBeALimitedLinearArray(Scale, 1, 2, 1)} 
    end

    properties (Dependent)
        TimeMin
        TimeMax
        TimeResolution 
        FreqMin
        FreqMax
        FreqResolution
        TimeString
        FreqString
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

        function setTimeMin(o, value)
            o.Time(1) = value;
        end

        function setTimeMax(o, value)
            if length(o.Time) > 1
                o.Time(end) = value;
            else
                o.Time(2) = value;
            end
        end

         % Time resolution can be set only TimeMin and TimeMax have been already 
        function setTimeResolution(o, value)
            nTime = length(o.Time);
            WTValidations.mustBeGTE(nTime, 2)
            if nTime > 2
                o.Time(2) = value;
            else
                o.Time = [o.Time(1) value o.Time(2)];
            end
        end

        function timeMin = get.TimeMin(o)
            timeMin = [];
            if length(o.Time) >= 1 
                timeMin = o.Time(1);
            end
        end

        function timeMax = get.TimeMax(o) 
            timeMax = [];
            if length(o.Time) >= 2 
                timeMax = o.Time(end);
            end
        end

        function timeResolution = get.TimeResolution(o) 
            timeResolution = [];
            if length(o.Time) > 2 
                timeResolution = o.Time(2);
            end
        end

        function str = get.TimeString(o) 
            str = regexprep(num2str(o.Time), '\s+', ':');
        end

        function setFreqMin(o, value)
            o.Frequency(1) = value;
        end

        function setFreqMax(o, value)
            if length(o.Frequency) > 1
                o.Frequency(end) = value;
            else
                o.Frequency(2) = value;
            end
        end

        % Frequency resolution can be set only FreqMin and FreqMax have been already 
        function setFreqResolution(o, value)
            nFreq = length(o.Frequency);
            WTValidations.mustBeGTE(nFreq, 2)
            if nFreq > 2
                o.Frequency(2) = value;
            else
                o.Frequency = [o.Frequency(1) value o.Frequency(2)];
            end
        end

        function timeMin = get.FreqMin(o)
            timeMin = [];
            if length(o.Frequency) >= 1 
                timeMin = o.Frequency(1);
            end
        end

        function freqMax = get.FreqMax(o) 
            freqMax = [];
            if length(o.Frequency) >= 2 
                freqMax = o.Frequency(end);
            end
        end

        function freqResolution = get.FreqResolution(o) 
            freqResolution = [];
            if length(o.Frequency) > 2 
                freqResolution = o.Frequency(2);
            end
        end

        function str = get.FreqString(o) 
            str = regexprep(num2str(o.Frequency), '\s+', ':');
        end

        function success = validate(o, throwExcpt)
            throwExcpt = nargin > 1 && throwExcpt; 
            success = false;

            nTime = numel(o.Time);
            nFreq = numel(o.Frequency);

            if nTime == 0
                WTUtils.throwOrLog(WTException.badValue('Field Time should contain between 1 and 3 values'), ~throwExcpt);
                return
            end
            if nFreq == 0
                WTUtils.throwOrLog(WTException.badValue('Field Frequency should contain between 1 and 3 values'), ~throwExcpt);
                return
            end
            if nTime == 3 && nFreq == 3 
                WTUtils.throwOrLog(WTException.badValue('Field Frequency & Time cannot both have 3 values (i.e. both define series)'), ~throwExcpt);
                return
            end
            if nTime == 2 && o.Time(1) >= o.Time(2)
                WTUtils.throwOrLog(WTException.badValue('Field Time(2) <= Time(1)'), ~throwExcpt);
                return
            end
            if nTime == 3 && isempty(o.Time(1):o.Time(2):o.Time(3))
                WTUtils.throwOrLog(WTException.badValue('Field Time defines an empty time serie'), ~throwExcpt);
                return
            end
            if o.Frequency(1) == 0 
                WTUtils.throwOrLog(WTException.badValue('Field Frequency(1) cannot be 0'), ~throwExcpt);
                return
            end
            if nFreq == 2 && o.Frequency(1) >= o.Frequency(2)
                WTUtils.throwOrLog(WTException.badValue('Field Frequency(2) <= Frequency(1)'), ~throwExcpt);
                return
            end
            if nFreq == 3 && isempty(o.Frequency(1):o.Frequency(2):o.Frequency(3))
                WTUtils.throwOrLog(WTException.badValue('Field Frequency defines an empty time serie'), ~throwExcpt);
                return
            end
            if o.Scale(1) >= o.Scale(2) 
                WTUtils.throwOrLog(WTException.badValue('Field Scale(2) <= Scale(1)'), ~throwExcpt);
                return
            end

            success = true;
        end
    end
end
