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

function wtChansAvgStdErrPlots(conditionsToPlot, channelsToPlot)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkGrandAverageDone() 
        return
    end

    interactive = wtProject.Interactive;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 2);
        WTValidations.mustBeLimitedLinearCellArrayOfChar(conditionsToPlot);
        WTValidations.mustBeLinearCellArrayOfChar(channelsToPlot);
        channelsToPlot = unique(channelsToPlot);
        conditionsToPlot = unique(conditionsToPlot);
        WTValidations.mustBeLTE(length(conditionsToPlot), 2); 
    end
    
    if interactive
        if ~setChansAvgStdErrPlotsParams() 
            return
        end
        plotsPrms = wtProject.Config.ChannelsAverageStdErrPlots;
        [fileNames, ~, measure] = WTPlotsGUI.selectFilesToPlot(plotsPrms.EvokedOscillations, true, true, 2);
        if isempty(fileNames)
            return
        end
    else
        plotsPrms = wtProject.Config.ChannelsAverageStdErrPlots;
        measure = WTCodingUtils.ifThenElse(plotsPrms.EvokedOscillations, ...
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

    [success, data] = WTProcessUtils.loadAnalyzedData(true, subject, conditionsToPlot{1}, measure);
    if ~success || ~WTConfigUtils.adjustTimeFreqDomains(wtProject.Config.ChannelsAverageStdErrPlots, data) 
        return
    end

    timeRes = WTCodingUtils.ifThenElse(length(data.tim) > 1, @()data.tim(2) - data.tim(1), 1); 
    timeIdxs = find(data.tim == plotsPrms.TimeMin) : find(data.tim == plotsPrms.TimeMax);
    freqIdxs = find(data.Fa == plotsPrms.FreqMin) : find(data.Fa == plotsPrms.FreqMax);
    allChannelsLabels = {data.chanlocs.labels}';
    
    if plotsPrms.AllChannels
        if ~interactive && numel(channelsToPlot) > 0
            wtLog.warn('All channels will be plotted: subset ignored: %s', char(join(channelsToPlot, ','))); 
        end
        channelsToPlot = allChannelsLabels;
        channelsToPlotIdxs = 1:numel(allChannelsLabels);
    elseif interactive 
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

    plotLabel = WTPlotUtils.getPlotLabel( ...
        plotsPrms.EvokedOscillations, ...
        plotsPrms.TransformPower, ...
        plotsPrms.BaselineSubtraction, ...
        plotsPrms.BaselineNormalization, ... 
        plotsPrms.Decibel);

    wtLog.info('Plotting channels grand average & standard error...');
    wtLog.pushStatus().HeaderOn = false;
    mainPlots = cell(1, 1);    

    try
        % The width / height ratio of the main figure
        figureWHRatio = 4/3;
        figuresPosition = WTPlotUtils.getFiguresPositions(1, figureWHRatio, 0.3, 0.1);
        figureName = sprintf('ChansAvgStdErr: %s.[%s].[%d-%d Hz]', basicPrms.FilesPrefix, measure, plotsPrms.FreqMin, plotsPrms.FreqMax); 
        channelsLocations = data.chanlocs(channelsToPlotIdxs);
        figureTitle = WTStringUtils.chunkStrings('Channel: ', 'Avg of: ', {channelsLocations.labels}, 10);
        yLabelParams = WTPlotUtils.getPlotYLabelParams(plotLabel);

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

        legendTxt = cell(1, nConditionsToPlot);
        colors = WTPlotUtils.generateHighContrastPalette(nConditionsToPlot);

        for cnd = 1:nConditionsToPlot
            wtLog.contextOn().info('Condition %s', conditionsToPlot{cnd});

            [success, data] = WTProcessUtils.loadAnalyzedData(true, subject, conditionsToPlot{cnd}, measure);
            if ~success
                wtLog.contextOff(); 
                break
            end

            chnsAvg = mean(data.WT(channelsToPlotIdxs, :, :), 1);
            chnsAvg = chnsAvg(1, freqIdxs, timeIdxs);
            chnsAvg = mean(chnsAvg, 2);
            chnsAvg = squeeze(chnsAvg(1, :, :)); % Squeeze fr but not channel
            chnsAvg = chnsAvg';
            chnsStdErr = squeeze(mean(std(mean(data.SS(channelsToPlotIdxs, freqIdxs, timeIdxs, :), 1), 0, 4)./sqrt(size(data.SS, 4)), 2));

            legendTxt{cnd} = conditionsToPlot{cnd};

            if plotsPrms.Decibel 
                [chnsAvg, dcAvg] = WTProcessUtils.DCShiftAndConvertToDecibel(chnsAvg, plotsPrms.TransformPower);
                [chnsStdErr, dcStdErr] = WTProcessUtils.DCShiftAndConvertToDecibel(chnsStdErr, plotsPrms.TransformPower);

                dcShiftsTxt = {};
                if dcAvg > 0
                    dcShiftsTxt(end+1) = {sprintf('Avg: %g', dcAvg)};
                end 
                if dcStdErr > 0
                    dcShiftsTxt(end+1) = {sprintf('SE: %g', dcStdErr)};
                end
                if ~isempty(dcShiftsTxt)
                    legendTxt{cnd} = sprintf('%s / DC shift %s', conditionsToPlot{cnd}, char(join(dcShiftsTxt,',')));
                end
            end

            errorbar(chnsAvg, chnsStdErr, colors(cnd));

            if cnd == 1
                hold('on');
            end

            if cnd == nConditionsToPlot
                legend(legendTxt{:});
                title(figureTitle, 'FontSize', 16, 'FontWeight','bold');
                set(gca, 'XTick', 1 : timePace/timeRes : length(timeIdxs))
                set(gca, 'XTickLabel', plotsPrms.TimeMin : timePace : plotsPrms.TimeMax);
                set(gca, 'XMinorTick', 'on', 'xgrid', 'on', 'YMinorTick','on',...
                    'ygrid', 'on', 'gridlinestyle', ':', 'YDIR', 'normal');
                axis('tight');
                xlabel('ms', 'FontSize', 12, 'FontWeight', 'bold');
                ylabel(yLabelParams.String, 'FontSize', 12, 'FontWeight', 'bold');
                hold('off');
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
    plotsPrms = WTConfigUtils.sigprocConfigPreset(wtProject.Config, ...
        wtProject.Config.ChannelsAverageStdErrPlots);

    if ~WTPlotsGUI.defineChansAvgStdErrPlotsSettings(plotsPrms, true, true, true, true)
        return
    end
    
    if ~plotsPrms.persist()
        wtProject.notifyErr([], 'Failed to save channels average with stderr plots params');
        return
    end

    wtProject.Config.ChannelsAverageStdErrPlots = plotsPrms;
    success = true;
end
