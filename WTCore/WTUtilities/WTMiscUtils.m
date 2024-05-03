classdef WTMiscUtils

    methods(Static)
        % checkDiffAndGrandAvg() checks whether the data are up to date and ready for the grand average  
        function [diffConsistency, grandAvgConsistency] = checkDiffAndGrandAvg(conditions, chkGrandAvg)
            chkGrandAvg = nargin < 2 || chkGrandAvg;
            diffConsistency = 1;
            grandAvgConsistency = 1;
            
            wtProject = WTProject();
            conditionsGrandPrms = wtProject.Config.ConditionsGrand;
            logFlag = wtProject.Config.WaveletTransform.LogarithmicTransform || ...
                wtProject.Config.BaselineChop.Log10Enable;
           
            if any(ismember(conditions, conditionsGrandPrms.ConditionsDiff))
                differencePrms = wtProject.Config.Difference;
                if logical(differencePrms.LogDiff) ~= logFlag
                    wtProject.notifyWrn([], ['The [Difference] paramaters are not up to date.\n' ...
                        'Run [Difference] again before plotting.'])
                    diffConsistency = 0;
                end        
            end
        
            if chkGrandAvg
                grandAveragePrms = wtProject.Config.GrandAverage;
                if logical(grandAveragePrms.Log10Enable) ~= logFlag
                    wtProject.notifyWrn([], ['The [Grand Average] paramaters are not up to date.\n' ...
                        'Run [Grand Average] again before plotting.'])
                    grandAvgConsistency = 0;
                end
            end
        end

        % subject empty => load grand average
        function [success, data] = loadData(perSubject, subject, condition, measure) 
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
