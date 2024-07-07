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

function success = wtRebuildSubjects()
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkWaveletAnalysisDone(false, false)
        return
    end

    analysisSubjects = 'Subjects Analysis';
    grandAnalysisSubjects = 'Subjects Grand Analysis';
    optionsList = { analysisSubjects, grandAnalysisSubjects };

    selection = WTDialogUtils.stringsSelectDlg('Select lists to rebuild:', optionsList, false, true, 'ListSize', [190, 120]);
    if isempty(selection)
        return
    end

    rebuildSubjects = any(strcmp(selection, analysisSubjects));
    rebuildSubjectsGrand = any(strcmp(selection, grandAnalysisSubjects));

    if ~WTProcessUtils.sanitizeSubjectsLists()
        wtProject.notifyErr([], 'Failed to sanitize subjects lists');
        return
    end

    subjectsPrms = wtProject.Config.Subjects;
    subjectsGrandPrms = wtProject.Config.SubjectsGrand;

    if isempty(subjectsPrms.ImportedSubjectsList)
        wtProject.notifyWrn([], 'No subjects have been imported yet');
        return
    end

    if isempty(subjectsPrms.SubjectsList)
        wtProject.notifyWrn([], 'No subjects have been analysed yet');
        return
    end

    if rebuildSubjects
        importedSubjs = subjectsPrms.ImportedSubjectsList;
        crntSubjs = cellfun(@(s)find(strcmp(importedSubjs, s)), subjectsPrms.SubjectsList);

        subjects = WTDialogUtils.stringsSelectDlg('Select analysed subjects:', ...
            importedSubjs, false, true, 'InitialValue', crntSubjs);

        if isempty(subjects)
            return
        end

        subjectsPrms = copy(subjectsPrms);
        subjectsPrms.SubjectsList = subjects;

        if ~subjectsPrms.persist()
            wtProject.notifyErr([], 'Failed to save new analysed subjects list');
            return
        end

        wtLog.info('New analysed subjects list successfully saved');
        wtProject.Config.Subjects = subjectsPrms;              
    end

    if rebuildSubjects || rebuildSubjectsGrand
        select = rebuildSubjectsGrand;
        update = false;

        if isempty(subjectsPrms.SubjectsList) 
            if ~isempty(subjectsGrandPrms.SubjectsList)
                wtProject.notifyWrn([], 'No subjects in the analysed subjects list: grand analysis subjects list will be voided.');
                subjects = {};
                update = true;
            elseif rebuildSubjectsGrand
                wtProject.notifyWrn([], 'The analysed subjects list is empty, so you can''t select subjects for the grand analysis.');
            end
            select = false;
        elseif ~rebuildSubjectsGrand
            if isempty(subjectsGrandPrms.SubjectsList)
                wtProject.notifyWrn([], ['The grand average subjects list is empty, you must select some subjects or it will\n' ...
                    'be automatically set with all the subjects in the analysis list.']);
                subjects = subjectsPrms.SubjectsList;
                select = true;
                update = true;
            else
                subjects = intersect(subjectsPrms.SubjectsList, subjectsGrandPrms.SubjectsList);
                if length(subjects) ~= length(subjectsGrandPrms.SubjectsList)
                    wtProject.notifyInf([], ['You have removed subjects from the analysis list subjects that were part of the grand analysis:\n' ...
                        'please review the subjects selection for the grand analysis or it will be updated automatically either by eliminatng\n' ...
                        'the missing subjects or, if that generates an empty list, with all the subjects in the analysis list.']);
                end
                select = true;
                update = true;
            end
        end

        if select
            crntSubjs = cellfun(@(s)find(strcmp(subjects, s)), subjectsPrms.SubjectsList);
            newSubjects = WTDialogUtils.stringsSelectDlg('Select subjects to\ninclude in the\ngrand analysis:', ...
                subjects, false, true, 'InitialValue', crntSubjs);
            if ~isempty(newSubjects)
                subjects = newSubjects;
                update = true;
            end
        end
        
        if update
            subjectsGrandPrms = copy(subjectsGrandPrms);
            subjectsGrandPrms.SubjectsList = subjects;
            if ~subjectsGrandPrms.persist()
                wtProject.notifyErr([], 'Failed to save new grand analysis subjects list');
                return
            end
            wtLog.info('New grand analysis subjects list successfully saved');
            wtProject.Config.SubjectsGrand = subjectsGrandPrms; 
        end
    end

    wtLog.info('Rebuild done.');
    success = true;
end
 