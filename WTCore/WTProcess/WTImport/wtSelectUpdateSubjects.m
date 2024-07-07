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

function [success, sbjFileNames] = wtSelectUpdateSubjects(system) 
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    subjectsParams = wtProject.Config.Subjects;
    sbjFileNames = {};

    if subjectsParams.exist()
        if ~WTEEGLabUtils.eeglabYesNoDlg('Re-import subjects?', ['The subject configuration file already exists!\n' ...
                'Do you want to import the subjects again?'])
            return;
        end            
    end     
    
    [subjects, sbjFileNames] = WTImportGUI.selectImportedSubjects(system);
    if isempty(subjects) 
        wtLog.warn('No subjects to import selected');
        return
    end

    subjectsParams = copy(subjectsParams);
    subjectsParams.SubjectsList = subjects;
    subjectsParams.ImportedSubjectsList = subjects;
    subjectsParams.FilesList = sbjFileNames;

    if ~subjectsParams.persist()
        wtProject.notifyErr([], 'Failed to save subjects to import params');
        return
    end

    wtProject.Config.Subjects = subjectsParams;
    success = true;
end