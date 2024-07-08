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

classdef WTEpochsAndFreqFiltersCfg < matlab.mixin.Copyable & matlab.mixin.SetGet

    properties
        EpochLimits(1,:) single {mustBeFinite, WTValidations.mustBeLimitedLinearArray(EpochLimits, 2, 2, 1)}
        LowPassFilter single {WTValidations.mustBeGTE(LowPassFilter,0,1,0)} = NaN
        HighPassFilter single {WTValidations.mustBeGT(HighPassFilter,0,1,0)} = NaN
    end

    methods
        function o = WTEpochsAndFreqFiltersCfg()
            o.default();
        end

        function default(o)  
            o.EpochLimits = [];
            o.LowPassFilter = NaN;
            o.HighPassFilter = NaN;
        end

        function success = validate(o, throwExcpt) 
            throwExcpt = nargin > 1 && throwExcpt; 
            success = true;

            if ~isempty(o.EpochLimits) && o.EpochLimits(0) >= o.EpochLimits(1)
                WTCodingUtils.throwOrLog(WTException.badValue('Field EpochLimits[2] < EpochLimits[1]'), ~throwExcpt);
                success = false;
                return
            end

            if ~isnan(o.LowPassFilter) && ~isnan(o.HighPassFilter) && o.LowPassFilter >= o.HighPassFilter
                WTCodingUtils.throwOrLog(WTException.badValue('Field HighPassFilter <= LowPassFilter'), ~throwExcpt);
                success = false;
                return
            end
        end
    end
end
