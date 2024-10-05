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

classdef WTMinMaxTrialIdCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        MinTrialId int32
        MaxTrialId int32
    end

    methods
        function o = WTMinMaxTrialIdCfg(ioProc)
            o@WTConfigStorage(ioProc, 'minmaxtrialid.m');
            o.default();
        end

        function default(o) 
            o.MinTrialId = 1;
            o.MaxTrialId = Inf;
        end

        function set.MinTrialId(o, value)
            WTValidations.mustBeGTE(value,1,1,0);
            o.MinTrialId = WTCodingUtils.ifThenElse(isnan(value), 1, value);
        end

        function set.MaxTrialId(o, value)
            WTValidations.mustBeGTE(value,1,1,1);
            o.MaxTrialId = WTCodingUtils.ifThenElse(isnan(value), Inf, value);
        end

        function value = MaxTrialIdStr(o)
            value = WTCodingUtils.ifThenElse(o.MaxTrialId == int32(Inf), 'Inf', num2str(o.MaxTrialId));
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success
                return
            end
            try
                if length(cells) >= 2
                    % For backward compatibility
                    o.MinTrialId = WTNumUtils.str2double(cells{1}, true);
                    o.MaxTrialId = WTNumUtils.str2double(cells{2}, true);
                    o.validate(true);
                else 
                    o.default();
                    WTLog().warn(['The min/max trial id parameters (%s) were inconsistent or set by a\n'...
                        'incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                o.default();
                success = false;
            end 
        end

        function success = validate(o, throwExcpt) 
            success = false;
            throwExcpt = nargin > 1 && throwExcpt; 

            if o.MaxTrialId < o.MinTrialId
                WTCodingUtils.throwOrLog(WTException.badValue('Field MaxTrialId < MinTrialId'), ~throwExcpt);
                return
            end
            success = true;
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ....
                WTConfigFormatter.FmtIntStr, o.MinTrialId, ...
                WTConfigFormatter.FmtStr, o.MaxTrialIdStr());
            success = ~isempty(txt) && o.write(txt);
        end
    end
end