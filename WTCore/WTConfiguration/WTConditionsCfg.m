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

classdef WTConditionsCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldConditions     = 'conditions'
        FldConditionsDiff = 'condiff'
    end

    properties
        ConditionsList cell {WTValidations.mustBeLinearCellArrayOfNonEmptyChar} = {}
        ConditionsDiff cell {WTValidations.mustBeLinearCellArrayOfNonEmptyChar} = {} 
    end
    
    methods
        function o = WTConditionsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'cond.m');
            o.default();
        end

        function default(o) 
            o.ConditionsList = {};
        end

        function set.ConditionsList(o, value)
            o.ConditionsList = sort(unique(value));
        end

        function set.ConditionsDiff(o, value)
            o.ConditionsDiff = sort(unique(value));
        end

        function success = load(o) 
            [success, conds, diff] = o.read(o.FldConditions, o.FldConditionsDiff);
            if ~success
                return
            end
            try
                o.ConditionsList = conds;
                o.ConditionsDiff = diff;
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt1 = WTConfigFormatter.stringCellsField(o.FldConditions, o.ConditionsList);
            txt2 = WTConfigFormatter.stringCellsField(o.FldConditionsDiff, o.ConditionsDiff);
            success = ~isempty(txt1) && ~isempty(txt2) && o.write(txt1, txt2);
        end
    end
end
