
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

classdef WTImportGUI
    
    methods(Static)
        function [subjects, subjFileNames] = selectImportedSubjects(system) 
            wtProject = WTProject();
            wtLog = WTLog();

            ioProc = wtProject.Config.IOProc;
            subjectsParams = wtProject.Config.Subjects;

            subjects = [];
            subjFileNames = ioProc.enumImportFiles(system);

            if isempty(subjFileNames) 
                WTEEGLabUtils.eeglabMsgDlg('Warning', 'No import files found');
                return
            end

            preSelectedIdx = cellfun(@(x)find(strcmp(x, subjFileNames)), intersect(subjFileNames, subjectsParams.FilesList));
             
            subjFileNames = WTDialogUtils.stringsSelectDlg('Select files/subjects', subjFileNames, false, true, 'InitialValue', preSelectedIdx);
            if isempty(subjFileNames) 
                wtLog.warn('No subject selected as no import files have been selected');
                return
            end

            [subjects, subjFileNames] = ioProc.getSubjectsFromImportFiles(system, subjFileNames{:});
            if isempty(subjects)
                wtLog.warn('No subject numbers could be found');
                return
            end
        end
    

        function conditions = selectImportedConditions(system, anyImportedFile) 
            wtProject = WTProject();
            wtLog = WTLog();
            conditions = {};

            ioProc = wtProject.Config.IOProc;
            conditionsPrms = wtProject.Config.Conditions;

            [success, conditions, ~] = ioProc.getConditionsFromImport(system, anyImportedFile);
            if ~success
                wtLog.err('Failed to get conditions from imported file ''%s''', anyImportedFile);
                return
            end

            preSelectedIdx = cellfun(@(x)find(strcmp(x, conditions)), intersect(conditions, conditionsPrms.ConditionsList));
            conditions = WTDialogUtils.stringsSelectDlg('Select conditions', conditions, false, true,  'InitialValue', preSelectedIdx);
        end
    end
end