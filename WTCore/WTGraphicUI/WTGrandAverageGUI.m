
classdef WTGrandAverageGUI
    
    methods(Static)

        function success = defineGrandAverageParams(grandAveragePrms, logFlag, evokFlag)
            WTValidations.mustBeA(grandAveragePrms, ?WTGrandAverageCfg);
            success = false;
            wtLog = WTLog();
            
            useAllSubjects = grandAveragePrms.UseAllSubjects;
            perSbjAvg = grandAveragePrms.PerSubjectAverage;

            logFlag = WTCodingUtils.ifThenElse(logFlag, 1, 0);
            evokFlag = WTCodingUtils.ifThenElse(evokFlag, 1, 0);
            enableLog = 'off';
            enableEvok = 'off';

            parameters = { ...
                { 'style' 'checkbox' 'string' 'Use all processed subjects'                      'value'   useAllSubjects } ...
                { 'style' 'checkbox' 'string' 'Compute per subject average (for std err plots)' 'value'   perSbjAvg } ...
                { 'style' 'checkbox' 'string' 'Log10-Transformed data'                          'value'   logFlag 'enable' enableLog } ...
                { 'style' 'checkbox' 'string' 'Evoked Oscillations'                             'value'   evokFlag 'enable' enableEvok } };
            
            [answer, ~, strhalt] = WTEEGLabUtils.eeglabInputMask('geometry', { 1 1 1 1 }, 'uilist', parameters, 'title', 'Grand average');

            if ~strcmp(strhalt,'retuninginputui')
                wtLog.dbg('User quitted grand average configuration dialog');
                return;
            end

            grandAveragePrms.UseAllSubjects = answer{1};
            grandAveragePrms.PerSubjectAverage = answer{2};
            grandAveragePrms.LogarithmicTransform = answer{3};
            grandAveragePrms.EvokedOscillations = answer{4};
            success = true;
        end
    end
end