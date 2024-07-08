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

classdef WTConvertGUI
    
    methods (Static)
        function success = selectImportType(importTypePrms, basicPrms, lockToSrcSystem) 
            WTValidations.mustBe(importTypePrms, ?WTImportTypeCfg);
            WTValidations.mustBe(basicPrms, ?WTBasicCfg);

            lockToSrcSystem = nargin > 2 && lockToSrcSystem && ~isempty(basicPrms.SourceSystem);
            wtProject = WTProject();
            wtLog = WTLog();
            success = false;

            systems = { ...
                WTIOProcessor.SystemEEP, ...
                WTIOProcessor.SystemEGI, ...
                WTIOProcessor.SystemBRV, ...
                WTIOProcessor.SystemEEGLab }; 

            if lockToSrcSystem
                answer = num2cell(strcmp(systems, basicPrms.SourceSystem));
                enabled = cellfun(@(x)WTCodingUtils.ifThenElse(x, 'on', 'off'), answer, 'UniformOutput', false);
            else
                answer = { ...
                    importTypePrms.EEPFlag, ...
                    importTypePrms.EGIFlag, ...
                    importTypePrms.BRVFlag, ...
                    importTypePrms.EEGLabFlag }; 
                enabled = repmat({'on'}, 1, length(systems));
            end

            % EEP conversion is supported only on MS Windows platform
            if ~ispc 
                systems{1} = [systems{1} ' (available only on MS Windows)'];
                enabled{1} = 'off';
                answer{1,1} = 0;
            end

            if sum([answer{:}]) == 0 && lockToSrcSystem
                wtProject.notifyErr('', 'Import type is locked to ''%s'', which is not supported.', basicPrms.SourceSystem);
                return
            end

            if sum([answer{:}]) ~= 1
                answer = {0, 1, 0, 0};
            end

            rb = arrayfun(@(i)sprintf('RB%d',i), 1:length(systems), 'UniformOutput', false);
            cb = @(n)sprintf('for i=1:%d; set(findobj(gcbf, ''tag'', sprintf(''RB%%d'', i)), ''Value'', i==%d); end', length(rb), n);
            geometry = repmat({1}, 1, 2+length(systems));

           function params = setParameters(answer) 
                params = cell(1, 2+length(systems));
                params{1} = { 'style' 'text' 'string' 'Import segmented files from the following system:' };
                params{2} = { 'style' 'text' 'string' '' };
                for i = 1:length(systems) 
                    params{2+i} = { 'style' 'radiobutton' 'tag' rb{i} 'string' systems{i} 'value' answer{1,i} 'callback' cb(i), 'enable', enabled{i} };
                end
            end

            while true
                params = setParameters(answer);
                [answer, ~, strhalt] = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', params, 'title', 'Import segmented EEG');

                if ~strcmp(strhalt,'retuninginputui')
                    wtLog.dbg('User quitted import configuration dialog');
                    return;
                end

                % This is a double check, if for any reason the configuration file was changed manually
                if sum(cellfun(@(e) e, answer)) ~= 0
                    break
                end
                WTDialogUtils.wrnDlg('Review parameter', 'You must select one EEG system among %s', char(join(systems, ' ')));
            end

            importTypePrms.EEPFlag = answer{1,1};
            importTypePrms.EGIFlag = answer{1,2};
            importTypePrms.BRVFlag = answer{1,3};
            importTypePrms.EEGLabFlag = answer{1,4};
            success = true;
        end

        function success = defineSamplingRate(samplingPrms) 
            WTValidations.mustBe(samplingPrms, ?WTSamplingCfg);
            success = false;
            wtLog = WTLog();
            
            answer = {num2str(samplingPrms.SamplingRate)};

            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text' 'string' 'Sampling rate (Hz):' } ...
                    { 'style' 'edit' 'string' answer{1,1} } ...
                    { 'style' 'text' 'string' 'Enter the recording sampling rate' } };
            end

            geometry = { [1 0.5] 1 };
            
            while ~success
                params = setParameters(answer);
                [answer, ~, strhalt] = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', params, 'title', 'Set sampling rate');
                
                if ~strcmp(strhalt,'retuninginputui')
                    wtLog.dbg('User quitted sampling rate configuration dialog');
                    return
                end

                success = WTTryExec(@()set(samplingPrms, 'SamplingRate', WTNumUtils.str2double(answer{1,1}))).logWrn().displayWrn('Review parameter', 'Invalid SamplingRate').run().Succeeded;
            end
        end

        function success = defineTriggerLatency(egi2eeglPrms)
            WTValidations.mustBe(egi2eeglPrms, ?WTEGIToEEGLabCfg);
            success = false;
            wtLog = WTLog();
            
            answer = {num2str(egi2eeglPrms.TriggerLatency)};

            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text' 'string' 'Trigger latency (ms):' } ...
                    { 'style' 'edit' 'string' answer{1,1} } ...
                    { 'style' 'text' 'string' 'Enter a positive value to time lock to any' } ...
                    { 'style' 'text' 'string' 'point from the beginning of the segment.' } };
            end

            geometry = { [1 0.5] 1 1 };
            
            while ~success
                params = setParameters(answer);
                [answer, ~, strhalt] = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', params, 'title', 'Set trigger');

                if ~strcmp(strhalt,'retuninginputui')
                    wtLog.dbg('User quitted trigger latency configuration dialog');
                    return
                end

                success = WTTryExec(@()set(egi2eeglPrms, 'TriggerLatency', WTNumUtils.str2double(answer{1,1}))).logWrn().displayWrn('Review parameter', 'Invalid TriggerLatency').run().Succeeded;
            end
        end

        function success = defineTrialsRangeId(minMaxTrialIdPrms)
            WTValidations.mustBe(minMaxTrialIdPrms, ?WTMinMaxTrialIdCfg);
            success = false;
            wtLog = WTLog();
            
            minId = minMaxTrialIdPrms.MinTrialId;
            maxId = minMaxTrialIdPrms.MaxTrialId;

            if isnan(minId)  
                minId = '';
            end
            if isnan(maxId)
                maxId = '';
            end
            if ~ischar(minId)
                minId = num2str(minId);
            end
            if ~ischar(maxId)
                maxId = num2str(maxId);
            end

            answer = { minId  maxId };

            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text' 'string' 'Min Trial ID:' } ...
                    { 'style' 'edit' 'string' answer{1,1} } ...
                    { 'style' 'text' 'string' 'Max Trial ID:' } ...
                    { 'style' 'edit' 'string' answer{1,2} } ...
                    { 'style' 'text' 'string' 'Enter nothing to process all available trials.' } ...
                    { 'style' 'text' 'string' 'Enter only min or max to process trials above/below a trial ID.' } ...
                    { 'style' 'text' 'string' 'Enter min/max positive integers to set the min/max trial ID to' } ...
                    { 'style' 'text' 'string' 'process.' } };
            end

            geometry = { [1 0.5] [1 0.5] 1 1 1 1 };
            
            while ~success
                params = setParameters(answer);
                [answer, ~, strhalt] = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', params, 'title', 'Set min/Max trial ID');
                
                if ~strcmp(strhalt,'retuninginputui')
                    wtLog.dbg('User quitted set min/max trial ID configuration dialog');
                    return
                end

                success = all([ ...
                    WTTryExec(@()set(minMaxTrialIdPrms, 'MinTrialId', WTNumUtils.str2double(answer{1,1}, true))).logWrn().displayWrn('Review parameter', 'Invalid MinTrialId').run().Succeeded ... 
                    WTTryExec(@()set(minMaxTrialIdPrms, 'MaxTrialId', WTNumUtils.str2double(answer{1,2}, true))).logWrn().displayWrn('Review parameter', 'Invalid MaxTrialId').run().Succeeded ... 
                ]);

                success = success && WTTryExec(@()minMaxTrialIdPrms.validate(true)).logWrn().displayWrn('Review parameter', 'Validation failure').run().Succeeded; 
                
                if ~success
                    WTDialogUtils.wrnDlg('Review parameter',['Invalid min/max trials id. Allowed values for [min,max] are:\n\n- [<empty>, <empty>]\n' ...
                        '- [int >= 0, <empty>]\n- [<empty>, int >= 0 ]\n- [min >= 0, max >= min]']);
                end
            end
        end

        function success = defineEpochLimitsAndFreqFilter(epochsAndFreqFilterPrms)
            WTValidations.mustBe(epochsAndFreqFilterPrms, ?WTEpochsAndFreqFiltersCfg);
            success = false;
            wtLog = WTLog();

            answer = { ...
                { sprintf(WTConfigFormatter.FmtArrayStr, num2str(epochsAndFreqFilterPrms.EpochLimits)) }, ...
                { WTCodingUtils.ifThenElse(isnan(epochsAndFreqFilterPrms.HighPassFilter), [], double2str(epochsAndFreqFilterPrms.HighPassFilter)) } ...
                { WTCodingUtils.ifThenElse(isnan(epochsAndFreqFilterPrms.LowPassFilter), [], double2str(epochsAndFreqFilterPrms.LowPassFilter)) }};

            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text' 'string' 'Epochs limits' } ...
                    { 'style' 'edit' 'string' answer{1,1} } ...
                    { 'style' 'text' 'string' 'High-pass filter' } ...
                    { 'style' 'edit' 'string' answer{1,2} }...
                    { 'style' 'text' 'string' 'Low-pass filter' } ...
                    { 'style' 'edit' 'string' answer{1,3} }};
            end

            geometry = { [1 1] [1 1]  [1 1] };

            while ~success
                params = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', params,'title', 'Set epochs & band filter params');

                if isempty(answer)
                    wtLog.dbg('User quitted epochs range and frequency filter configuration dialog');
                    return 
                end

                success = all([ ...
                    WTTryExec(@()set(epochsAndFreqFilterPrms, 'EpochLimits', WTNumUtils.str2nums(answer{1,1}))).logWrn().displayWrn('Review parameter', 'Invalid EpochLimits').run().Succeeded ...
                    WTTryExec(@()set(epochsAndFreqFilterPrms, 'HighPassFilter', WTNumUtils.str2double(answer{1,2}))).logWrn().displayWrn('Review parameter', 'Invalid HighPassFilter').run().Succeeded ... 
                    WTTryExec(@()set(epochsAndFreqFilterPrms, 'LowPassFiler', WTNumUtils.str2double(answer{1,3}))).logWrn().displayWrn('Review parameter', 'Invalid LowPassFiler').run().Succeeded ... 
                ]);

                success = success && WTTryExec(@()epochsAndFreqFilterPrms.validate(true)).logWrn().displayWrn('Review parameter', 'Validation failure').run().Succeeded; 
            end
        end
    end
end

