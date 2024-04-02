% wtRebuildSubjects.m
% Created by Eugenio Parise
% CDC CEU 2012
% Function to rebuild subj.m and subgrand.m afer importing and
% processing new subjects. It only works from GUI.
%
% Usage:
% wtRebuildSubjects();

function wtRebuildSubjects()
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkWaveletAnalysisDone()
        return
    end

    subjectsPrms = wtProject.Config.Subjects;
    subjectsGrandPrms =  wtProject.Config.SubjectsGrand;
    importedSubjects = 'Subjects Analysis';
    includedSubjects = 'Subjects Grand Analysis';
    optionsList = { importedSubjects, includedSubjects };

    selection = WTUtils.stringsSelectDlg('Select lists to rebuild:', optionsList, false, true, 'ListSize', [190,120]);
    if isempty(selection)
        return
    end

    ioProc = wtProject.Config.IOProc;
    rebuildSubjects = any(strcmp(optionsList, importedSubjects));
    rebuildSubjectsGrand = any(strcmp(optionsList, includedSubjects));

    if rebuildSubjects
        subjects = ioProc.getAnalysedSubjects();
        if isempty(subjects)
            wtProject.notifyWrn([], 'No subjects have been analysed yet');
            return
        end
        subjects = WTUtils.stringsSelectDlg('Select analysed subjects:', subjectsPrms.SubjectsList, false, true);
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

    if rebuildSubjectsGrand
        if isempty(subjectsPrms.SubjectsList)
            wtProject.notifyWrn([], 'No subjects in the analysed subjects list');
            return
        end

        subjects = WTUtils.stringsSelectDlg('Select subjects to\ninclude in the\ngrand analysis:', subjectsPrms.SubjectsList, false, true);
        if isempty(subjects)
            return
        end

        subjectsGrandPrms = copy(subjectsGrandPrms);
        subjectsGrandPrms.SubjectsList = subjects;
        if ~subjectsGrandPrms.persist()
            wtProject.notifyErr([], 'Failed to save new grand analysis subjects list');
            return
        end
        wtLog.info('New grand analysis subjects list successfully saved');
        wtProject.Config.SubjectsGrand = subjectsGrandPrms; 
    end

    wtLog.info('Rebuild done.');
end
 