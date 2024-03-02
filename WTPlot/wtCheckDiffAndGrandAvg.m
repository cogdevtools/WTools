% wtCheckDiffAndGrandAvg.m
% Created by Eugenio Parise
% CDC CEU 2012
% Function that controls whether data are up to date and ready for grandaverage (i.e. n>1) 

function [diffConsistency, grandAvgConsistency] = wtCheckDiffAndGrandAvg(fileNames, chkGrandAvg)
    chkGrandAvg = nargin < 2 || any(logical(chkGrandAvg));
    diffConsistency = 1;
    grandAvgConsistency = 1;
    
    wtProject = WTProject();
    conditionsGrandPrms = wtProject.Config.ConditionsGrand;
    logFlag = logical(wtCheckEvokLog());
   
    if any(ismember(fileNames, conditionsGrandPrms.ConditionsDiff))
        differencePrms = wtProject.Config.Difference;
        if logical(differencePrms.LogDiff) ~= logFlag
            wtProject.notifyWrn([], ['The difference files are not up to date.\n' ...
                'Run Difference again before plotting.'])
            diffConsistency = 0;
        end        
    end

    if chkGrandAvg
        grandAveragePrms = wtProject.Config.GrandAverage;
        if logical(grandAveragePrms.Log10Enable) ~= logFlag
            wtProject.notifyWrn([], ['The grand average files are not up to date.\n' ...
                'Run Grand Average again before plotting.'])
            grandAvgConsistency = 0;
        end
    end
end