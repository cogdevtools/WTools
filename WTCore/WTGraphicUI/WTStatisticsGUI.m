classdef WTStatisticsGUI

    methods(Static)

        function [success, subjectsList, conditionsList] = defineStatisticsSettings(statsPrms, subjectsGrandPrms, conditionsGrandPrms) 
            success = false;
            subjectsList = {};
            conditionsList = {};
            WTValidations.mustBeA(statsPrms, ?WTStatisticsCfg);
            WTValidations.mustBeA(subjectsGrandPrms, ?WTSubjectsGrandCfg);
            WTValidations.mustBeA(conditionsGrandPrms, ?WTConditionsGrandCfg);
            wtLog = WTLog();

            subjects = subjectsGrandPrms.SubjectsList;
            if isempty(subjects)
                WTUtils.errDlg('Bad parameter', 'There project subjects list is empty!');
                return
            end

            conditions = conditionsGrandPrms.ConditionsList;
            if isempty(conditions)
                WTUtils.errDlg('Bad parameter', 'The project conditions list is empty!');
                return
            end

            answer = { ...
                num2str(statsPrms.TimeMin) ...
                num2str(statsPrms.TimeMax) ...
                num2str(statsPrms.FreqMin) ...
                num2str(statsPrms.FreqMax) ...
                statsPrms.IndividualFreqs ...
                statsPrms.EvokedOscillations ...
                [], ...
                [], ... 
            };

            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text'     'string' 'Time (ms): From     ' } ...
                    { 'style' 'edit'     'string' answer{1,1} } ...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,2} }...
                    { 'style' 'text'     'string' 'Frequency (Hz): From' } ...
                    { 'style' 'edit'     'string' answer{1,3} }...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,4} }.....
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'checkbox' 'string' 'Retrieve individual frequencies' 'value'  answer{1,5} } ...
                    { 'style' 'checkbox' 'string' 'Retrieve evoked oscillations' 'value'  answer{1,6} } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' 'Subjects (no selection = all)'   } ...
                    { 'style' 'text'     'string' 'Conditions (no selection = all)' } ...
                    { 'style' 'listbox'  'tag'  'subjs' 'string' subjects   'value' answer{1,7} 'min' 0 'max' length(subjects) }, ...
                    { 'style' 'listbox'  'tag'  'conds' 'string' conditions 'value' answer{1,8} 'min' 0 'max' length(conditions) }, ...
                };
            end

            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] 1 1 1 1 [0.5 0.5] [0.5 0.5] };
            geomvert = [ 1 1 1 1 1 1 1 min(max(length(subjects), length(conditions)), 10) ];

            while ~success
                parameters = setParameters(answer);
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'geomvert', geomvert, 'uilist', parameters, 'title', 'Set statistics parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    statsPrms.TimeMin = WTUtils.str2double(answer{1,1});
                    statsPrms.TimeMax = WTUtils.str2double(answer{1,2});
                    statsPrms.FreqMin = WTUtils.str2double(answer{1,3});
                    statsPrms.FreqMax = WTUtils.str2double(answer{1,4});
                    statsPrms.IndividualFreqs = answer{1,5};
                    statsPrms.EvokedOscillations = answer{1,6};
                    success = statsPrms.validate(); 
                    subjectsList = subjects(answer{1,7});
                    conditionsList = conditions(answer{1,8});
                catch me
                    wtLog.except(me);
                end
                 
                if ~success
                    WTUtils.wrnDlg('Review parameter', 'Invalid parameters: check the log for details');
                end
            end
        end

    end
end