classdef WTPacedTimeFreqCfg < matlab.mixin.Copyable

    % When Time and Frequency contain only 1 value, then they represent a single point set.
    % When they contain 2 values they represent a range, when they contain 3 values they 
    % represent a range of paced values, where the pace is the middle value.
    properties
        Time(1,:)
        Frequency(1,:)
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

    properties (GetAccess = public, SetAccess = protected)
        AllowTimeResolution logical
        AllowFreqResolution logical
    end

    methods
        function o = WTPacedTimeFreqCfg()
            o.AllowTimeResolution = true;
            o.AllowFreqResolution = true; 
            o.default();
        end

        function default(o) 
            o.Time = [];
            o.Frequency = [];
        end

        function set.Time(o, value)
            if ischar(value)
                value = WTNumUtils.strRange2nums(value, '[]');
            end
            nMaxValues = WTCodingUtils.ifThenElse(o.AllowTimeResolution, 3, 2);
            WTValidations.mustBeALimitedLinearArray(value, 1, nMaxValues, 1)
            o.Time = value;
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
            if ~o.AllowTimeResolution 
                WTException.unsupported('Time resolution is not supported').throw();
            end
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

        function set.Frequency(o, value)
            if ischar(value)
                value = WTNumUtils.strRange2nums(value, '[]');
            end
            nMaxValues = WTCodingUtils.ifThenElse(o.AllowFreqResolution, 3, 2);
            WTValidations.mustBeALimitedLinearArray(value, 1, nMaxValues, 1)
            o.Frequency = value;
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
            if ~o.AllowFreqResolution 
                WTException.unsupported('Frequency resolution is not supported').throw();
            end
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
                WTCodingUtils.throwOrLog(WTException.badValue('Field Time should contain between 1 and %d values', ...
                    WTCodingUtils.ifThenElse(o.AllowTimeResolution, 3, 2)), ~throwExcpt);
                return
            end
            if nFreq == 0
                WTCodingUtils.throwOrLog(WTException.badValue('Field Frequency should contain between 1 and %d values', ... 
                    WTCodingUtils.ifThenElse(o.AllowFreqResolution, 3, 2)), ~throwExcpt);
                return
            end
            if nTime == 3 && nFreq == 3 
                WTCodingUtils.throwOrLog(WTException.badValue('Field Frequency & Time cannot both have 3 values (i.e. both define series)'), ~throwExcpt);
                return
            end
            if nTime == 2 && o.Time(1) >= o.Time(2)
                WTCodingUtils.throwOrLog(WTException.badValue('Field Time(2) <= Time(1)'), ~throwExcpt);
                return
            end
            if nTime == 3 && isempty(o.Time(1):o.Time(2):o.Time(3))
                WTCodingUtils.throwOrLog(WTException.badValue('Field Time defines an empty time serie'), ~throwExcpt);
                return
            end
            if o.Frequency(1) == 0 
                WTCodingUtils.throwOrLog(WTException.badValue('Field Frequency(1) cannot be 0'), ~throwExcpt);
                return
            end
            if nFreq == 2 && o.Frequency(1) >= o.Frequency(2)
                WTCodingUtils.throwOrLog(WTException.badValue('Field Frequency(2) <= Frequency(1)'), ~throwExcpt);
                return
            end
            if nFreq == 3 && isempty(o.Frequency(1):o.Frequency(2):o.Frequency(3))
                WTCodingUtils.throwOrLog(WTException.badValue('Field Frequency defines an empty time serie'), ~throwExcpt);
                return
            end

            success = true;
        end
    end
end
