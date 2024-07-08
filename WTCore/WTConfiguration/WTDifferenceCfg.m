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

classdef WTDifferenceCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        Condition1(1,1) int8 {WTValidations.mustBeGT(Condition1,0,0,0)} = 1
        Condition2(1,1) int8 {WTValidations.mustBeGT(Condition2,0,0,0)} = 1
        ConditionsDiff(1,1) int8 {WTValidations.mustBeGT(ConditionsDiff,0,0,0)} = 1
        LogarithmicTransform(1,1) int8 {WTValidations.mustBeZeroOrOne}
        EvokedOscillations(1,1) int8 {WTValidations.mustBeZeroOrOne}
    end

    methods
        function o = WTDifferenceCfg(ioProc)
            o@WTConfigStorage(ioProc, 'difference_cfg.m');
            o.default();
        end

        function default(o) 
            o.Condition1 = 1;
            o.Condition2 = 1;
            o.ConditionsDiff = 1;
            o.LogarithmicTransform = 0;
            o.EvokedOscillations = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 5
                    o.Condition1 = cells{1};
                    o.Condition2 = cells{2};
                    o.ConditionsDiff = cells{3};
                    o.LogarithmicTransform = cells{4};
                    o.EvokedOscillations = cells{5};
                else 
                    o.default();
                    WTLog().warn(['The difference parameters (%s) were set by an \n'...
                        'incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.intCellsFieldArgs(o.FldDefaultAnswer, o.Condition1, o.Condition2, o.ConditionsDiff, o.LogarithmicTransform, o.EvokedOscillations);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
