% wtRebuildSubjects.m
% Created by Eugenio Parise
% CDC CEU 2012
% Function to rebuild subj.m and subgrand.m afer importing and
% processing new subjects. It only works from GUI.
%
% Usage:
% wtRebuildSubjects();

function success = wtRebuildSubjects()
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkWaveletAnalysisDone(false)
        return
    end

    subjectsPrms = wtProject.Config.Subjects;
    subjectsGrandPrms =  wtProject.Config.SubjectsGrand;
    analysisSubjects = 'Subjects Analysis';
    grandAnalysisSubjects = 'Subjects Grand Analysis';
    optionsList = { analysisSubjects, grandAnalysisSubjects };

    selection = WTUtils.stringsSelectDlg('Select lists to rebuild:', optionsList, false, true, 'ListSize', [190, 120]);
    if isempty(selection)
        return
    end

    ioProc = wtProject.Config.IOProc;
    rebuildSubjects = any(strcmp(selection, analysisSubjects));
    rebuildSubjectsGrand = any(strcmp(selection, grandAnalysisSubjects));
    
    if rebuildSubjects
        allAnalysedSubjects = intersect(ioProc.getAnalysedSubjects(), subjectsPrms.ImportedSubjectsList);

        if isempty(allAnalysedSubjects)
            wtProject.notifyWrn([], 'No subjects have been analysed yet');
            return
        end

        subjects = WTUtils.stringsSelectDlg('Select analysed subjects:', allAnalysedSubjects, false, true);
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
                wtProject.notifyWrn([], 'The subjects list is empty, so you can''t select subjects for the grand analysis.');
            end
            select = false;
        elseif ~rebuildSubjectsGrand
            if isempty(subjectsGrandPrms.SubjectsList)
                wtProject.notifyWrn([], ['The grand average subjects list is empty, you must select some subjects or it will\n' ...
                    'be automatically set with all the subjects in the analysis list']);
                subjects = subjectsPrms.SubjectsList;
                select = true;
                update = true;
            else
                subjects = intersect(subjectsPrms.SubjectsList, subjectsGrandPrms.SubjectsList);
                if length(subjects) ~= length(subjectsGrandPrms.SubjectsList);
                    wtProject.notifyInf([], ['You have removed subjects from the analysis list subjects that were part of the grand analysis:\n' ...
                        'please review the subjects selection for the grand analysis or it will be updated automatically either by eliminatng\n' ...
                        'the missing subjects or, if that generates an empty list, with all the subjects in the analysis list.']);
                end
                select = true;
                update = true;
            end
        end

        if select
            newSubjects = WTUtils.stringsSelectDlg('Select subjects to\ninclude in the\ngrand analysis:', subjectsPrms.SubjectsList, false, true);
            update = update || ~isempty(newSubjects);
            subjects = WTUtils.ifThenElse(isempty(newSubjects), {subjects}, {newSubjects});
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
 