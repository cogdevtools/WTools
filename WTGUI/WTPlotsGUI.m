classdef WTPlotsGUI

    methods(Static)
        % subject = [] when the grand average directory is selected instead of a specific subject dir
        function [fileNames, filesPath, fileType, subject] = selectFilesToPlot(perSubject, averageOnly, maxFilesNum)
            averageOnly = any(logical(averageOnly));
            wtProject = WTProject();
            ioProc = wtProject.Config.IOProc;
            subject = [];
            

            evokedOscillations = WTUtils.eeglabYesNoDlg('Define plot type', 'Do you want to plot Evoked Oscillations?');
            [fileType, fileExt] = ioProc.getGrandAverageFileTypeAndExtension(perSubject, evokedOscillations);
            fileFilter = {  sprintf('*-%s%s', fileType, fileExt), 'All Files' };

            while true
                title = 'Select files to plot';
                if maxFilesNum > 0
                    title = sprintf('%s\n[ Max %d files ]', title, maxFilesNum);
                end

                rootSelectionDir = WTUtils.ifThenElse(averageOnly, ioProc.GrandAvgDir, ioProc.AnalysisDir);
                
                [fileNames, filesPath, ~] = WTUtils.uiGetFiles(fileFilter, -1, maxFilesNum, title, ...
                    'MultiSelect', 'on', 'restrictToDirs', ['^' rootSelectionDir], rootSelectionDir);
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
                
                WTUtils.eeglabMsgDlg('Warning', ...
                    'Directory:\n   ''%s''\ndoesn''t look like a subject directory.\nPlease select again...', filesPath)
            end
        end

        function success = defineAvgPlotsSettings(plotsPrms, logFlag) 
            success = false;
            WTValidations.mustBeA(plotsPrms, ?WTAvgPlotsCfg);
            logFlag = any(logical(logFlag));
            wtLog = WTLog();
            
            if (abs(plotsPrms.Scale(1)) == abs(plotsPrms.Scale(2))) && ...
                (logFlag && (plotsPrms.Scale(2) < 3)) || (~logFlag && (plotsPrms.Scale(2) >= 3))
                plotsPrms.Scale = WTUtils.ifThenElse(logFlag, [-10.0 10.0], [-0.5 0.5]);
            end  

            answer = { ...
                num2str(plotsPrms.TimeMin) ...
                num2str(plotsPrms.TimeMax) ...
                num2str(plotsPrms.FreqMin) ...
                num2str(plotsPrms.FreqMax) ...
                sprintf(WTFormatter.FmtArray, num2str(plotsPrms.Scale)) ...
                plotsPrms.Contours ...
                plotsPrms.AllChannels ... 
            };

            scaleLabel = WTUtils.ifThenElse(logFlag, 'Scale (�x% change)', 'Scale (mV)');
            
            parameters = { ...
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
            
            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };
            
            while true
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plotting parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.TimeMin = WTUtils.str2double(answer{1,1});
                    plotsPrms.TimeMax = WTUtils.str2double(answer{1,2});
                    plotsPrms.FreqMin = WTUtils.str2double(answer{1,3});
                    plotsPrms.FreqMax = WTUtils.str2double(answer{1,4});
                    plotsPrms.Scale = WTUtils.str2nums(answer{1,5});
                    plotsPrms.Contours = answer{1,6};
                    plotsPrms.AllChannels = answer{1,7};
                    plotsPrms.validate();
                catch me
                    wtLog.except(me);
                    WTUtils.wrnDlg('Review parameter', 'Invalid paramters: check the log for details');
                    continue
                end
                break
            end
            success = true;
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
            
            parameters = { ...
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
            
            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };

            while true
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plotting parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.TimeMin = WTUtils.str2double(answer{1,1});
                    plotsPrms.TimeMax = WTUtils.str2double(answer{1,2});
                    plotsPrms.FreqMin = WTUtils.str2double(answer{1,3});
                    plotsPrms.FreqMax = WTUtils.str2double(answer{1,4});
                    plotsPrms.AllChannels = answer{1,5};
                    plotsPrms.validate();
                catch me
                    wtLog.except(me);
                    WTUtils.wrnDlg('Review parameter', 'Invalid paramters: check the log for details');
                    continue
                end
                break
            end
            success = true;
        end

        function success = defineChansAvgPlotsSettings(plotsPrms, logFlag) 
            success = false;
            WTValidations.mustBeA(plotsPrms, ?WTChansAvgPlotsCfg);
            logFlag = any(logical(logFlag));
            wtLog = WTLog();
            
            if (abs(plotsPrms.Scale(1)) == abs(plotsPrms.Scale(2))) && ...
                (logFlag && (plotsPrms.Scale(2) < 3)) || (~logFlag && (plotsPrms.Scale(2) >= 3))
                plotsPrms.Scale = WTUtils.ifThenElse(logFlag, [-10.0 10.0], [-0.5 0.5]);
            end  

            answer = { ...
                num2str(plotsPrms.TimeMin) ...
                num2str(plotsPrms.TimeMax) ...
                num2str(plotsPrms.FreqMin) ...
                num2str(plotsPrms.FreqMax) ...
                sprintf(WTFormatter.FmtArray, num2str(plotsPrms.Scale)) ...
                plotsPrms.Contours ...
            };

            scaleLabel = WTUtils.ifThenElse(logFlag, 'Scale (�x% change)', 'Scale (mV)');
            
            parameters = { ...
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
            
            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };

            while true
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plotting parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.TimeMin = WTUtils.str2double(answer{1,1});
                    plotsPrms.TimeMax = WTUtils.str2double(answer{1,2});
                    plotsPrms.FreqMin = WTUtils.str2double(answer{1,3});
                    plotsPrms.FreqMax = WTUtils.str2double(answer{1,4});
                    plotsPrms.Scale = WTUtils.str2nums(answer{1,5});
                    plotsPrms.Contours = answer{1,6};
                    plotsPrms.validate();
                catch me
                    wtLog.except(me);
                    WTUtils.wrnDlg('Review parameter', 'Invalid paramters: check the log for details');
                    continue
                end
                break
            end
            success = true;
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
            
            parameters = { ...
                { 'style' 'text'     'string' 'Time (ms): From     ' } ...
                { 'style' 'edit'     'string' answer{1,1} } ...
                { 'style' 'text'     'string' 'To' } ...
                { 'style' 'edit'     'string' answer{1,2} }...
                { 'style' 'text'     'string' 'Frequency (Hz): From' } ...
                { 'style' 'edit'     'string' answer{1,3} }...
                { 'style' 'text'     'string' 'To' } ...
                { 'style' 'edit'     'string' answer{1,4} }...
                { 'style' 'text'     'string' '' } ...
            };
            
            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };

            while true
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plotting parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.TimeMin = WTUtils.str2double(answer{1,1});
                    plotsPrms.TimeMax = WTUtils.str2double(answer{1,2});
                    plotsPrms.FreqMin = WTUtils.str2double(answer{1,3});
                    plotsPrms.FreqMax = WTUtils.str2double(answer{1,4});
                    plotsPrms.validate();
                catch me
                    wtLog.except(me);
                    WTUtils.wrnDlg('Review parameter', 'Invalid paramters: check the log for details');
                    continue
                end
                break
            end
            success = true;
        end

        function success = defineScalpMapPlotsSettings(plotsPrms, logFlag)
            success = false; 
            WTValidations.mustBeA(plotsPrms, ?WTScalpMapPlotsCfg);
            logFlag = any(logical(logFlag));
            wtLog = WTLog();
            
            if (abs(plotsPrms.Scale(1)) == abs(plotsPrms.Scale(2))) && ...
                (logFlag && (plotsPrms.Scale(2) < 3)) || (~logFlag && (plotsPrms.Scale(2) >= 3))
                plotsPrms.Scale = WTUtils.ifThenElse(logFlag, [-10.0 10.0], [-0.5 0.5]);
            end  

            answer = { ...
                sprintf(WTFormatter.FmtArray, num2str(plotsPrms.Time)); ...
                sprintf(WTFormatter.FmtArray, num2str(plotsPrms.Frequency)); ...
                sprintf(WTFormatter.FmtArray, num2str(plotsPrms.Scale)) ...
                plotsPrms.PeripheralElectrodes ...
                plotsPrms.Contours ... 
                plotsPrms.ElectrodesLabel ... 
            };

            scaleLabel = WTUtils.ifThenElse(logFlag, 'Scale (�x% change)', 'Scale (mV)');
            
            parameters = { ...
                { 'style' 'text'     'string' 'Time (ms): From - To     ' } ...
                { 'style' 'edit'     'string'  answer{1,1} } ...
                { 'style' 'text'     'string' 'Frequency (Hz): From - To' } ...
                { 'style' 'edit'     'string'  answer{1,2} } ...
                { 'style' 'text'     'string'  scaleLabel } ...
                { 'style' 'edit'     'string'  answer{1,3} } ...
                { 'style' 'text'     'string' 'Peripheral Electrodes' } ...
                { 'style' 'checkbox' 'value'   answer{1,4} } ...
                { 'style' 'text'     'string' 'Draw contours' } ...
                { 'style' 'checkbox' 'value'   answer{1,5} } ...
                { 'style' 'text'     'string' 'Electrode labels' } ...
                { 'style' 'checkbox' 'value'   answer{1,6} } ...
                { 'style' 'text'     'string' '' } ...
            };
            
            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };

            while true
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plotting parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.Time = WTUtils.str2nums(answer{1,1});
                    plotsPrms.Frequencsy = WTUtils.str2nums(answer{1,2});
                    plotsPrms.Scale = WTUtils.str2nums(answer{1,3});
                    plotsPrms.PeripheralElectrodes = answer{1,4};
                    plotsPrms.Contours = answer{1,5};
                    plotsPrms.ElectrodesLabel = answer{1,6};
                    plotsPrms.validate();
                catch me
                    wtLog.except(me);
                    WTUtils.wrnDlg('Review parameter', 'Invalid paramters: check the log for details');
                    continue
                end
                break
            end
            success = true;
        end

        function success = define3DScalpMapPlotsSettings(plotsPrms, logFlag)
            success = false; 
            WTValidations.mustBeA(plotsPrms, ?WTScalpMapPlotsCfg);
            logFlag = any(logical(logFlag));
            wtLog = WTLog();
            
            if (abs(plotsPrms.Scale(1)) == abs(plotsPrms.Scale(2))) && ...
                (logFlag && (plotsPrms.Scale(2) < 3)) || (~logFlag && (plotsPrms.Scale(2) >= 3))
                plotsPrms.Scale = WTUtils.ifThenElse(logFlag, [-10.0 10.0], [-0.5 0.5]);
            end  

            answer = { ...
                sprintf(WTFormatter.FmtArray, num2str(plotsPrms.Time)); ...
                sprintf(WTFormatter.FmtArray, num2str(plotsPrms.Frequency)); ...
                sprintf(WTFormatter.FmtArray, num2str(plotsPrms.Scale)) ...
            };

            scaleLabel = WTUtils.ifThenElse(logFlag, 'Scale (�x% change)', 'Scale (mV)');
            
            parameters = { ...
                { 'style' 'text'     'string' 'Time (ms): From - To     ' } ...
                { 'style' 'edit'     'string'  answer{1,1} } ...
                { 'style' 'text'     'string' 'Frequency (Hz): From - To' } ...
                { 'style' 'edit'     'string'  answer{1,2} } ...
                { 'style' 'text'     'string'  scaleLabel } ...
                { 'style' 'edit'     'string'  answer{1,3} } ...
                { 'style' 'text'     'string' '' } ...
            };
            
            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };

            while true
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set plotting parameters');
                
                if isempty(answer)
                    return 
                end

                try
                    plotsPrms.Time = WTUtils.str2nums(answer{1,1});
                    plotsPrms.Frequencsy = WTUtils.str2nums(answer{1,2});
                    plotsPrms.Scale = WTUtils.str2nums(answer{1,3});
                    plotsPrms.validate();
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