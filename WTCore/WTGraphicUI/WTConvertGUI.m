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
            
            minId = num2str(minMaxTrialIdPrms.MinTrialId);
            maxId = minMaxTrialIdPrms.MaxTrialIdStr();
            answer = { minId  maxId };

            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text' 'string' 'Min Trial ID:' } ...
                    { 'style' 'edit' 'string' answer{1,1} } ...
                    { 'style' 'text' 'string' 'Max Trial ID:' } ...
                    { 'style' 'edit' 'string' answer{1,2} } ...
                    { 'style' 'text' 'string' 'If you don''t know the total #trials' } ...
                    { 'style' 'text' 'string' 'use Inf as value for the max id.' } };
            end

            geometry = { [1 0.5] [1 0.5] 1 1};
            
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

                if ~success
                    continue
                end

                success = WTTryExec(@()minMaxTrialIdPrms.validate(true)).logWrn().displayWrn('Review parameter', 'Validation failure').run().Succeeded; 
                
                if ~success
                    WTDialogUtils.wrnDlg('Review parameter',['Invalid min/max trials id. Allowed values: [min >= 1, max >= min]']);
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

        function success = displayImportSettings(system)
            success = false;
            wtProject = WTProject();
            wtLog = WTLog();

            sampling = wtProject.Config.Sampling;
            conditions = wtProject.Config.Conditions;
            channels = wtProject.Config.Channels;

            parameters = { ...
                { 'style' 'text' 'string' 'Sampling rate (Hz)' } ...
                { 'style' 'edit' 'string' num2str(sampling.SamplingRate) 'enable' 'off'} ...
                { 'style' 'text' 'string' 'Conditions' } ...
                { 'Style' 'listbox' 'string' conditions.ConditionsList 'value' 1 'enable' 'on'}, ...
                { 'style' 'text' 'string' 'Channels locations' } ...
                { 'style' 'edit' 'string' channels.ChannelsLocationFile 'enable' 'off'} ...
            };

            geometry = { [1 1] [1 1] [1 1] };
            geomvert = [1 2 1];
            
            parameters(end+1) = {{ 'style' 'text' 'string' 'Channels re-referencing' }}; 

            switch channels.ReReference
                case WTChannelsCfg.ReReferenceNone
                    parameters(end+1) = {{ 'style' 'edit' 'string' 'NONE' 'enable' 'off'}};
                    geometry(end+1) = {[1 1]};
                    geomvert(end+1) = 1;
                case WTChannelsCfg.ReReferenceWithAverage
                    parameters(end+1) = {{ 'style' 'edit' 'string' 'AVERAGE' 'enable' 'off'}};
                    geometry(end+1) = {[1 1]};
                    geomvert(end+1) = 1;
                case WTChannelsCfg.ReReferenceWithChannels
                    parameters(end+1) = {{ 'Style' 'listbox' 'string' channels.NewChannelsReference 'value' 1 'enable' 'off'}};
                    geometry(end+1) = {[1 1]};
                    geomvert(end+1) = 2;
                otherwise
                    wtProject.notifyErr([], 'Undefined channels re-referencing');
                    return
            end

            parameters(end+1) = {{ 'style' 'text' 'string' 'Channels to cut' }}; 
            parameters(end+1) = {{ 'Style' 'listbox' 'string' channels.CutChannels 'value' 1 'enable' 'on'}};
            geometry(end+1) = {[1 1]};
            geomvert(end+1) = 2;

            switch system
                case WTIOProcessor.SystemEEP
                    fromEEP = wtProject.Config.EEPToEEGLab;
                    parameters(end+1) = {{ 'style' 'text' 'string' 'Epoch limits' }}; 
                    parameters(end+1) = {{ 'style' 'edit' 'string' num2str(fromEEP.EpochLimits) 'enable' 'off'}};
                    parameters(end+1) = {{ 'style' 'text' 'string' 'Low pass filter (Hz)' }}; 
                    parameters(end+1) = {{ 'style' 'edit' 'string' num2str(fromEEP.LowPassFilter) 'enable' 'off'}};
                    parameters(end+1) = {{ 'style' 'text' 'string' 'High pass filter (Hz)' }}; 
                    parameters(end+1) = {{ 'style' 'edit' 'string' num2str(fromEEP.HighPassFilter) 'enable' 'off'}};
                    geometry(end+1:end+3) = {[1 1] [1 1] [1 1]};
                    geomvert(end+1:end+3) = [1 1 1];
                case WTIOProcessor.SystemBRV
                    fromBRV = wtProject.Config.BRVToEEGLab;
                    parameters(end+1) = {{ 'style' 'text' 'string' 'Epoch limits' }}; 
                    parameters(end+1) = {{ 'style' 'edit' 'string' num2str(fromBRV.EpochLimits) 'enable' 'off'}};
                    parameters(end+1) = {{ 'style' 'text' 'string' 'Low pass filter (Hz)' }}; 
                    parameters(end+1) = {{ 'style' 'edit' 'string' num2str(fromBRV.LowPassFilter) 'enable' 'off'}};
                    parameters(end+1) = {{ 'style' 'text' 'string' 'High pass filter (Hz)' }}; 
                    parameters(end+1) = {{ 'style' 'edit' 'string' num2str(fromBRV.HighPassFilter) 'enable' 'off'}};
                    geometry(end+1:end+3) = {[1 1] [1 1] [1 1]};
                    geomvert(end+1:end+3) = [1 1 1];
                case WTIOProcessor.SystemEGI
                    fromEGI = wtProject.Config.EGIToEEGLab;
                    minMaxTrialsPrms = wtProject.Config.MinMaxTrialId;
                    parameters(end+1) = {{ 'style' 'text' 'string' 'Trigger latency (ms)' }}; 
                    parameters(end+1) = {{ 'style' 'edit' 'string' num2str(fromEGI.TriggerLatency) 'enable' 'off'}};
                    parameters(end+1) = {{ 'style' 'text' 'string' 'Minimum trial id' }}; 
                    parameters(end+1) = {{ 'style' 'edit' 'string' num2str(minMaxTrialsPrms.MinTrialId) 'enable' 'off'}};
                    parameters(end+1) = {{ 'style' 'text' 'string' 'Maximum trial id' }}; 
                    parameters(end+1) = {{ 'style' 'edit' 'string' minMaxTrialsPrms.MaxTrialIdStr() 'enable' 'off'}};
                    geometry(end+1:end+3) = {[1 1] [1 1] [1 1]};
                    geomvert(end+1:end+3) = [1 1 1];
                case WTIOProcessor.SystemEEGLab
                    % Nothing to do...
                otherwise
                    wtProject.notifyErr([], 'Unknown source system: ''%s''', system);
                    return
            end
            
            answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'geomvert', geomvert, 'uilist', parameters, 'title', 'Confirm Import paramaters');

            if isempty(answer)
                wtLog.dbg('User quitted import settings confirmation dialog');
                return
            end

            success = true;
        end

        function success = displayChannelsLayoutFromFile(fileName) 
            success = false;
            figures = {};
            try
                windowTitle = sprintf('Check channels layout: %s', WTIOUtils.getPathTail(fileName));
                figures = { figure( 'NumberTitle', 'off', 'Name', windowTitle) }; 
                WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'topoplot', ...
                    [], fileName, 'style', 'blank', 'drawaxis', 'on', 'electrodes', 'labels', 'plotrad', 0.5);
                success = true;
            catch me
                WTLog().except(me);
            end
            WTPlotUtils.waitUIs(figures);
        end

        function success = displayChannelsLayoutFromData(source, chanLocs, chanInfo) 
            success = false;
            figures = {};
            try
                windowTitle = 'Source: <Undefined>';
                if ~isempty(source)
                    windowTitle =  sprintf('Source: %s', source);
                end
                figures = { figure( 'NumberTitle', 'off', 'Name', windowTitle) };
                if isempty(chanInfo) 
                    WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'topoplot', ...
                        [], chanLocs, 'style', 'blank', 'drawaxis', 'on', 'electrodes', ...
                        'ptslabels', 'plotrad', 1);
                else
                    WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'topoplot', ...
                        [], chanLocs, 'style', 'blank', 'drawaxis', 'on', 'electrodes', ...
                        'ptslabels', 'plotrad', 1, 'chaninfo', chanInfo);
                end
                success = true;
            catch me
                WTLog().except(me);
            end
            WTPlotUtils.waitUIs(figures);
        end
    end
end

