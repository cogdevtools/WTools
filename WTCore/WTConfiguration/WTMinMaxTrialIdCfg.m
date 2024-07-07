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
        MinTrialId int32 {WTValidations.mustBeGTE(MinTrialId, 0, 1)}
        MaxTrialId int32 {WTValidations.mustBeGTE(MaxTrialId, 0, 1)}
    end

    methods
        function o = WTMinMaxTrialIdCfg(ioProc)
            o@WTConfigStorage(ioProc, 'minmaxtrialid.m');
            o.default();
        end

        function default(o) 
            o.MinTrialId = NaN;
            o.MaxTrialId = NaN;
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
            success = true;
            throwExcpt = nargin > 1 && throwExcpt; 

            if ~isnan(o.MinTrialId) && ~isnan(o.MaxTrialId)
                if o.MaxTrialId < o.MinTrialId;
                    WTCodingUtils.throwOrLog(WTException.badValue('Field MaxTrialId < MinTrialId'), ~throwExcpt);
                    success = false;
                end
            end
        end

        function isAllTrials= allTrials(o)
            isAllTrials = isnan(o.MinTrialId) && isnan(o.MaxTrialId);
        end

        function newObj = interpret(o)
            newObj = copy(o);
            if isnan(o.MinTrialId) && isnan(o.MaxTrialId) % all trials case
                return
            elseif isnan(o.MaxTrialId)
                newObj.MaxTrialId = 1000000; % set an arbitrary large enough number
            elseif isnan(o.MinTrialId)
                newObj.MinTrialId = 0; % set a value < of the min possible trial = 1
            end
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ....
                WTConfigFormatter.FmtIntStr, o.MinTrialId, ...
                WTConfigFormatter.FmtIntStr, o.MaxTrialId);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end