function [success, sbjFileNames] = wtSelectUpdateSubjects(system) 
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    subjectsParams = wtProject.Config.Subjects;
    sbjFileNames = {};

    if subjectsParams.exist()
        if ~WTUtils.eeglabYesNoDlg('Re-import subjects?', ['The subject configuration file already exists!\n' ...
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
    subjectsParams.FilesList = sbjFileNames;

    if ~subjectsParams.persist()
        wtProject.notifyErr([], 'Failed to save subjects to import params');
        return
    end

    wtProject.Config.Subjects = subjectsParams;
    success = true;
end