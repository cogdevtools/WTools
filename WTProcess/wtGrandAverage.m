% wtGrandAverage.m
% Created by Eugenio Parise
% CDC CEU 2010 - 2011
% Function to calculate the grand average matrix by condition from baseline
% corrected and chopped files (individual subjects files).
% This script is set to process the whole final sample of subjects of the study.
% Add 'evok' as argument to compute the grand average of evoked
% oscillations (of course, if they have been previously computed).
% 
% Usage:
% 
% wtGrandAverage(); to compute grand average of previously computed total-induced
% oscillations.
% wtGrandAverage('evok'); to compute grand average of previously computed evoked
% oscillations.

% Luca:
%   subjects & conditions are used only if the project is not interactive
%   subjects empty means: use all subjects
%   conditions empty means: use all conditions
function wtGrandAverage(subjects, conditions)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkIsOpen()
        return
    end

    interactive = wtProject.Interactive;
    subjectsGrandPrms = wtProject.Config.SubjectsGrand;
    waveletsTransformPrms = wtProject.Config.WaveletTransform;
    
    if ~subjectsGrandPrms.exist() || ~waveletsTransformPrms.exist()
        wtProject.notifyWrn([], 'Perform wavelet analysis before...');
        return
    end

    baselineChopPrms = wtProject.Config.BaselineChop;
    if ~baselineChopPrms.exist() 
        wtProject.notifyWrn([], 'Perform baseline correction & edges chopping before...');
    end 

    if length(subjectsGrandPrms.SubjectsList) < 2 
        wtProject.notifyWrn([], 'At least 2 subjects analysis is needed to perform the grand average...');
    end

    conditionsGrandPrms = wtProject.Config.ConditionsGrand;
    grandAveragePrms = wtProject.Config.GrandAverage;

    if ~interactive
        if nargin < 2 
            wtLog.excpt('MissingArg', 'Subjects and conditions lists must be provided when project is non-interactive');
        elseif ~WTValidations.isALinearCellArrayOfNonEmptyString(subjects)
            wtLog.excpt('BadArg', 'Bad argument type or value: subjects');
        elseif ~WTValidations.isALinearCellArrayOfNonEmptyString(conditions)
            wtLog.excpt('BadArg', 'Bad argument type or value: conditions');
        end
        if empty(subjects) 
            subjects = subjectsGrandPrms.SubjectsList;
        end
        if empty(conditions)
            conditions = cat(2, conditionsGrandPrms.ConditionsList, conditionsGrandPrms.ConditionsDiff);
        end
    else
        grandAveragePrms = copy(grandAveragePrms);
        [logFlag, ~, evokFlag] = wtCheckEvokLog();

        if ~WTGrandAverageGUI.grandAverageParams(grandAveragePrms, logFlag, evokFlag)
            return
        end

        if ~grandAveragePrms.persist() 
            wtProject.notifyErr([], 'Failed to save grand average params');
            return
        end

        wtProject.Config.GrandAverage = grandAveragePrms;
        subjects = subjectsGrandPrms.SubjectsList;

        if ~grandAveragePrms.UseAllSubjects 
            subjects = WTUtils.stringsSelectDlg('Select subjects\nto average:', subjects, false, false);
            if length(subjects) <= 1
                wtProject.notifyWrn([], 'No enough subjects selected');
                return
            end
        end

        conditions = cat(2, conditionsGrandPrms.ConditionsList, conditionsGrandPrms.ConditionsDiff);

        if length(conditions) > 1
            conditions = WTUtils.stringsSelectDlg('Select conditions:', conditions, false, false);
            if isempty(conditions)
                wtProject.notifyWrn([],'No enough conditions selected');
                return
            end
        end
    end 

    nSubjects = length(subjects);
    nConditions = length(conditions);

    measure = WTUtils.ifThenElseSet(grandAveragePrms.EvokedOscillations, ...
                WTIOProcessor.WaveletsAnalisys_evWT, ...
                WTIOProcessor.WaveletsAnalisys_avWT);

    wtLog.info('Computing grand average...');
    wtLog.pushStatus().ctxOn();

    for cnd = 1:nConditions
        for subj = 1:nSubjects
            [success, data] = ioProc.loadBaselineCorrection(subjects{sbj}, conditions{cnd}, measure);
            if ~success 
                wtProject.notifyErr([],'Failed to load dataset for subject ''%s'', condition: ''%s''', subjects{s}, conditions{cnd});
                wtLog.popStatus();
                return
            end         
            if subj == 1
                dataToSave = data;
                WT = dataToSave.WT;
            else
                WT = cat(4, WT, data.WT);
            end         
        end
        
        dataToSave.WT = mean(WT, 4);
        dataToSave.nepoch = nSubjects; % in accordance to ERPWAVELAB file structure

        [success, filePath] = ioProc.writeGrandAverage(subjects{sbj}, conditions{cnd}, measure, '-struct', 'dataToSave');
        if ~success
            wtProject.notifyErr([], 'Failed to save grand average data to ''%s''', filePath);
            wtLog.popStatus();
            return
        end

        if grandAveragePrms.PerSubjectAgerage
            dataToSave.SS = WT;

            [success, filePath] = ioProc.writeGrandAverage(subjects{sbj}, conditions{cnd}, measure, true, '-struct', 'dataToSave');
            if ~success
                wtProject.notifyErr([], 'Failed to save per subject average data to ''%s''', filePath);
                wtLog.popStatus();
                return
            end
            wtLog.info('Per subject average files for condition ''%s'' successfully saved', conditions{cnd});    
        end      
    end

    wtLog.popStatus();
    wtProject.notifyInf([], 'Computation of the grand average completed!');
end
