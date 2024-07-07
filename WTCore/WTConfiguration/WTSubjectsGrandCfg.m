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

classdef WTSubjectsGrandCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldSubjects = 'subjects'
    end

    properties
        SubjectsList cell {WTValidations.mustBeLinearCellArrayOfNonEmptyChar} = {}
    end

    methods
        function o = WTSubjectsGrandCfg(ioProc)
            o@WTConfigStorage(ioProc, 'subjgrand.m');
            o.default();
        end

        function default(o) 
            o.SubjectsList = {};
        end

        function set.SubjectsList(o, value)
            o.SubjectsList = sort(unique(value));
        end
        
        function success = load(o) 
            [success, subjs] = o.read(o.FldSubjects);
            if ~success
                return
            end
            try
                o.SubjectsList = subjs;
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.stringCellsField(o.FldSubjects, o.SubjectsList);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end