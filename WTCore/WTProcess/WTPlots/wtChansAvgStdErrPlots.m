function wtChansAvgStdErrPlots(conditionsToPlot, channelsToPlot, evokedOscillations)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkGrandAverageDone() 
        return
    end

    interactive = wtProject.Interactive;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 3);
        WTValidations.mustBeALimitedLinearCellArrayOfString(conditionsToPlot);
        WTValidations.mustBeALinearCellArrayOfString(channelsToPlot);
        channelsToPlot = unique(channelsToPlot);
        conditionsToPlot = unique(conditionsToPlot);
        WTValidations.mustBeLTE(length(conditionsToPlot), 2); 
    end
    
    waveletTransformPrms = wtProject.Config.WaveletTransform;
    baselineChopPrms = wtProject.Config.BaselineChop;
    logFlag = waveletTransformPrms.LogarithmicTransform || baselineChopPrms.LogarithmicTransform;
    evokFlag = waveletTransformPrms.EvokedOscillations;

    if interactive
        [fileNames, ~, measure] = WTPlotsGUI.selectFilesToPlot(evokFlag, true, true, 2);
        if isempty(fileNames)
            return
        end
        if ~setChansAvgStdErrPlotsParams() 
            return
        end
    else
        measure = WTCodingUtils.ifThenElse(evokedOscillations, ...
            WTIOProcessor.WaveletsAnalisys_evWT,  WTIOProcessor.WaveletsAnalisys_avWT);
    end

    basicPrms = wtProject.Config.Basic;
    conditionsGrandPrms = wtProject.Config.ConditionsGrand;
    conditions = [conditionsGrandPrms.ConditionsList(:)' conditionsGrandPrms.ConditionsDiff(:)'];
    grandAverage = true;
    subject = ''; % subect forced to value which means means grand average

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

    [success, data] = WTProcessUtils.loadAnalyzedData(true, subject, conditionsToPlot{1}, measure);
    if ~success || ~WTConfigUtils.adjustTimeFreqDomains(wtProject.Config.ChannelsAverageStdErrPlots, data) 
        return
    end

    plotsPrms = wtProject.Config.ChannelsAverageStdErrPlots;
    timeRes = WTCodingUtils.ifThenElse(length(data.tim) > 1, @()data.tim(2) - data.tim(1), 1); 
    timeIdxs = find(data.tim == plotsPrms.TimeMin) : find(data.tim == plotsPrms.TimeMax);
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

    wtLog.info('Plotting channels grand average & standard error...');
    wtLog.pushStatus().HeaderOn = false;
    mainPlots = cell(1, 1);    

    try
        % The width / height ratio of the main figure
        figureWHRatio = 4/3;
        figuresPosition = WTPlotUtils.getFiguresPositions(1, figureWHRatio, 0.3, 0.1);
        figureName = sprintf('%s.[%s].[%d-%d Hz]', basicPrms.FilesPrefix, measure, plotsPrms.FreqMin, plotsPrms.FreqMax); 
        channelsLocations = data.chanlocs(channelsToPlotIdxs);
        figureTitle = WTStringUtils.chunkStrings('Channel: ', 'Avg of: ', {channelsLocations.labels}, 10);
        yLabel = WTPlotUtils.getYLabelParams(logFlag);

        % Create the figure
        hFigure = figure('Position', figuresPosition{1});
        mainPlots{1} = hFigure;
        hFigure.NumberTitle = 'off'; 
        hFigure.Name = figureName;
        hFigure.ToolBar = 'none';

        % Set time pace
        timeChunk = (plotsPrms.TimeMax - plotsPrms.TimeMin) / 100;
        if timeChunk < 1
            timePace = 10;
        elseif timeChunk < 2
            timePace = 20;
        elseif timeChunk < 8
            timePace = 100;
        else
            timePace = 200;
        end  

        for cnd = 1:nConditionsToPlot
            wtLog.contextOn().info('Condition %s', conditionsToPlot{cnd});

            [success, data] = WTProcessUtils.loadAnalyzedData(true, subject, conditionsToPlot{cnd}, measure);
            if ~success
                wtLog.contextOff(); 
                break
            end

            WTChansAvg = mean(data.WT(channelsToPlotIdxs, :, :), 1);
            WTChansAvg = WTChansAvg(1, freqIdxs, timeIdxs);
            WTChansAvg = mean(WTChansAvg, 2);
            WTChansAvg = squeeze(WTChansAvg(1, :, :)); % Squeeze fr but not channel
            WTChansAvg = WTChansAvg';
            WTChansAvgStdErr = squeeze(mean(std(mean(data.SS(channelsToPlotIdxs, freqIdxs, timeIdxs, :), 1), 0, 4)./sqrt(size(data.SS, 4)), 2));

            if cnd == 1
                errorbar(WTChansAvg, WTChansAvgStdErr, 'b');
                hold('on');
            else
                errorbar(WTChansAvg, WTChansAvgStdErr, 'r'); 
                legend(conditionsToPlot{1}, conditionsToPlot{nConditionsToPlot});
            end

            if cnd == nConditionsToPlot
                title(figureTitle, 'FontSize', 16, 'FontWeight','bold');
                set(gca, 'XTick', 1 : timePace/timeRes : length(timeIdxs))
                set(gca, 'XTickLabel', plotsPrms.TimeMin : timePace : plotsPrms.TimeMax);
                set(gca, 'XMinorTick', 'on', 'xgrid', 'on', 'YMinorTick','on',...
                    'ygrid', 'on', 'gridlinestyle', ':', 'YDIR', 'normal');
                axis('tight');
                xlabel('ms', 'FontSize', 12, 'FontWeight', 'bold');
                ylabel(yLabel.String, 'FontSize', 12, 'FontWeight', 'bold');
            end

            wtLog.contextOff(); 
        end

        % Set the callback to manage grid style change
        hFigure.WindowButtonDownFcn = @WTPlotUtils.setAxesGridStyleCb;
    catch me
        wtLog.except(me);
        wtLog.popStatus();
    end

    % Wait for all main plots to close
    WTPlotUtils.waitUIs(mainPlots);
    wtLog.info('Plotting done.');
end

function success = setChansAvgStdErrPlotsParams()
    success = false;
    wtProject = WTProject();
    plotsPrms = copy(wtProject.Config.ChannelsAverageStdErrPlots);

    if ~WTPlotsGUI.defineChansAvgStdErrPlotsSettings(plotsPrms)
        return
    end
    
    if ~plotsPrms.persist()
        wtProject.notifyErr([], 'Failed to save channels average with stderr plots params');
        return
    end

    wtProject.Config.ChannelsAverageStdErrPlots = plotsPrms;
    success = true;
end
