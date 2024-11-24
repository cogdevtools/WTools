% Copyright (C) 2024 Eugenio Parise, Luca Filippin
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.

classdef WTPacedTimeFreqCfg < matlab.mixin.Copyable & matlab.mixin.SetGet
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

    properties (Access = private)
        GuardedSet logical = true;
    end

    properties (GetAccess = public, SetAccess = protected)
        AllowTimeResolution logical
        AllowFreqResolution logical
    end

    methods(Access = private)
        function success = validateTime(o, time, throwExcpt) 
            if ~o.GuardedSet
                success = true;
                return
            end

            throwExcpt = nargin > 1 && throwExcpt; 
            success = false;
            nTime = numel(time);

            if nTime == 0 
                WTCodingUtils.throwOrLog(WTException.badValue('Field Time should contain between 1 and %d values', ...
                    WTCodingUtils.ifThenElse(o.AllowTimeResolution, 3, 2)), ~throwExcpt);
                return
            end
            if nTime == 2 && time(1) >= time(2)
                WTCodingUtils.throwOrLog(WTException.badValue('Field Time(2) <= Time(1)'), ~throwExcpt);
                return
            end
            if nTime == 3 && isempty(time(1):time(2):time(3))
                WTCodingUtils.throwOrLog(WTException.badValue('Field Time defines an empty time serie'), ~throwExcpt);
                return
            end
            success = true;
        end

        function success = validateFrequency(o, freq, throwExcpt)
            if ~o.GuardedSet
                success = true;
                return
            end

            throwExcpt = nargin > 1 && throwExcpt; 
            success = false;
            nFreq = numel(freq);

            if nFreq == 0
                WTCodingUtils.throwOrLog(WTException.badValue('Field Frequency should contain between 1 and %d values', ... 
                    WTCodingUtils.ifThenElse(o.AllowFreqResolution, 3, 2)), ~throwExcpt);
                return
            end

            if freq(1) <= 0 
                WTCodingUtils.throwOrLog(WTException.badValue('Field Frequency(1) cannot be <= 0'), ~throwExcpt);
                return
            end
            if nFreq == 2 && freq(1) >= freq(2)
                WTCodingUtils.throwOrLog(WTException.badValue('Field Frequency(2) <= Frequency(1)'), ~throwExcpt);
                return
            end
            if nFreq == 3 && isempty(freq(1):freq(2):freq(3))
                WTCodingUtils.throwOrLog(WTException.badValue('Field Frequency defines an empty time serie'), ~throwExcpt);
                return
            end
            success = true;
        end
    end

    methods
        function o = WTPacedTimeFreqCfg()
            o.AllowTimeResolution = true;
            o.AllowFreqResolution = true; 
            o.default();
        end

        function default(o) 
            o.GuardedSet = false;
            o.Time = [];
            o.Frequency = [];
            o.GuardedSet = true;
        end

        function set.Time(o, value)
            if ischar(value)
                value = WTNumUtils.strRange2nums(value, '[]');
            end
            nMaxValues = WTCodingUtils.ifThenElse(o.AllowTimeResolution, 3, 2);
            WTValidations.mustBeLimitedLinearArray(value, 1, nMaxValues, 1)
            o.validateTime(value, true);
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
            WTValidations.mustBeGTE(nTime, 2, 0, 0)
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
            WTValidations.mustBeLimitedLinearArray(value, 1, nMaxValues, 1)
            WTValidations.mustBeGT(value, 0, 0, 0);
            o.validateFrequency(value, true);
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
            WTValidations.mustBeGTE(nFreq, 2, 0, 0)
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
            success = o.validateTime(o.Time, throwExcpt) && o.validateFrequency(o.Frequency, throwExcpt);
            if success && numel(o.Time) == 3 && numel(o.Frequency) == 3
                WTCodingUtils.throwOrLog(WTException.badValue('Field Frequency & Time cannot both have 3 values (i.e. both define series)'), ~throwExcpt);
                success = false;
            end
        end
    end
end