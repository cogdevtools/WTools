classdef WTPlotsGUI

    methods(Static)
        % subject = [] when the grand average directory is selected instead of a specific subject dir
        function [fileNames, filesPath, fileType, subject] = selectFilesToPlot(perSubject, averageOnly, maxFilesNum)
            wtProject = WTProject();
            ioProc = wtProject.Config.IOProc;
            subject = [];
            
            evokedOscillations = WTEEGLabUtils.eeglabYesNoDlg('Define plot type', 'Do you want to plot Evoked Oscillations?');
            [fileType, fileExt] = ioProc.getGrandAverageFileTypeAndExtension(perSubject, evokedOscillations);
            fileFilter = {  sprintf('*-%s%s', fileType, fileExt), 'All Files' };

            while true
                title = 'Select files to plot';
                if maxFilesNum > 0
                    title = sprintf('%s\n[ Max %d files ]', title, maxFilesNum);
                end

                rootSelectionDir = WTCodingUtils.ifThenElse(averageOnly, ioProc.GrandAvgDir, ioProc.AnalysisDir);
                
                [fileNames, filesPath, ~] = WTDialogUtils.uiGetFiles(fileFilter, -1, maxFilesNum, title, ...
                    'MultiSelect', 'on', 'restrictToDirs', ['^' regexptranslate('escape', rootSelectionDir)], rootSelectionDir);
                if isempty(fileNames) 
                    wtProject.notifyWrn([], 'No files to plot selected');
                    return
                end

                if averageOnly
                    break
                end
                
                subject = ioProc.getSubjectFromPath(filesPath);
                if ~isempty(subject) || ioProc.isGrandAvgDir(filesPath)
                    break
                end
                
                WTEEGLabUtils.eeglabMsgDlg('Warning', ...
                    'Directory:\n   ''%s''\ndoesn''t look like a subject directory.\nPlease select again...', filesPath)
            end
        end

        function success = defineAvgPlotsSettings(plotsPrms, logFlag) 
            success = false;
            WTValidations.mustBeA(plotsPrms, ?WTAvgPlotsCfg);
            wtLog = WTLog();
            
            if (abs(plotsPrms.Scale(1)) == abs(plotsPrms.Scale(2))) && ...
                (logFlag && (plotsPrms.Scale(2) < 3)) || (~logFlag && (plotsPrms.Scale(2) >= 3))
                plotsPrms.Scale = WTCodingUtils.ifThenElse(logFlag, [-10.0 10.0], [-0.5 0.5]);
            end  

            answer = { ...
                num2str(plotsPrms.TimeMin) ...
                num2str(plotsPrms.TimeMax) ...
                num2str(plotsPrms.FreqMin) ...
                num2str(plotsPrms.FreqMax) ...
                sprintf(WTConfigFormatter.FmtArray, num2str(plotsPrms.Scale)) ...
                plotsPrms.Contours ...
                plotsPrms.AllChannels ... 
            };

            scaleLabel = WTCodingUtils.ifThenElse(logFlag, 'Scale (% change)', 'Scale (mV)');
            
            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text'     'string' 'Time (ms): From     ' } ...
                    { 'style' 'edit'     'string' answer{1,1} } ...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,2} }...
                    { 'style' 'text'     'string' 'Frequency (Hz): From' } ...
                    { 'style' 'edit'     'string' answer{1,3} }...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,4} }...
                    { 'style' 'text'     'string' scaleLabel } ...
                    { 'style' 'edit'     'string' answer{1,5} }...
                    { 'style' 'text'     'string' 'Draw contours' } ...
                    { 'style' 'checkbox' 'value'  answer{1,6} } ...
                    { 'style' 'text'     'string' 'Plot all channels' } ...
                    { 'style' 'checkbox' 'value'  answer{1,7} } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                };
            end

            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };
            
            while ~success
                parameters = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plots parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.TimeMin = WTNumUtils.str2double(answer{1,1});
                    plotsPrms.TimeMax = WTNumUtils.str2double(answer{1,2});
                    plotsPrms.FreqMin = WTNumUtils.str2double(answer{1,3});
                    plotsPrms.FreqMax = WTNumUtils.str2double(answer{1,4});
                    plotsPrms.Scale = WTNumUtils.str2nums(answer{1,5});
                    plotsPrms.Contours = answer{1,6};
                    plotsPrms.AllChannels = answer{1,7};
                    success = plotsPrms.validate(); 
                catch me
                    wtLog.except(me);
                end
                 
                if ~success
                    WTDialogUtils.wrnDlg('Review parameter', 'Invalid parameters: check the log for details');
                end
            end
        end

        function success = defineAvgStdErrPlotsSettings(plotsPrms)
            success = false; 
            WTValidations.mustBeA(plotsPrms, ?WTAvgStdErrPlotsCfg);
            wtLog = WTLog();

            answer = { ...
                num2str(plotsPrms.TimeMin) ...
                num2str(plotsPrms.TimeMax) ...
                num2str(plotsPrms.FreqMin) ...
                num2str(plotsPrms.FreqMax) ...
                plotsPrms.AllChannels ... 
            };
            
            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text'     'string' 'Time (ms): From     ' } ...
                    { 'style' 'edit'     'string' answer{1,1} } ...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,2} }...
                    { 'style' 'text'     'string' 'Frequency (Hz): From' } ...
                    { 'style' 'edit'     'string' answer{1,3} }...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,4} }...
                    { 'style' 'text'     'string' 'Plot all channels' } ...
                    { 'style' 'checkbox' 'value'  answer{1,5} } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                };
            end

            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };

            while ~success
                parameters = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plots parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.TimeMin = WTNumUtils.str2double(answer{1,1});
                    plotsPrms.TimeMax = WTNumUtils.str2double(answer{1,2});
                    plotsPrms.FreqMin = WTNumUtils.str2double(answer{1,3});
                    plotsPrms.FreqMax = WTNumUtils.str2double(answer{1,4});
                    plotsPrms.AllChannels = answer{1,5};
                    success = plotsPrms.validate(); 
                catch me
                    wtLog.except(me);
                end
                
                if ~success
                    WTDialogUtils.wrnDlg('Review parameter', 'Invalid parameters: check the log for details');
                end
            end
        end

        function success = defineChansAvgPlotsSettings(plotsPrms, logFlag) 
            success = false;
            WTValidations.mustBeA(plotsPrms, ?WTChansAvgPlotsCfg);
            wtLog = WTLog();
            
            if (abs(plotsPrms.Scale(1)) == abs(plotsPrms.Scale(2))) && ...
                (logFlag && (plotsPrms.Scale(2) < 3)) || (~logFlag && (plotsPrms.Scale(2) >= 3))
                plotsPrms.Scale = WTCodingUtils.ifThenElse(logFlag, [-10.0 10.0], [-0.5 0.5]);
            end  

            answer = { ...
                num2str(plotsPrms.TimeMin) ...
                num2str(plotsPrms.TimeMax) ...
                num2str(plotsPrms.FreqMin) ...
                num2str(plotsPrms.FreqMax) ...
                sprintf(WTConfigFormatter.FmtArray, num2str(plotsPrms.Scale)) ...
                plotsPrms.Contours ...
            };

            scaleLabel = WTCodingUtils.ifThenElse(logFlag, 'Scale (% change)', 'Scale (mV)');
            
            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text'     'string' 'Time (ms): From     ' } ...
                    { 'style' 'edit'     'string' answer{1,1} } ...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,2} }...
                    { 'style' 'text'     'string' 'Frequency (Hz): From' } ...
                    { 'style' 'edit'     'string' answer{1,3} }...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,4} }...
                    { 'style' 'text'     'string' scaleLabel } ...
                    { 'style' 'edit'     'string' answer{1,5} }...
                    { 'style' 'text'     'string' 'Draw contours' } ...
                    { 'style' 'checkbox' 'value'  answer{1,6} } ...
                };
            end

            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };

            while ~success
                parameters = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plots parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.TimeMin = WTNumUtils.str2double(answer{1,1});
                    plotsPrms.TimeMax = WTNumUtils.str2double(answer{1,2});
                    plotsPrms.FreqMin = WTNumUtils.str2double(answer{1,3});
                    plotsPrms.FreqMax = WTNumUtils.str2double(answer{1,4});
                    plotsPrms.Scale = WTNumUtils.str2nums(answer{1,5});
                    plotsPrms.Contours = answer{1,6};
                    success = plotsPrms.validate(); 
                catch me
                    wtLog.except(me);
                end
                
                if ~success
                    WTDialogUtils.wrnDlg('Review parameter', 'Invalid parameters: check the log for details');
                end
            end
        end

        function success = defineChansAvgStdErrPlotsSettings(plotsPrms)
            success = false; 
            WTValidations.mustBeA(plotsPrms, ?WTChansAvgStdErrPlotsCfg);
            wtLog = WTLog();

            answer = { ...
                num2str(plotsPrms.TimeMin) ...
                num2str(plotsPrms.TimeMax) ...
                num2str(plotsPrms.FreqMin) ...
                num2str(plotsPrms.FreqMax) ...
            };
            
            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text'     'string' 'Time (ms): From     ' } ...
                    { 'style' 'edit'     'string' answer{1,1} } ...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,2} }...
                    { 'style' 'text'     'string' 'Frequency (Hz): From' } ...
                    { 'style' 'edit'     'string' answer{1,3} }...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,4} }...
                };
            end

            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };

            while ~success
                parameters = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plots parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.TimeMin = WTNumUtils.str2double(answer{1,1});
                    plotsPrms.TimeMax = WTNumUtils.str2double(answer{1,2});
                    plotsPrms.FreqMin = WTNumUtils.str2double(answer{1,3});
                    plotsPrms.FreqMax = WTNumUtils.str2double(answer{1,4});
                    success = plotsPrms.validate(); 
                catch me
                    wtLog.except(me);
                end
                
                if ~success
                    WTDialogUtils.wrnDlg('Review parameter', 'Invalid parameters: check the log for details');
                end
            end
        end

        function success = define2DScalpMapPlotsSettings(plotsPrms, logFlag, maxSerieLength)
            success = false; 
            WTValidations.mustBeA(plotsPrms, ?WT2DScalpMapPlotsCfg);
            maxSerieLength = WTCodingUtils.ifThenElse(nargin > 2, @()maxSerieLength, 0);
            wtLog = WTLog();
            
            if isempty(plotsPrms.Scale) || ...
                ((abs(plotsPrms.Scale(1)) == abs(plotsPrms.Scale(2))) && ...
                (logFlag && (plotsPrms.Scale(2) < 3)) || (~logFlag && (plotsPrms.Scale(2) >= 3)))
                plotsPrms.Scale = WTCodingUtils.ifThenElse(logFlag, [-10.0 10.0], [-0.5 0.5]);
            end  

            answer = { ...
                sprintf(WTConfigFormatter.FmtArray, num2str(plotsPrms.Time)) ...
                sprintf(WTConfigFormatter.FmtArray, num2str(plotsPrms.Frequency)) ...
                sprintf(WTConfigFormatter.FmtArray, num2str(plotsPrms.Scale)) ...
                plotsPrms.PeripheralElectrodes ...
                plotsPrms.Contours ... 
                plotsPrms.ElectrodesLabel ... 
            };

            scaleLabel = WTCodingUtils.ifThenElse(logFlag, 'Scale (% change)', 'Scale (mV)');
            
            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text'     'string' 'Time (ms): From-[pace]-To     ' } ...
                    { 'style' 'edit'     'string'  answer{1,1} } ...
                    { 'style' 'text'     'string' 'Frequency (Hz): From-[pace]-To' } ...
                    { 'style' 'edit'     'string'  answer{1,2} } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' 'NOTE: The pace is optional and defines time / frequency series. The pace can be defined either' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '             for time or frequency, not both. Small paces can slow down sensibly the processing.' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '             Example: Frequency = [1 10 201] => 20 frequency based subplots.' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string'  scaleLabel } ...
                    { 'style' 'edit'     'string'  answer{1,3} } ...
                    { 'style' 'text'     'string' 'Peripheral Electrodes' } ...
                    { 'style' 'checkbox' 'value'   answer{1,4} } ...
                    { 'style' 'text'     'string' 'Draw contours' } ...
                    { 'style' 'checkbox' 'value'   answer{1,5} } ...
                    { 'style' 'text'     'string' 'Electrode labels' } ...
                    { 'style' 'checkbox' 'value'   answer{1,6} } ...
                };
            end
            
            geometry = { [1 1] [1 1] [1 1] [1 0] [1 0] [1 0] [1 1] [1 1] [1 1] [1 1] [1 1] };

            while ~success
                parameters = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plots parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.Time = answer{1,1};
                    plotsPrms.Frequency =answer{1,2};
                    plotsPrms.Scale = WTNumUtils.str2nums(answer{1,3});
                    plotsPrms.PeripheralElectrodes = answer{1,4};
                    plotsPrms.Contours = answer{1,5};
                    plotsPrms.ElectrodesLabel = answer{1,6};
                    success = plotsPrms.validate(); 
                catch me
                    wtLog.except(me);
                end

                if ~success
                    WTDialogUtils.wrnDlg('Review parameter', 'Invalid parameters: check the log for details');
                end

                if maxSerieLength > 0 && ~isempty(plotsPrms.TimeResolution) 
                    n = length(plotsPrms.TimeMin : plotsPrms.TimeResolution : plotsPrms.TimeMax);
                    if maxSerieLength < n 
                        WTDialogUtils.wrnDlg('Review parameter', ...
                            [ 'You defined a time serie with %d samples which reflects into as many plots.' ... 
                              'The application manages max %d plots. Adjust please.' ], ...
                              n, maxSerieLength)
                        success = false;
                        continue
                    end
                end
                
                if maxSerieLength > 0 && ~isempty(plotsPrms.FreqResolution) 
                    n = length(plotsPrms.FreqMin : plotsPrms.FreqResolution : plotsPrms.FreqMax);
                    if maxSerieLength < n
                        WTDialogUtils.wrnDlg('Review parameter', ...
                            [ 'You defined a frequency serie with %d samples which reflects into as many plots.' ... 
                              'The application manages max %d plots. Adjust please.' ], ...
                               n, maxSerieLength)
                        success = false;
                        continue
                    end
                end

            end
            success = true;
        end

        function success = define3DScalpMapPlotsSettings(plotsPrms, logFlag)
            success = false; 
            WTValidations.mustBeA(plotsPrms, ?WT3DScalpMapPlotsCfg);
            wtLog = WTLog();
            
            if isempty(plotsPrms.Scale) || ...
                ((abs(plotsPrms.Scale(1)) == abs(plotsPrms.Scale(2))) && ...
                (logFlag && (plotsPrms.Scale(2) < 3)) || (~logFlag && (plotsPrms.Scale(2) >= 3)))
                plotsPrms.Scale = WTCodingUtils.ifThenElse(logFlag, [-10.0 10.0], [-0.5 0.5]);
            end  

            answer = { ...
                sprintf(WTConfigFormatter.FmtArray, num2str(plotsPrms.Time)) ...
                sprintf(WTConfigFormatter.FmtArray, num2str(plotsPrms.Frequency)) ...
                sprintf(WTConfigFormatter.FmtArray, num2str(plotsPrms.Scale)) ...
            };

            scaleLabel = WTCodingUtils.ifThenElse(logFlag, 'Scale (% change)', 'Scale (mV)');
            
            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text'     'string' 'Time (ms): From - To     ' } ...
                    { 'style' 'edit'     'string'  answer{1,1} } ...
                    { 'style' 'text'     'string' 'Frequency (Hz): From - To' } ...
                    { 'style' 'edit'     'string'  answer{1,2} } ...
                    { 'style' 'text'     'string'  scaleLabel } ...
                    { 'style' 'edit'     'string'  answer{1,3} } ...
                };
            end
            
            geometry = { [1 1] [1 1] [1 1] };

            while ~success
                parameters = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plots parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.Time = answer{1,1};
                    plotsPrms.Frequency = answer{1,2};
                    plotsPrms.Scale = WTNumUtils.str2nums(answer{1,3});
                    success = plotsPrms.validate(); 
                catch me
                    wtLog.except(me);
                end

                if ~success 
                    WTDialogUtils.wrnDlg('Review parameter', 'Invalid parameters: check the log for details');
                end
            end
        end
    end
end