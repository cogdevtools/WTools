classdef WTConvertGUI
    
    methods (Static)
        function success = sourceDataFormatSelect(convertToEEGLabData) 
            WTUtils.mustBeA(convertToEEGLabData, ?WTConvertToEEGLabCfg)
            success = false;
            wtLog = WTLog();
            
            answer = { convertToEEGLabData.EEPFlag, ...
                convertToEEGLabData.EGIFlag, ...
                convertToEEGLabData.BRVFlag, ...
                convertToEEGLabData.EEGLabFlag }; 

            cbRadioButton1 = [ ...
                'get(gcbf, ''userdata'');' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton1''), ''Value'', 1);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton2''), ''Value'', 0);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton3''), ''Value'', 0);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton4''), ''Value'', 0);' ];

            cbRadioButton2 = [ ...
                'get(gcbf, ''userdata'');' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton1''), ''Value'', 0);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton2''), ''Value'', 1);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton3''), ''Value'', 0);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton4''), ''Value'', 0);' ];

            cbRadioButton3 = [ ...
                'get(gcbf, ''userdata'');' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton1''), ''Value'', 0);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton2''), ''Value'', 0);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton3''), ''Value'', 1);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton4''), ''Value'', 0);' ];

            cbRadioButton4 = [ ...
                'get(gcbf, ''userdata'');' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton1''), ''Value'', 0);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton2''), ''Value'', 0);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton3''), ''Value'', 0);' ...
                'set(findobj(gcbf, ''tag'', ''radiobutton4''), ''Value'', 1);' ];

            params = { ...
                { 'style' 'text'        'string' 'Import segmented files from the following system:' } ...
                { 'style' 'text'        'string' '' } ...
                { 'style' 'radiobutton' 'tag'    'radiobutton1' 'string' 'EEP'    'value'  answer{1,1} 'callback' cbRadioButton1 } ...
                { 'style' 'radiobutton' 'tag'    'radiobutton2' 'string' 'EGI'    'value'  answer{1,2} 'callback' cbRadioButton2 } ...
                { 'style' 'radiobutton' 'tag'    'radiobutton3' 'string' 'BRV'    'value'  answer{1,3} 'callback' cbRadioButton3 } ...
                { 'style' 'radiobutton' 'tag'    'radiobutton4' 'string' 'EEGLAB' 'value'  answer{1,4} 'callback' cbRadioButton4 } };

            geometry = { 1 1 1 1 1 1 };

            while true
                [answer, ~, strhalt] = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', params,'title', 'Import segmented EEG');

                if ~strcmp(strhalt,'retuninginputui')
                    wtLog.dbg('User quitted import configuration dialog');
                    return;
                end

                % This is a double check, if for any reason the configuration file was changed manually
                if sum(cellfun(@(e) e, answer)) ~= 0
                    break
                end
                WTUtils.eeglabMsgDlg('Warning', 'You must select one EEG system among EEP, EGI, BRV, EEGLAB')
            end

            convertToEEGLabData.EEPFlag = answer{1,1};
            convertToEEGLabData.EGIFlag = answer{1,2};
            convertToEEGLabData.BRVFlag = answer{1,3};
            convertToEEGLabData.EEGLabFlag = answer{1,4};
            success = true;
        end

        function success = defineSamplingRate(samplingData) 
            WTUtils.mustBeA(samplingData, ?WTSamplingCfg);
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
                    samplingData.SamplingRate = str2double(answer{1,1});
                    break
                catch
                    WTUtils.eeglabMsgDlg('Warning', 'Invalid sampling rate:  must be a float > 0');
                end
            end
            success = true;
        end

        function success = defineTriggerLatency(egi2eeglData)
            WTUtils.mustBeA(egi2eeglData, ?WTEGIToEEGLabCfg);
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
                    egi2eeglData.TriggerLatency = str2double(answer{1,1});
                    break
                catch
                    WTUtils.eeglabMsgDlg('Warning', 'Invalid trigger latency: must be a float >= 0');
                end
            end
            success = true;
        end

        function success = defineTrialsRangeId(minMaxTrialIdData)
            WTUtils.mustBeA(minMaxTrialIdData, ?WTMinMaxTrialIdCfg);
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
                    minId = WTUtils.ifThenElseSet(isempty(answer{1,1}), NaN, str2double(answer{1,1}));
                    maxId = WTUtils.ifThenElseSet(isempty(answer{1,2}), NaN, str2double(answer{1,2}));
                    minMaxTrialIdData.MinTrialId = minId;
                    minMaxTrialIdData.MaxTrialId = maxId;
                    minMaxTrialIdData.validate();
                catch
                    WTUtils.eeglabMsgDlg('Warning', ['Invalid min/max trials id. Allowed values for [min,max] are: [<empty>,<empty>], ' ...
                        '[int >= 0, <empty>], [<empty>, int >= 0 ], [min >= 0, max >= min]']);
                    continue
                end
                break
            end
            success = true;
        end

    end
end

