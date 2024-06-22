classdef WTProcessUtils

    methods(Static)
        function success = sanitizeSubjectsLists()
            success = false;
            wtProject = WTProject();
            wtLog = WTLog().contextOn('SubjectsListSanitation');
            ioProc = wtProject.Config.IOProc;
            sbjsPrms = copy(wtProject.Config.Subjects);
            sbjsGrdPrms = copy(wtProject.Config.SubjectsGrand);

            sbjsImp = sbjsPrms.ImportedSubjectsList;
            sbjsSel = sbjsPrms.SubjectsList;
            sbjsGrd = sbjsGrdPrms.SubjectsList;
            updSbjs = false;
            updSbjsGrd = false;

            sbjsAll = ioProc.getAnalysedSubjects();
            sbjsImpNew = intersect(sbjsImp, sbjsAll);

            if length(sbjsImpNew) ~= length(sbjsImp)
                wtLog.info('Imported subjects list will be sanitized. Pruned subjects: [%s]', ...
                    char(join(setdiff(sbjsImp, sbjsAll), ',')));
                sbjsPrms.ImportedSubjectsList = sbjsImpNew;
                updSbjs = true;
            end
    
            sbjsSelNew = intersect(sbjsSel, sbjsImpNew);
            sbjsGrdNew = intersect(sbjsGrd, sbjsSelNew);

            if length(intersect(sbjsSel, sbjsSelNew)) ~= length(sbjsSel)
                wtLog.info('Subjects list will be sanitized. Pruned subjects: [%s]', ...
                    char(join(setdiff(sbjsSel, sbjsSelNew), ',')));
                sbjsPrms.SubjectsList = sbjsSelNew;
                updSbjs = true;
            end
            if length(intersect(sbjsGrd, sbjsGrdNew)) ~= length(sbjsGrd)
                wtLog.info('Subjects grand list will be sanitized. Pruned subjects: [%s]', ...
                    char(join(setdiff(sbjsGrd, sbjsGrdNew), ',')));
                sbjsGrdPrms.SubjectsList = sbjsGrdNew;
                updSbjsGrd = true;
            end

            success = true;

            if updSbjs
                if  ~sbjsPrms.persist()
                    wtLog.err('Failed to save sanitized subjects lists');
                    success = false;
                else
                    wtProject.Config.Subjects = sbjsPrms;
                    updSbjsGrd = false;
                end
            end

            if updSbjsGrd 
                if ~sbjsGrdPrms.persist()
                    wtLog.err('Failed to save sanitized subjects grand list');
                    success = false;
                else
                    wtProject.Config.SubjectsGrand = sbjsGrdPrms;
                end
            end

            wtLog.contextOff();
        end

        % checkDiffAndGrandAvg() checks whether the data are up to date and ready for the grand average  
        function [diffConsistency, grandAvgConsistency] = checkDiffAndGrandAvg(conditions, chkGrandAvg)
            chkGrandAvg = nargin < 2 || chkGrandAvg;
            diffConsistency = 1;
            grandAvgConsistency = 1;
            
            wtProject = WTProject();
            conditionsGrandPrms = wtProject.Config.ConditionsGrand;
            logFlag = wtProject.Config.WaveletTransform.LogarithmicTransform || ...
                wtProject.Config.BaselineChop.LogarithmicTransform;
           
            if any(ismember(conditions, conditionsGrandPrms.ConditionsDiff))
                differencePrms = wtProject.Config.Difference;
                if logical(differencePrms.LogarithmicTransform) ~= logFlag
                    wtProject.notifyWrn([], ['The [Difference] paramaters are not up to date.\n' ...
                        'Run [Difference] again before plotting.'])
                    diffConsistency = 0;
                end        
            end
        
            if chkGrandAvg
                grandAveragePrms = wtProject.Config.GrandAverage;
                if logical(grandAveragePrms.LogarithmicTransform) ~= logFlag
                    wtProject.notifyWrn([], ['The [Grand Average] paramaters are not up to date.\n' ...
                        'Run [Grand Average] again before plotting.'])
                    grandAvgConsistency = 0;
                end
            end
        end

        % subject empty => load grand average
        function [success, data] = loadAnalyzedData(perSubject, subject, condition, measure) 
            wtProject = WTProject();
            ioProc = wtProject.Config.IOProc;
            grandAverage = isempty(subject);
        
            if grandAverage
                [success, data] = ioProc.loadGrandAverage(condition, measure, perSubject);
            else
                [success, data] = ioProc.loadBaselineCorrection(subject, condition, measure);
            end
            if ~success 
                wtProject.notifyErr([], 'Failed to load data for condition ''%s''', condition);
            end
        end
    end
end
