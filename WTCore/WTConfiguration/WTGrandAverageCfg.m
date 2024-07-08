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

classdef WTGrandAverageCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        UseAllSubjects(1,1) int8 {WTValidations.mustBeZeroOrOne} = 0
        PerSubjectAverage(1,1) int8 {WTValidations.mustBeZeroOrOne} = 0
        LogarithmicTransform(1,1) int8 {WTValidations.mustBeZeroOrOne} = 0
        EvokedOscillations(1,1) int8 {WTValidations.mustBeZeroOrOne} = 0
    end

    methods
        function o = WTGrandAverageCfg(ioProc)
            o@WTConfigStorage(ioProc, 'grand_cfg.m');
            o.default();
        end

        function default(o) 
            o.UseAllSubjects = 1;
            o.PerSubjectAverage = 1;
            o.LogarithmicTransform = 0;
            o.EvokedOscillations = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 4
                    o.UseAllSubjects = cells{1};
                    o.PerSubjectAverage = cells{2};
                    o.LogarithmicTransform = cells{3};
                    o.EvokedOscillations = cells{4};
                else 
                    o.default()
                    WTLog().warn(['The grand average parameters (%s) were set by an \n'...
                        'incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.intCellsFieldArgs(o.FldDefaultAnswer, o.UseAllSubjects, o.PerSubjectAverage, o.LogarithmicTransform, o.EvokedOscillations);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end