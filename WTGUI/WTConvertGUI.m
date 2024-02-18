classdef WTConvertGUI
    
    methods (Static)
        function success = selectImportType(convertToEEGLabData) 
            WTValidations.mustBeA(convertToEEGLabData, ?WTImportTypeCfg);
            wtLog = WTLog();
            success = false;

            answer = { ...
                convertToEEGLabData.EEPFlag, ...
                convertToEEGLabData.EGIFlag, ...
                convertToEEGLabData.BRVFlag, ...
                convertToEEGLabData.EEGLabFlag }; 

            systems = { ...
                WTIOProcessor.SystemEEP, ...
                WTIOProcessor.SystemEGI, ...
                WTIOProcessor.SystemBRV, ...
                WTIOProcessor.SystemEEGLab }; 

            enabled = repmat({'on'}, 1, length(systems));

            % EEP conversion is supported only on MS Windows platform
            if ~ispc 
                systems{1} = [systems{1} ' (available only on MS Windows)'];
                enabled{1} = 'off';
                answer{1,1} = 0;
            end

            if sum([answer{:}]) ~= 1
                answer = {0, 1, 0, 0};
            end

            rb = arrayfun(@(i)sprintf('RB%d',i), 1:length(systems), 'UniformOutput', false);
            cb = @(n)sprintf('for i=1:%d; set(findobj(gcbf, ''tag'', sprintf(''RB%%d'', i)), ''Value'', i==%d); end', length(rb), n);
            geometry = repmat({1}, 1, 2+length(systems));
            params = cell(1, 2+length(systems));
            params{1} = { 'style' 'text' 'string' 'Import segmented files from the following system:' };
            params{2} = { 'style' 'text' 'string' '' };
            for i = 1:length(systems) 
                params{2+i} = { 'style' 'radiobutton' 'tag' rb{i} 'string' systems{i} 'value' answer{1,i} 'callback' cb(i), 'enable', enabled{i} };
            end
            
            while true
                [answer, ~, strhalt] = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', params, 'title', 'Import segmented EEG');

                if ~strcmp(strhalt,'retuninginputui')
                    wtLog.dbg('User quitted import configuration dialog');
                    return;
                end

                % This is a double check, if for any reason the configuration file was changed manually
                if sum(cellfun(@(e) e, answer)) ~= 0
                    break
                end
                WTUtils.wrnDlg('Review parameter', 'You must select one EEG system among %s', char(join(systems, ' ')));
            end

            convertToEEGLabData.EEPFlag = answer{1,1};
            convertToEEGLabData.EGIFlag = answer{1,2};
            convertToEEGLabData.BRVFlag = answer{1,3};
            convertToEEGLabData.EEGLabFlag = answer{1,4};
            success = true;
        end

        function success = defineSamplingRate(samplingData) 
            WTValidations.mustBeA(samplingData, ?WTSamplingCfg);
            success = false;
            wtLog = WTLog();
            
            answer = {num2str(samplingData.SamplingRate)};
            params = { ...
                { 'style' 'text' 'string' 'Sampling rate (Hz):' } ...
                { 'style' 'edit' 'string' answer{1,1} } ...
                { 'style' 'text' 'string' 'Enter the recording sampling rate' } };
            geometry = { [1 0.5] 1 };
            
            while true
                [answer, ~, strhalt] = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', params, 'title', 'Set sampling rate');
                if ~strcmp(strhalt,'retuninginputui')
                    wtLog.dbg('User quitted set sampling rate configuration dialog');
                    return
                end
                try
                    samplingData.SamplingRate = WTUtils.str2double(answer{1,1});
                    break
                catch
                    WTUtils.wrnDlg('Review parameter','Invalid sampling rate:  must be a float > 0');
                end
            end
            success = true;
        end

        function success = defineTriggerLatency(egi2eeglData)
            WTValidations.mustBeA(egi2eeglData, ?WTEGIToEEGLabCfg);
            success = false;
            wtLog = WTLog();
            
            answer = {num2str(egi2eeglData.TriggerLatency)};
            params = { ...
                { 'style' 'text' 'string' 'Trigger latency (ms):' } ...
                { 'style' 'edit' 'string' answer{1,1} } ...
                { 'style' 'text' 'string' 'Enter nothing to time lock to the onset of the stimulus,' } ...
                { 'style' 'text' 'string' 'enter a positive value to time lock to any point from' } ...
                { 'style' 'text' 'string' 'the beginning of the segment.' } };
            geometry = { [1 0.5] 1 1 1 };
            
            while true
                [answer, ~, strhalt] = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', params, 'title', 'Set trigger');
                if ~strcmp(strhalt,'retuninginputui')
                    wtLog.dbg('User quitted set trigger latency configuration dialog');
                    return
                end
                try
                    egi2eeglData.TriggerLatency = WTUtils.str2double(answer{1,1});
                    break
                catch
                    WTUtils.wrnDlg('Review parameter', 'Invalid trigger latency: must be a float >= 0');
                end
            end
            success = true;
        end

        function success = defineTrialsRangeId(minMaxTrialIdData)
            WTValidations.mustBeA(minMaxTrialIdData, ?WTMinMaxTrialIdCfg);
            success = false;
            wtLog = WTLog();
            
            minId = minMaxTrialIdData.MinTrialId;
            maxId = minMaxTrialIdData.MaxTrialId;

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

            params = { ...
                { 'style' 'text' 'string' 'Min Trial ID:' } ...
                { 'style' 'edit' 'string' answer{1,1} } ...
                { 'style' 'text' 'string' 'Max Trial ID:' } ...
                { 'style' 'edit' 'string' answer{1,2} } ...
                { 'style' 'text' 'string' 'Enter nothing to process all available trials.' } ...
                { 'style' 'text' 'string' 'Enter only min or max to process trials above/below a trial ID.' } ...
                { 'style' 'text' 'string' 'Enter min/max positive integers to set the min/max trial ID to' } ...
                { 'style' 'text' 'string' 'process.' } };

            geometry = { [1 0.5] [1 0.5] 1 1 1 1 };
            
            while true
                [answer, ~, strhalt] = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', params, 'title', 'Set min/Max trial ID');
                if ~strcmp(strhalt,'retuninginputui')
                    wtLog.dbg('User quitted set min/max trial ID configuration dialog');
                    return
                end
                try
                    minId = WTUtils.str2double(answer{1,1}, true);
                    maxId = WTUtils.str2double(answer{1,2}, true);
                    minMaxTrialIdData.MinTrialId = minId;
                    minMaxTrialIdData.MaxTrialId = maxId;
                    minMaxTrialIdData.validate(true);
                catch
                    WTUtils.wrnDlg('Review parameter',['Invalid min/max trials id. Allowed values for [min,max] are: [<empty>,<empty>], ' ...
                        '[int >= 0, <empty>], [<empty>, int >= 0 ], [min >= 0, max >= min]']);
                    continue
                end
                break
            end
            success = true;
        end

        function success = defineEpochLimitsAndFreqFilter(EpochLimitsAndFreqFilterData)
            WTValidations.mustBeA(EpochLimitsAndFreqFilterData, ?WTEpochLimitsAndFreqFilterCfg);
            success = false;
            wtLog = WTLog();

            answer = { ...
                { sprintf(WTFormatter.FmtArrayStr, num2str(EpochLimitsAndFreqFilterData.EpochLimits)) }, ...
                { fastif(isnan(EpochLimitsAndFreqFilterData.HighPassFilter), [], double2str(EpochLimitsAndFreqFilterData.HighPassFilter)) } ...
                { fastif(isnan(EpochLimitsAndFreqFilterData.LowPassFilter), [], double2str(EpochLimitsAndFreqFilterData.LowPassFilter)) }};

            params = { ...
                { 'style' 'text' 'string' 'Epochs limits' } ...
                { 'style' 'edit' 'string' answer{1,1} } ...
                { 'style' 'text' 'string' 'High-pass filter' } ...
                { 'style' 'edit' 'string' answer{1,2} }...
                { 'style' 'text' 'string' 'Low-pass filter' } ...
                { 'style' 'edit' 'string' answer{1,3} }};

            geometry = { [1 1] [1 1]  [1 1] };

            while true
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', params,'title', 'Set epochs & band filter params');

                if isempty(answer)
                    wtLog.dbg('User quitted set epochs range and frequency filter configuration dialog');
                    return 
                end

                try
                    EpochLimitsAndFreqFilterData.EpochLimits = WTUtils.str2nums(answer{1,1});
                    EpochLimitsAndFreqFilterData.HighPassFilter = WTUtils.str2double(answer{1,2}, true);
                    EpochLimitsAndFreqFilterData.LowPassFiler = WTUtils.str2double(answer{1,2}, true);
                    EpochLimitsAndFreqFilterData.validate(true)
                catch me
                    wtLog.except(me);
                    WTUtils.wrnDlg('Review parameter','Invalid epochs range and/or filter frequencies: check the log for details');
                    continue
                end
                break
            end

            success = true;
        end
    end
end

