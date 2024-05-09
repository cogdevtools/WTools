
classdef WTGrandAverageGUI
    
    methods(Static)

        function success = defineGrandAverageParams(wtGrandAveragePrms, logFlag, evokFlag)
            WTValidations.mustBeA(wtGrandAveragePrms, ?WTGrandAverageCfg);
            success = false;
            wtLog = WTLog();
            
            useAllSubjects = wtGrandAveragePrms.UseAllSubjects;
            perSbjAvg = wtGrandAveragePrms.PerSubjectAgerage;

            parameters = { ...
                { 'style' 'checkbox' 'string' 'Use all processed subjects'                      'value'   useAllSubjects } ...
                { 'style' 'checkbox' 'string' 'Compute per subject average (for std err plots)' 'value'   perSbjAvg } ...
                { 'style' 'checkbox' 'string' 'Log10-Transformed data'                          'value'   logFlag 'enable' 'off' } ...
                { 'style' 'checkbox' 'string' 'Evoked Oscillations'                             'value'   evokFlag } };
            
            [answer, ~, strhalt] = WTEEGLabUtils.eeglabInputMask('geometry', { 1 1 1 1 }, 'uilist', parameters, 'title', 'Grand average');

            if ~strcmp(strhalt,'retuninginputui')
                wtLog.dbg('User quitted grand average configuration dialog');
                return;
            end

            wtGrandAveragePrms.UseAllSubjects = answer{1};
            wtGrandAveragePrms.PerSubjectAgerage = answer{2};
            wtGrandAveragePrms.Log10Enable = answer{3};
            wtGrandAveragePrms.EvokedOscillations = answer{4};
            success = true;
        end
    end
end