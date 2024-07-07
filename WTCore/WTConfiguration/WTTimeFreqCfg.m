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

classdef WTTimeFreqCfg < matlab.mixin.Copyable & matlab.mixin.SetGet

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
