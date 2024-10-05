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

function success = wtGrandAverage(subjects, conditions)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkChopAndBaselineCorrectionDone() || ...
        ~wtProject.checkRepeatedGrandAverage()
        return
    end

    interactive = wtProject.Interactive;
    basicPrms = wtProject.Config.Basic;
    subjectsGrandPrms = wtProject.Config.SubjectsGrand;

    if length(subjectsGrandPrms.SubjectsList) < 2 
        wtProject.notifyWrn([], ['To perform the grand average is meaningful when\n' ... 
            'there are at least 2 subjects. It''ll be performed\n'...
            'anyway, but consider importing new subjects data or\n'...
            'running the Subject Manager...']);
    end

    conditionsGrandPrms = wtProject.Config.ConditionsGrand;
    grandAveragePrms = wtProject.Config.GrandAverage;

    if ~interactive
        if nargin < 2 
            WTException.missinArg('Subjects and conditions lists must be provided when project is non-interactive').throw();
        elseif ~WTValidations.isLinearCellArrayOfNonEmptyChar(subjects)
            WTException.badArg('Bad argument type or value: subjects').throw();
        elseif ~WTValidations.isLinearCellArrayOfNonEmptyChar(conditions)
            WTException.badArg('Bad argument type or value: conditions').throw();
        end
        if empty(subjects) 
            subjects = subjectsGrandPrms.SubjectsList;
        end
        if empty(conditions)
            conditions = [conditionsGrandPrms.ConditionsList(:)' conditionsGrandPrms.ConditionsDiff(:)'];
        end
    else
        grandAveragePrms = copy(grandAveragePrms);
        waveletTransformPrms = wtProject.Config.WaveletTransform;
        baselineChopPrms =  wtProject.Config.BaselineChop;
        logFlag = grandAveragePrms.LogarithmicTransform;
        evokFlag = grandAveragePrms.EvokedOscillations;

        if waveletTransformPrms.exist()
            logFlag = waveletTransformPrms.LogarithmicTransform; 
            evokFlag = waveletTransformPrms.EvokedOscillations;
        end
        if baselineChopPrms.exist() 
            logFlag = baselineChopPrms.LogarithmicTransform; 
        end

        if ~WTGrandAverageGUI.defineGrandAverageParams(grandAveragePrms, logFlag, evokFlag)
            return
        end

        if ~grandAveragePrms.persist() 
            wtProject.notifyErr([], 'Failed to save grand average params');
            return
        end

        wtProject.Config.GrandAverage = grandAveragePrms;
        subjects = subjectsGrandPrms.SubjectsList;

        if ~grandAveragePrms.UseAllSubjects 
            subjects = WTDialogUtils.stringsSelectDlg('Select subjects\nto average:', subjects, false, false);
            if length(subjects) == 0
                wtLog.warn('No subjects selected');
                return
            end
            if length(subjects) <= 1
                wtProject.notifyWrn([], 'No enough subjects selected');
                return
            end
        end

        conditions = [conditionsGrandPrms.ConditionsList(:)' conditionsGrandPrms.ConditionsDiff(:)'];

        if length(conditions) > 1
            conditions = WTDialogUtils.stringsSelectDlg('Select conditions:', conditions, false, false);
            if isempty(conditions)
                wtProject.notifyWrn([],'No enough conditions selected');
                return
            end
        end
    end 

    ioProc = wtProject.Config.IOProc;
    nSubjects = length(subjects);
    nConditions = length(conditions);

    measure = WTCodingUtils.ifThenElse(grandAveragePrms.EvokedOscillations, ...
                WTIOProcessor.WaveletsAnalisys_evWT, ...
                WTIOProcessor.WaveletsAnalisys_avWT);

    wtLog.info('Computing the grand average...');
    wtLog.pushStatus().contextOn();

    for cnd = 1:nConditions
        for sbj = 1:nSubjects
            [success, data] = ioProc.loadBaselineCorrection(subjects{sbj}, conditions{cnd}, measure);
            if ~success 
                wtProject.notifyErr([],'Failed to load dataset for subject ''%s'', condition: ''%s''', subjects{sbj}, conditions{cnd});
                wtLog.popStatus();
                return
            end         
            if sbj == 1
                dataToSave = data;
                WT = dataToSave.WT;
            else
                WT = cat(4, WT, data.WT);
            end         
        end
        
        dataToSave.WT = mean(WT, 4);
        dataToSave.nEpochs = nSubjects; % in accordance to ERPWAVELAB file structure

        [success, filePath] = ioProc.writeGrandAverage(conditions{cnd}, measure, false, '-struct', 'dataToSave');
        if ~success
            wtProject.notifyErr([], 'Failed to save grand average data to ''%s''', filePath);
            wtLog.popStatus();
            return
        end

        if grandAveragePrms.PerSubjectAverage
            wtLog.info('Saving per subject average data: be patient, this may take quite a while...');
            dataToSave.SS = WT;

            [success, filePath] = ioProc.writeGrandAverage(conditions{cnd}, measure, true, '-struct', 'dataToSave');
            if ~success
                wtProject.notifyErr([], 'Failed to save grand average with per subject data to ''%s''', filePath);
                wtLog.popStatus();
                return
            end
            wtLog.info('Per subject average files for condition ''%s'' successfully saved', conditions{cnd});    
        end
    end

    wtLog.popStatus();
    basicPrms.GrandAverageDone = 1;

    if ~basicPrms.persist()
        wtProject.notifyErr([], 'Failed to save basic configuration params related to the processing status.');
        return
    end

    wtProject.notifyInf([], 'Computation of the grand average completed!');
    success = true;
end
