function wtChansAvgPlots(subject, conditionsToPlot, channelsToPlot, evokedOscillations)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkChopAndBaselineCorrectionDone() 
        return
    end

    interactive = wtProject.Interactive;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 4);
        WTValidations.mustBeAStringOrChar(subject);
        WTValidations.mustBeALimitedLinearCellArrayOfString(conditionsToPlot);
        WTValidations.mustBeALinearCellArrayOfString(channelsToPlot);
        subject = char(subject);
        conditionsToPlot = unique(conditionsToPlot);
        channelsToPlot = unique(channelsToPlot);
    end
    
    logFlag = wtProject.Config.WaveletTransform.LogarithmicTransform || ...
        wtProject.Config.BaselineChop.LogarithmicTransform;

    if interactive
        [fileNames, ~, measure, subject] = WTPlotsGUI.selectFilesToPlot(false, false, -1);
        if isempty(fileNames)
            return
        end
    end

    grandAverage = isempty(subject);
    if grandAverage && ~wtProject.checkGrandAverageDone()
        return
    end

    if interactive
        if ~setChansAvgPlotsParams(logFlag) 
            return
        end
    else
        measure = WTCodingUtils.ifThenElse(evokedOscillations, ...
            WTIOProcessor.WaveletsAnalisys_evWT,  WTIOProcessor.WaveletsAnalisys_avWT);
    end

    basicPrms = wtProject.Config.Basic;
    conditionsGrandPrms = wtProject.Config.ConditionsGrand;
    conditions = [conditionsGrandPrms.ConditionsList(:)' conditionsGrandPrms.ConditionsDiff(:)'];

    if interactive
        [conditionsToPlot, emptyConditionFiles] = WTIOProcessor.getConditionsFromBaselineCorrectedFileNames(fileNames);
        if ~isempty(emptyConditionFiles)
            wtLog.warn('The following files to plots do not have the right name format and have been pruned: %s', ...
                char(join(emptyConditionFiles, ',')));
        end
    elseif isempty(conditionsToPlot)
        conditionsToPlot = conditions;
    end

    intersectConditionsToPlot = sort(intersect(conditionsToPlot, conditions));
    if numel(intersectConditionsToPlot) ~= numel(conditionsToPlot)
        wtLog.warn('The following conditions to plots are not part of the current analysis and have been pruned: %s', ...
            char(join(setdiff(conditionsToPlot, intersectConditionsToPlot), ',')));
    end

    conditionsToPlot = intersectConditionsToPlot;
    nConditionsToPlot = length(conditionsToPlot);

    if nConditionsToPlot == 0
        wtProject.notifyWrn([], 'Plotting aborted due to empty conditions selection');
        return
    end

    [diffConsistency, grandConsistency] = WTProcessUtils.checkDiffAndGrandAvg(conditionsToPlot, grandAverage);
    if ~diffConsistency || ~grandConsistency
        return
    end

    [success, data] = WTProcessUtils.loadAnalyzedData(false, subject, conditionsToPlot{1}, measure);
    if ~success || ~WTConfigUtils.adjustTimeFreqDomains(wtProject.Config.ChannelsAveragePlots, data) 
        return
    end

    plotsPrms = wtProject.Config.ChannelsAveragePlots;
    timeRes = data.tim(2) - data.tim(1); 
    downsampleFactor = WTCodingUtils.ifThenElse(timeRes <= 1, 4, @()WTCodingUtils.ifThenElse(timeRes <= 2, 2, 1)); % apply downsampling to speed up plotting
    timeIdxs = find(data.tim == plotsPrms.TimeMin) : downsampleFactor : find(data.tim == plotsPrms.TimeMax);
    freqIdxs = find(data.Fa == plotsPrms.FreqMin) : find(data.Fa == plotsPrms.FreqMax);
    allChannelsLabels = {data.chanlocs.labels}';

    if interactive 
        [channelsToPlot, channelsToPlotIdxs] = WTDialogUtils.stringsSelectDlg('Select channels\nto plot:', allChannelsLabels, false, true);
    elseif isempty(channelsToPlot)
        channelsToPlot = allChannelsLabels;
    else
        intersectChannelsToPlot = intersect(channelsToPlot, allChannelsLabels);
        if numel(intersectChannelsToPlot) ~= numel(channelsToPlot)
            wtLog.warn('The following channels to plots are not part of the current analysis and have been pruned: %s', ...
               char(join(setdiff(channelsToPlot, intersectChannelsToPlot), ',')));
        end
        channelsToPlot = intersectChannelsToPlot;
        channelsToPlotIdxs = cellfun(@(l)find(strcmp(allChannelsLabels, l)), channelsToPlot);
    end
    
    if isempty(channelsToPlot)
        wtProject.notifyWrn([], 'Plotting aborted due to empty channels selection');
        return
    end

    wtLog.info('Plotting %s...', WTCodingUtils.ifThenElse(grandAverage, 'grand average', @()sprintf('subject %s', subject)));
    wtLog.pushStatus().HeaderOn = false;
    mainPlots = [];

    try
        figureWHRatio = 4/3; 
        figuresPosition = WTPlotUtils.getFiguresPositions(nConditionsToPlot, figureWHRatio, 0.3, 0.1);
        xLabel = WTPlotUtils.getXLabelParams(logFlag);
        colorMap = WTPlotUtils.getPlotsColorMap();

        for cnd = 1:nConditionsToPlot
            wtLog.contextOn().info('Condition %s', conditionsToPlot{cnd});

            [success, data] = WTProcessUtils.loadAnalyzedData(false, subject, conditionsToPlot{cnd}, measure);
            if ~success
                wtLog.contextOff(); 
                continue
            end

            figureName = WTCodingUtils.ifThenElse(grandAverage, ...
                @()char(strcat(basicPrms.FilesPrefix,'.[AVG].[', conditionsToPlot{cnd}, '].[', measure, ']')), ...
                @()char(strcat(basicPrms.FilesPrefix, '.[SBJ:', subject, '].[', conditionsToPlot{cnd}, '].[', measure, ']')));
            
            channelsLocations = data.chanlocs(channelsToPlotIdxs);
            figureTitle = WTStringUtils.chunkStrings('Channel: ', 'Avg of: ', {channelsLocations.labels}, 10);

            % Convert the data back to non-log scale straight in percent change in case logFlag is set
            WT = WTCodingUtils.ifThenElse(logFlag, @()100 * (10.^data.WT - 1), data.WT);
            WTChansAvg = mean(WT(channelsToPlotIdxs,:,:), 1);

            % Create the figure
            hFigure = figure('Position', figuresPosition{cnd});
            mainPlots(end+1) = hFigure;
            colormap(colorMap);
            hFigure.NumberTitle = 'off'; 
            hFigure.Name = figureName;
            hFigure.ToolBar = 'none';
            
            imagesc([plotsPrms.TimeMin plotsPrms.TimeMax], [plotsPrms.FreqMin plotsPrms.FreqMax], ...
                interp2(squeeze(WTChansAvg(1, freqIdxs, timeIdxs)), 4, 'spline'));

            hold('on');
            if plotsPrms.Contours
                timePace = downsampleFactor * timeRes;
                contour(plotsPrms.TimeMin:timePace:plotsPrms.TimeMax, ... 
                        plotsPrms.FreqMin:plotsPrms.FreqMax, ...
                        squeeze(WTChansAvg(1, freqIdxs, timeIdxs)), 'k');
            end

            clim(plotsPrms.Scale);
            xConst = (plotsPrms.TimeMax - plotsPrms.TimeMin) / 200;
            xPace = (plotsPrms.TimeMax - plotsPrms.TimeMin) / xConst;
            xTick = plotsPrms.TimeMin : xPace : plotsPrms.TimeMax;
            deltaFreq = plotsPrms.FreqMax - plotsPrms.FreqMin;

            if deltaFreq > 1 && deltaFreq <= 5
                freqPace = 1;
            elseif deltaFreq > 5 && deltaFreq <= 15
                freqPace = 2;
            elseif deltaFreq > 15 && deltaFreq <= 25
                freqPace = 5;
            elseif deltaFreq > 25 && deltaFreq <= 45
                freqPace = 10;
            elseif deltaFreq > 45 && deltaFreq <= 65
                freqPace = 15;
            else
                freqPace = 20;
            end

            yTick = plotsPrms.FreqMin : freqPace : plotsPrms.FreqMax;

            set(gca, 'XMinorTick', 'on', 'xgrid', 'on', 'YMinorTick', 'on', 'ygrid', 'on', ...
                     'gridlinestyle', '-', 'YDIR', 'normal', 'XTick', xTick, 'YTick', yTick);
            axis('tight');
            title(figureTitle, 'FontSize', 16, 'FontWeight', 'bold');
            xlabel('ms', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('Hz', 'FontSize', 12, 'FontWeight', 'bold');
            pace = linspace(min(plotsPrms.Scale), max(plotsPrms.Scale), 64);
            pace = pace(2) - pace(1);
            colorBar = colorbar('peer', gca, 'YTick', sort([0 plotsPrms.Scale]));
            set(get(colorBar, 'xlabel'), ...
                'String', xLabel.String, ...
                'Rotation', xLabel.Rotation, ...
                'Position', [xLabel.Position 2 * pace], ...
                'FontSize', 12, 'FontWeight', 'bold'); 

            % Set the callback to manage grid style change
            hFigure.WindowButtonDownFcn = @WTPlotUtils.setAxesGridStyleCb;
            wtLog.contextOff(); 
        end
    catch me
        wtLog.except(me);
        wtLog.popStatus();
    end

    % Wait for all main plots to close
    WTPlotUtils.waitUIs(mainPlots);
    wtLog.info('Plotting done.');
end

function success = setChansAvgPlotsParams(logFlag)
    success = false;
    wtProject = WTProject();
    plotsPrms = copy(wtProject.Config.ChannelsAveragePlots);

    if ~WTPlotsGUI.defineChansAvgPlotsSettings(plotsPrms, logFlag)
        return
    end
    
    if ~plotsPrms.persist()
        wtProject.notifyErr([], 'Failed to save channels average plots params');
        return
    end

    wtProject.Config.ChannelsAveragePlots = plotsPrms;
    success = true;
end
