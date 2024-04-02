classdef WTBaselineChopGUI
    
    methods(Static)
        function success = defineBaselineChopParams(waveletTransformParams, baselineChopParams)
            success = false;

            WTValidations.mustBeA(waveletTransformParams, ?WTWaveletTransformCfg);
            WTValidations.mustBeA(baselineChopParams, ?WTBaselineChopCfg);

            waveletTransformParamsExist = waveletTransformParams.exist();
            baselineChopParamsExist = baselineChopParams.exist();

            evokedOscillations = (waveletTransformParamsExist && waveletTransformParams.EvokedOscillations) || ...
                (baselineChopParamsExist && baselineChopParams.EvokedOscillations);
            enableUV = WTUtils.ifThenElse(waveletTransformParamsExist && waveletTransformParams.LogarithmicTransform, 'on', 'off');
            enableBs = WTUtils.ifThenElse(baselineChopParamsExist && baselineChopParams.NoBaselineCorrection, 'off', 'on');

            answer = { ...
                num2str(baselineChopParams.ChopMin), ...
                num2str(baselineChopParams.ChopMax), ...
                num2str(baselineChopParams.BaselineMin), ...
                num2str(baselineChopParams.BaselineMax), ...
                baselineChopParams.Log10Enable, ...
                baselineChopParams.NoBaselineCorrection, ...
                evokedOscillations };
            
            cbEnableBs = ['set(findobj(gcbf, ''userdata'', ''NoBC''),' ...
                        '''enable'',' 'WTUtils.ifThenElse(get(gcbo, ''value''), ''off'', ''on''));'];
            
            parameters = { ...
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
                { 'style' 'checkbox' 'value' answer{1,5} 'string' 'Log10-Transform' 'enable' enableUV } ...
                { 'style' 'checkbox' 'value' answer{1,6} 'string' 'No Baseline Correction', 'callback', cbEnableBs } ...
                { 'style' 'checkbox' 'value' answer{1,7} 'string' 'Evoked Oscillations' } };
            
            geometry = { [1 0.5 0.5 0.5] [1 0.5 0.5 0.5] [1 1 1 1] 1 1 1 };

            while true
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set baseline and edges chopping parameters');
                
                if isempty(answer)
                    return % quit on cancel button
                end

                try
                    baselineChopParams.ChopMin = WTUtils.str2double(answer{1,1});
                    baselineChopParams.ChopMax = WTUtils.str2double(answer{1,2});
                    baselineChopParams.Log10Enable = answer{1,5};
                    baselineChopParams.NoBaselineCorrection = answer{1,6};
                    baselineChopParams.EvokedOscillations = answer{1,7};

                    if baselineChopParams.NoBaselineCorrection
                        % Update baseline window only if baseline correction was selected, 
                        % otherwise retains previous values for convenience.
                        answer{1,3} = [];
                        answer{1,4} = [];
                    else
                        baselineChopParams.BaselineMin = WTUtils.str2double(answer{1,3});
                        baselineChopParams.BaselineMax = WTUtils.str2double(answer{1,4});
                    end
                    baselineChopParams.validate(true);
                catch me
                    wtLog.except(me);
                    WTUtils.wrnDlg('Review parameter', 'Invalid paramters: check the log for details');
                    continue
                end
                break
            end

            success = true;
        end
    end
end