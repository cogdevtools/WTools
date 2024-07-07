
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

classdef WTGrandAverageGUI
    
    methods(Static)

        function success = defineGrandAverageParams(grandAveragePrms, logFlag, evokFlag)
            WTValidations.mustBe(grandAveragePrms, ?WTGrandAverageCfg);
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
                return
            end

            success = all([ ...
                WTTryExec(@()set(grandAveragePrms, 'UseAllSubjects', answer{1,1})).logWrn().displayWrn('Review parameter', 'Invalid UseAllSubjects').run().Succeeded ...
                WTTryExec(@()set(grandAveragePrms, 'PerSubjectAverage', answer{1,2})).logWrn().displayWrn('Review parameter', 'Invalid PerSubjectAverage').run().Succeeded ... 
                WTTryExec(@()set(grandAveragePrms, 'LogarithmicTransform', answer{1,3})).logWrn().displayWrn('Review parameter', 'Invalid LogarithmicTransform').run().Succeeded ... 
                WTTryExec(@()set(grandAveragePrms, 'EvokedOscillations', answer{1,4})).logWrn().displayWrn('Review parameter', 'Invalid EvokedOscillations').run().Succeeded ...
            ]);
        end
    end
end