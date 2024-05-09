
classdef WTImportGUI
    
    methods(Static)
        function [subjects, subjFileNames] = selectImportedSubjects(system) 
            ioProc = WTProject().Config.IOProc;
            wtLog = WTLog();
            subjects = [];

            subjFileNames = ioProc.enumImportFiles(system);
            if isempty(subjFileNames) 
                WTEEGLabUtils.eeglabMsgDlg('Warning', 'No import files found');
                return
            end

            subjFileNames = WTDialogUtils.stringsSelectDlg('Select files/subjects', subjFileNames, false, true);
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
    end
end