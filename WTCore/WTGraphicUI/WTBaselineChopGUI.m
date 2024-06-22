classdef WTBaselineChopGUI
    
    methods(Static)
        function success = defineBaselineChopParams(baselineChopParams, logFlag, evokFlag)
            success = false;
            WTValidations.mustBeA(baselineChopParams, ?WTBaselineChopCfg);

            baselineChopParamsExist = baselineChopParams.exist();
            
            % EvokedOscillations can not be set: it reflects previous choices (wavelet tansformation)
            evokedOscillations = WTCodingUtils.ifThenElse(evokFlag, 1, 0);
            enableEvok = 'off';

            % Log10 can be set only if data have not been already log transformed
            enableLog = WTCodingUtils.ifThenElse(logFlag, 'off', 'on');
            enableBs = WTCodingUtils.ifThenElse(baselineChopParamsExist && baselineChopParams.NoBaselineCorrection, 'off', 'on');

            answer = { ...
                num2str(baselineChopParams.ChopTimeMin), ...
                num2str(baselineChopParams.ChopTimeMax), ...
                num2str(baselineChopParams.BaselineTimeMin), ...
                num2str(baselineChopParams.BaselineTimeMax), ...
                WTCodingUtils.ifThenElse(logFlag, 1, baselineChopParams.LogarithmicTransform), ...
                baselineChopParams.NoBaselineCorrection, ...
                evokedOscillations };
            
            cbEnableBs = ['set(findobj(gcbf, ''userdata'', ''NoBC''),' ...
                        '''enable'',' 'WTCodingUtils.ifThenElse(get(gcbo, ''value''), ''off'', ''on''));'];
            
            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text'     'string' 'Chop Ends:              Left' } ...
                    { 'style' 'edit'     'string' answer{1,1} } ...
                    { 'style' 'text'     'string' 'Right' } ...
                    { 'style' 'edit'     'string' answer{1,2} } ...
                    { 'style' 'text'     'string' 'Correct Baseline:    From' } ...
                    { 'style' 'edit'     'string' answer{1,3} 'userdata' 'NoBC' 'enable' enableBs } ...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,4} 'userdata' 'NoBC' 'enable' enableBs } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'checkbox' 'value' answer{1,5} 'string' 'Log10-Transform' 'enable' enableLog } ...
                    { 'style' 'checkbox' 'value' answer{1,6} 'string' 'No Baseline Correction', 'callback', cbEnableBs } ...
                    { 'style' 'checkbox' 'value' answer{1,7} 'string' 'Evoked Oscillations' 'enable'  enableEvok } };
            end

            geometry = { [1 0.5 0.5 0.5] [1 0.5 0.5 0.5] [1 1 1 1] 1 1 1 };

            while true
                parameters = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set baseline and edges chopping parameters');
                
                if isempty(answer)
                    return % quit on cancel button
                end

                try
                    baselineChopParams.ChopTimeMin = WTNumUtils.str2double(answer{1,1});
                    baselineChopParams.ChopTimeMax = WTNumUtils.str2double(answer{1,2});
                    baselineChopParams.LogarithmicTransform = answer{1,5};
                    baselineChopParams.NoBaselineCorrection = answer{1,6};
                    baselineChopParams.EvokedOscillations = answer{1,7};

                    if baselineChopParams.NoBaselineCorrection
                        % Update baseline window only if baseline correction was selected, 
                        % otherwise retains previous values for convenience.
                        answer{1,3} = [];
                        answer{1,4} = [];
                    else
                        baselineChopParams.BaselineTimeMin = WTNumUtils.str2double(answer{1,3});
                        baselineChopParams.BaselineTimeMax = WTNumUtils.str2double(answer{1,4});
                    end
                    baselineChopParams.validate(true);
                catch me
                    wtLog.except(me);
                    WTDialogUtils.wrnDlg('Review parameter', 'Invalid parameters: check the log for details');
                    continue
                end
                break
            end

            success = true;
        end
    end
end