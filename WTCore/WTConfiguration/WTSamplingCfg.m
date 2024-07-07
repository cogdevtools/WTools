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

classdef WTSamplingCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        SamplingRate single {mustBeFinite, WTValidations.mustBeGT(SamplingRate, 0)}
    end

    methods
        function o = WTSamplingCfg(ioProc)
            o@WTConfigStorage(ioProc, 'samplrate.m');
            o.default();
        end

        function default(o) 
            o.SamplingRate = 1;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success
                return
            end
            try
                o.SamplingRate = WTNumUtils.str2double(cells{1});
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, WTConfigFormatter.FmtStr, num2str(o.SamplingRate));
            success = ~isempty(txt) && o.write(txt);
        end
    end
end