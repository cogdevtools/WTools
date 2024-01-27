classdef WTBaselineChopGUI
    
    methods(Static)
        function success = baselineChopParams(waveletTransformParams, baselineChopParams)
            success = false;
            wtLog = WTLog();

            WTUtils.mustBeA(waveletTransformParams, ?WTWaveletTransformCfg)
            WTUtils.mustBeA(baselineChopParams, ?WTBaselineChopCfg)

            waveletTransformParamsExist = waveletTransformParams.exist();
            baselineChopParamsExist = baselineChopParams.exist();

            evokedOscillations = (waveletTransformParamsExist && waveletTransformParams.EvokedOscillations) || ...
                (baselineChopParamsExist && baselineChopParams.EvokedOscillations);
            enableUV = WTUtils.ifThenElseSet(waveletTransformParamsExist && waveletTransformParams.LogarithmicTransform, 'on', 'off');
            enableBs = WTUtils.ifThenElseSet(baselineChopParamsExist && baselineChopParams.NoBaselineCorrection, 'off', 'on');

            defaultAnswer = { ...
                num2str(baselineChopParams.ChopMin), ...
                num2str(baselineChopParams.ChopMax), ...
                num2str(baselineChopParams.BaselineMin), ...
                num2str(baselineChopParams.BaselineMax), ...
                baselineChopParams.Log10Enable, ...
                baselineChopParams.NoBaselineCorrection, ...
                evokedOscillations };
            
            cbEnableBs = ['set(findobj(gcbf, ''userdata'', ''NoBC''),' ...
                        '''enable'',' 'fastif(get(gcbo, ''value''), ''off'', ''on''));'];
            
            parameters = { ...
                { 'style' 'text'     'string' 'Chop Ends:              Left' } ...
                { 'style' 'edit'     'string' defaultAnswer{1,1} } ...
                { 'style' 'text'     'string' 'Right' } ...
                { 'style' 'edit'     'string' defaultAnswer{1,2} } ...
                { 'style' 'text'     'string' 'Correct Baseline:    From' } ...
                { 'style' 'edit'     'string' defaultAnswer{1,3} 'userdata' 'NoBC' 'enable' enableBs } ...
                { 'style' 'text'     'string' 'To' } ...
                { 'style' 'edit'     'string' defaultAnswer{1,4} 'userdata' 'NoBC' 'enable' enableBs } ...
                { 'style' 'text'     'string' '' } ...
                { 'style' 'text'     'string' '' } ...
                { 'style' 'text'     'string' '' } ...
                { 'style' 'text'     'string' '' } ...
                { 'style' 'checkbox' 'value' defaultAnswer{1,5} 'string' 'Log10-Transform' 'enable' enableUV } ...
                { 'style' 'checkbox' 'value' defaultAnswer{1,6} 'string' 'No Baseline Correction', 'callback', cbEnableBs } ...
                { 'style' 'checkbox' 'value' defaultAnswer{1,7} 'string' 'Evoked Oscillations' } };
            
            geometry = { [1 0.5 0.5 0.5] [1 0.5 0.5 0.5] [1 1 1 1] 1 1 1 };
            warnDlg = @(msg)WTUtils.wrnDlg('Review parameter', msg);

            while true
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set baseline and edges chopping parameters');
                
                if isempty(answer)
                    return % quit on cancel button
                end
                
                chopMin = str2double(answer{1,1});
                chopMax = str2double(answer{1,2});
                baselineMin = str2double(answer{1,3});
                baselineMax = str2double(answer{1,4});
                bog10Enable = answer{1,5};
                noBaseline = answer{1,6};
                evokedOscillation = answer{1,7};

                if noBaseline
                    baselineMin = 0;
                    answer{1,3} = [];
                    baselineMax = 0;
                    answer{1,4} = [];
                end

                if chopMin > chopMax
                    warnDlg('The chopping window is not valid!');
                    continue
                end

                if ~noBaseline && baselineMin > baselineMax
                    warnDlg('The baseline window is not valid!');
                    continue
                end

                break
            end

            baselineChopParams.ChopMin = chopMin;
            baselineChopParams.ChopMax = chopMax;
            % Update baseline window only if baseline correction was selected, or retain previous values for convenience
            if ~noBaseline 
                baselineChopParams.BaselineMin = baselineMin;
                baselineChopParams.BaselineMax = baselineMax;
            end
            
            baselineChopParams.Log10Enable = bog10Enable;
            baselineChopParams.NoBaselineCorrection = noBaseline;
            baselineChopParams.EvokedOscillations = evokedOscillation;
            success = true;
        end
    end
end