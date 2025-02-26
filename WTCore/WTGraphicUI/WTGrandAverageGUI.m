
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

        function success = defineGrandAverageParams(grandAveragePrms, lockEvok, lockPower, lockBaselineCorrect, lockBaselineNorm)
            WTValidations.mustBe(grandAveragePrms, ?WTGrandAverageCfg);
            success = false;
            wtLog = WTLog();
            
            answer = { ...
                grandAveragePrms.UseAllSubjects, ...
                grandAveragePrms.PerSubjectAverage, ...
                grandAveragePrms.EvokedOscillations, ...
                grandAveragePrms.TransformPower, ...
                grandAveragePrms.BaselineSubtraction, ...
                grandAveragePrms.BaselineNormalization };

            enableEvok = WTCodingUtils.ifThenElse(lockEvok, 'off', 'on');
            enablePower = WTCodingUtils.ifThenElse(lockPower, 'off', 'on');
            enableBC = WTCodingUtils.ifThenElse(lockBaselineCorrect, 'off', 'on');
            enableBN = WTCodingUtils.ifThenElse(lockBaselineNorm, 'off', 'on');
           
            parameters = { ...
                { 'style' 'checkbox' 'string' 'Use all processed subjects'                      'value'   answer{1,1} } ...
                { 'style' 'checkbox' 'string' 'Compute per subject average (for std err plots)' 'value'   answer{1,2} } ...
                { 'style' 'checkbox' 'string' 'Evoked Oscillations'                             'value'   answer{1,3} 'enable' enableEvok } ...
                { 'style' 'checkbox' 'string' 'Transform Power'                                 'value'   answer{1,4} 'enable' enablePower } ...
                { 'style' 'checkbox' 'string' 'Baseline Subtraction'                             'value'   answer{1,5} 'enable' enableBC } ...
                { 'style' 'checkbox' 'string' 'Baseline Normalization'                          'value'   answer{1,6} 'enable' enableBN } };
            
            answer = WTEEGLabUtils.eeglabInputMask('geometry', { 1 1 1 1 1 1 }, 'uilist', parameters, 'title', 'Grand average');

            if isempty(answer) % ~strcmp(strhalt,'retuninginputui')
                wtLog.dbg('User quitted grand average configuration dialog');
                return
            end

            success = all([ ...
                WTTryExec(@()set(grandAveragePrms, 'UseAllSubjects', answer{1,1})).logWrn().displayWrn('Review parameter', 'Invalid UseAllSubjects').run().Succeeded ...
                WTTryExec(@()set(grandAveragePrms, 'PerSubjectAverage', answer{1,2})).logWrn().displayWrn('Review parameter', 'Invalid PerSubjectAverage').run().Succeeded ... 
                WTTryExec(@()set(grandAveragePrms, 'EvokedOscillations', answer{1,3})).logWrn().displayWrn('Review parameter', 'Invalid EvokedOscillations').run().Succeeded ...
                WTTryExec(@()set(grandAveragePrms, 'TransformPower', answer{1,4})).logWrn().displayWrn('Review parameter', 'Invalid TransformPower').run().Succeeded ... 
                WTTryExec(@()set(grandAveragePrms, 'BaselineSubtraction', answer{1,5})).logWrn().displayWrn('Review parameter', 'Invalid BaselineSubtraction').run().Succeeded ... 
                WTTryExec(@()set(grandAveragePrms, 'BaselineNormalization', answer{1,6})).logWrn().displayWrn('Review parameter', 'Invalid BaselineNormalization').run().Succeeded ...
            ]);
        end
    end
end