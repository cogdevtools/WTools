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

function wt2DScalpMapPlots(subject, conditionsToPlot, evokedOscillations)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkChopAndBaselineCorrectionDone() 
        return
    end

    interactive = wtProject.Interactive;
    maxNumSubPlots = 100;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 3);
        WTValidations.mustBeStringOrChar(subject);
        WTValidations.mustBeLimitedLinearCellArrayOfChar(conditionsToPlot);
        subject = char(subject);
        conditionsToPlot = unique(conditionsToPlot);
    end
    
    waveletTransformPrms = wtProject.Config.WaveletTransform;
    baselineChopPrms = wtProject.Config.BaselineChop;
    logFlag = waveletTransformPrms.LogarithmicTransform || baselineChopPrms.LogarithmicTransform;
    evokFlag = waveletTransformPrms.EvokedOscillations;

    if interactive
        [fileNames, ~, measure, subject] = WTPlotsGUI.selectFilesToPlot(evokFlag, false, false, -1);
        if isempty(fileNames)
            return
        end
    end

    grandAverage = isempty(subject);
    if grandAverage && ~wtProject.checkGrandAverageDone()
        return
    end

    if interactive
        if ~set2DScalpMapPlotsParams(logFlag, maxNumSubPlots) 
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
    if ~success || ~WTConfigUtils.adjustPacedTimeFreqDomains(wtProject.Config.TwoDimensionalScalpMapPlots, data) 
        return
    end

    plotsPrms = wtProject.Config.TwoDimensionalScalpMapPlots;

    if ~isempty(plotsPrms.TimeResolution)
        downsampleFactor = floor(plotsPrms.TimeResolution / (data.tim(2) - data.tim(1)));
        timeIdxs = find(data.tim == plotsPrms.TimeMin) : downsampleFactor : find(data.tim == plotsPrms.TimeMax);
        n = length(timeIdxs);
        if n > maxNumSubPlots
            wtProject.notifyWrn([],'Too long time serie: can''t manage efficiently %d plots (max %d)', n, maxNumSubPlots);
            return
        end
    elseif ~isempty(plotsPrms.TimeMax)
        timeIdxs = find(data.tim == plotsPrms.TimeMin) : find(data.tim == plotsPrms.TimeMax);
    else 
        timeIdxs = find(data.tim == plotsPrms.TimeMin);
    end

    if ~isempty(plotsPrms.FreqResolution)
        downsampleFactor = floor(plotsPrms.FreqResolution / (data.Fa(2) - data.Fa(1)));
        freqIdxs = find(data.Fa == plotsPrms.FreqMin) : downsampleFactor : find(data.Fa == plotsPrms.FreqMax);
        n = length(freqIdxs);
        if n > maxNumSubPlots
            wtProject.notifyWrn([],'Too long frequency serie: can''t manage efficiently %d plots (max %d)', n, maxNumSubPlots);
            return
        end
    elseif ~isempty(plotsPrms.FreqMax)
        freqIdxs = find(data.Fa == plotsPrms.FreqMin) : find(data.Fa == plotsPrms.FreqMax);
    else 
        freqIdxs = find(data.Fa == plotsPrms.FreqMin);
    end

    peripheralElectrodes = WTCodingUtils.ifThenElse(plotsPrms.PeripheralElectrodes, 1, 0.5);
    contours = WTCodingUtils.ifThenElse(plotsPrms.Contours, 6, 0);
    labels = WTCodingUtils.ifThenElse(plotsPrms.ElectrodesLabel, 'labels', 'on');
    nSubPlots = WTCodingUtils.ifThenElse(isempty(plotsPrms.TimeResolution), 1, length(timeIdxs));
    nSubPlots = WTCodingUtils.ifThenElse(isempty(plotsPrms.FreqResolution), nSubPlots, length(freqIdxs));

    wtLog.info('Plotting %s...', WTCodingUtils.ifThenElse(grandAverage, 'grand average', @()sprintf('subject %s', subject)));
    wtLog.pushStatus().HeaderOn = false;
    hMainPlots = WTHandle(cell(1, nConditionsToPlot));

    try
        % The width / height ratio of the main figure
        [figureRelWidth, figureWHRatio] = getMainFigureRelativeSize(nSubPlots);
        figuresPosition = WTPlotUtils.getFiguresPositions(nConditionsToPlot, figureWHRatio, figureRelWidth, 0.1, true);
        xLabel = WTPlotUtils.getXLabelParams(logFlag);
        channelAnnotationHeight = 0.05;
        colorMap = WTPlotUtils.getPlotsColorMap(); 
        serialPlots = ~isempty(plotsPrms.TimeResolution) || ~isempty(plotsPrms.FreqResolution);

        if serialPlots
            % Create struct to store all the useful params used here and by the callbacks
            prms = struct();
            prms.whSubPlotRatio = 1;
            prms.plotsPrms = copy(plotsPrms);
            prms.xLabel = xLabel;
            prms.contours = contours;
            prms.labels = labels;
            prms.peripheralElectrodes = peripheralElectrodes;
            prms.nSubPlots = nSubPlots;
            prms.nSubPlotsGridCols = ceil(sqrt(nSubPlots));
            prms.nSubPlotsGridRows = ceil(nSubPlots / prms.nSubPlotsGridCols);
            prms.colorMap = colorMap;
        end

        for cnd = 1:nConditionsToPlot
            wtLog.contextOn().info('Condition %s', conditionsToPlot{cnd});

            [success, data] = WTProcessUtils.loadAnalyzedData(false, subject, conditionsToPlot{cnd}, measure);
            if ~success
                wtLog.contextOff();
                continue
            end 

            figureNamePrefix = WTCodingUtils.ifThenElse(grandAverage, ...
                @()char(strcat(basicPrms.FilesPrefix, '.[AVG].[', conditionsToPlot{cnd}, '].[', measure, ']')), ...
                @()char(strcat(basicPrms.FilesPrefix, '.[SBJ:', subject, '].[', conditionsToPlot{cnd}, '].[', measure, ']')));

            figureName = [figureNamePrefix '.[' plotsPrms.TimeString ' ms].[' plotsPrms.FreqString ' Hz]'];
            
            
            hFigure = figure('NumberTitle', 'off', ...
                'Name', figureName, 'ToolBar', 'none', 'Units', 'normalized', 'Position', figuresPosition{cnd});

            hMainPlots.Value{cnd} = hFigure;

            % Convert the data back to non-log scale straight in percent change in case logFlag is set
            data.WT = WTCodingUtils.ifThenElse(logFlag, @()100 * (10.^data.WT - 1), data.WT);
            
            if isempty(plotsPrms.TimeResolution)
                % Average along times
                data.WT = mean(data.WT(:,:,timeIdxs), 3);
            end
            if isempty(plotsPrms.FreqResolution)
                % Average along frequencies
                data.WT = mean(data.WT(:,freqIdxs,:), 2);
            end
           
            if ~serialPlots
                WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'topoplot', ...
                        data.WT, data.chanlocs, 'electrodes', labels, 'maplimits', ...
                        plotsPrms.Scale, 'intrad', peripheralElectrodes,'numcontour', contours);
                colormap(colorMap);
                pace = linspace(min(plotsPrms.Scale), max(plotsPrms.Scale), 64);
                pace = pace(2) - pace(1);
                colorBar = colorbar('peer', gca, 'YTick', sort([0 plotsPrms.Scale]));
                set(get(colorBar,'xlabel'), 'String', xLabel.String, 'FontSize', 12, ...
                    'FontWeight', 'bold', 'Rotation', xLabel.Rotation, 'Position', [xLabel.Position 2 * pace]);
            else
                prms.data = WTHandle(cell(1, nConditionsToPlot));
                prms.subPlotsPrms = WTHandle(cell(1, nSubPlots));

                % Set annotation for multi-plots case
                hWhichSubPlotAnnotation = annotation('textbox',[0.9, 0.95 .09 channelAnnotationHeight]);
                hWhichSubPlotAnnotation.Color = [1 0 0];
                hWhichSubPlotAnnotation.String = '';
                hWhichSubPlotAnnotation.EdgeColor = 'none';
                hWhichSubPlotAnnotation.HorizontalAlignment = 'right';
                hWhichSubPlotAnnotation.VerticalAlignment = 'middle';
                hWhichSubPlotAnnotation.FontName = 'Courier';
                hWhichSubPlotAnnotation.FontSize = 15;
                hWhichSubPlotAnnotation.FontWeight = 'bold';
                
                prms.data.Value{cnd} = data;
                subPlotTiles = cell(1, nSubPlots);
                wtLog.contextOn();

                for i = 1:nSubPlots        
                    subPlotData = struct();
                    subPlotData.conditionIdx = cnd;

                    % It's either one or the other condition
                    if ~isempty(plotsPrms.TimeResolution)
                        timeLabel = num2str(data.tim(timeIdxs(i)));
                        subPlotData.figureName = [figureNamePrefix '.[' timeLabel ' ms].[' plotsPrms.FreqString ' Hz]' ];
                        subPlotData.title = [timeLabel ' ms'];
                        subPlotData.data = data.WT(:,:,timeIdxs(i));
                        wtLog.dbg('Plotting time %s ms', timeLabel);
                    elseif ~isempty(plotsPrms.FreqResolution)  % redundant check
                        freqLabel = num2str(data.Fa(freqIdxs(i)));
                        subPlotData.figureName = [figureNamePrefix '.[' plotsPrms.TimeString ' ms].[' freqLabel ' Hz]'];
                        subPlotData.title = [freqLabel ' Hz'];
                        subPlotData.data = data.WT(:,freqIdxs(i),:);
                        wtLog.dbg('Plotting frequency %s Hz', freqLabel);
                    end

                    % Speed up sub plot tiles creation
                    hFigure.NextPlot = 'new';
                    hSubPlotFigure = subplot(prms.nSubPlotsGridRows, prms.nSubPlotsGridCols, i, 'Parent', hFigure);

                    hSubPlotFigure.UserData = struct('FigureSubPlotIdx', i);
                    WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'topoplot', ...
                            subPlotData.data, data.chanlocs, 'electrodes', labels, 'maplimits',...
                            plotsPrms.Scale, 'intrad', peripheralElectrodes, 'numcontour', contours);
                    colormap(colorMap);
                    title(subPlotData.title, 'FontSize', 8, 'FontWeight', 'bold');
                    figure(hFigure);

                    subPlotTiles{i} = hSubPlotFigure;
                    prms.subPlotsPrms.Value{i} = subPlotData;
                end

                % Set main figure user data
                hFigure.UserData.MainPlots = hMainPlots;
                hFigure.UserData.OpenSubPlots = [];
                hFigure.UserData.Annotation = hWhichSubPlotAnnotation;
                hFigure.UserData.SubPlotsPolys = cellfun(@(x)[ x(1), x(1)+x(3), x(1)+x(3), x(1); x(2), x(2), x(2)+x(4), x(2)+x(4) ], ...
                    cellfun(@(v)get(v,'position'), subPlotTiles, 'uniformoutput', false), 'uniformoutput', false);
                % Set callbacks
                hFigure.CloseRequestFcn = {@WTPlotUtils.parentObjectCloseRequestCb, 'OpenSubPlots'};
                hFigure.WindowButtonDownFcn = {@mainPlotOnButtonDownCb, prms};
                hFigure.WindowKeyPressFcn = WTPlotUtils.composeGraphicCallbacks(...
                    {@WTPlotUtils.onKeyPressResetObjectsPositionCb, 'r', 'OpenSubPlots', 'OriginalPosition'}, ...
                    {@WTPlotUtils.onKeyPressBringObjectsToFrontCb, 'a', 'MainPlots.Value'}, ...
                    {@WTPlotUtils.onKeyPressCloseObjectsCb, 'q', 'MainPlots.Value'}, ...
                    {@WTPlotUtils.onKeyPressSetObjectAndChildrenVisibilityCb, 'h', 's', 'MainPlots.Value', [], 'OpenSubPlots'});
                hFigure.WindowButtonMotionFcn = {@setSubPlotAnnotationSetCb, prms};
                wtLog.contextOff();
            end
            wtLog.contextOff();
        end
    catch me
        wtLog.except(me);
        wtLog.popStatus();
    end

    % Wait for all main plots to close
    WTPlotUtils.waitUIs(hMainPlots.Value);
    wtLog.info('Plotting done.');
end


function setSubPlotAnnotationSetCb(hMainPlot, ~, prms)
    cp = hMainPlot.CurrentPoint;
    polys = hMainPlot.UserData.SubPlotsPolys;
    in = cellfun(@(x)inpolygon(cp(1), cp(2), x(1,:)', x(2,:)'), polys);
    text = hMainPlot.UserData.Annotation.String;
    newText = '';

    if any(in) 
        subPlotData = prms.subPlotsPrms.Value{in};
        newText = subPlotData.title;
    end

    if ~strcmp(text, newText)
        hMainPlot.UserData.Annotation.String = newText;
        drawnow();
    end
end

function [relWidth, whRatio] = getMainFigureRelativeSize(nSubPlots)
    screenSize = get(groot, 'screensize');
    maxSubPlotWidth = WTCodingUtils.ifThenElse(nSubPlots == 1, screenSize(3)/3, screenSize(3)/6);
    nSubPlotsGridCols = ceil(sqrt(nSubPlots));
    width = screenSize(3) / nSubPlotsGridCols;
    relWidth = WTCodingUtils.ifThenElse(width < maxSubPlotWidth, 1, ...
        (maxSubPlotWidth * nSubPlotsGridCols) / screenSize(3));
    whRatio = screenSize(3)/screenSize(4);
end

function position = getSubPlotPosition(row, col, nGridRows, nGridCols, whRatio) 
    screenSize = get(groot, 'screensize');
    whScreenRatio = screenSize(3)/screenSize(4);

    if nGridCols * whScreenRatio / whRatio <= nGridRows
        widthOnScreen = 1 / nGridCols;
        heightOnScreen = (widthOnScreen * whScreenRatio) / whRatio;
        xOnScreen = 1 - widthOnScreen * (nGridCols - col + 1);
        yOnScreen = 1 - (1/nGridRows * row) + (1/nGridRows - heightOnScreen)/2; 
    else
        heightOnScreen = 1 / nGridRows;
        widthOnScreen = (heightOnScreen * whRatio) / whScreenRatio;
        xOnScreen = 1 - (1/nGridCols * (nGridCols - col + 1)) + (1/nGridCols - widthOnScreen)/2;
        yOnScreen = 1 - heightOnScreen * row;   
    end

    position = [ xOnScreen yOnScreen widthOnScreen heightOnScreen ];   
end

function mainPlotOnButtonDownCb(hMainPlot, ~, prms)
    try
        hGraphicObject = gca;
        openSubPlots = hMainPlot.UserData.OpenSubPlots;
        WTPlotUtils.bringObjectsToFront(openSubPlots);

        if ~isfield(hGraphicObject.UserData, 'FigureSubPlotIdx')
            figure(hMainPlot);
            return
        end
        % If the click of the mouse is off any sub plot, gca returns the main plot current axes.
        % In such case we want to avoid opening the corresponding sub-plot so we have to check 
        % if the position of the mouse is inside the gca object. If not, we return.
        if hGraphicObject == hMainPlot.CurrentAxes && ...
            ~WTPlotUtils.isPointInCurrentAxes(hMainPlot.CurrentPoint)
            return
        end

        subPlotIdx = hGraphicObject.UserData.FigureSubPlotIdx;
        % Determine if the subPlot has been already drawed, in which case put it in foreground and exit
        figureTag = [ 'SubPlot.' num2str(subPlotIdx) ];
        hFigure = openSubPlots(arrayfun(@(figure)strcmp(figure.Tag, figureTag), openSubPlots));
        if ~isempty(hFigure)
            return
        end
        % Determine position and size of the new subplot which opens on screen
        row = ceil(subPlotIdx / prms.nSubPlotsGridCols);
        col = subPlotIdx - (row-1) * prms.nSubPlotsGridCols;
        subPlotPosition = getSubPlotPosition(row, col, ...
            prms.nSubPlotsGridRows, prms.nSubPlotsGridCols, prms.whSubPlotRatio);
   
        subPlotData = prms.subPlotsPrms.Value{subPlotIdx};
        data = prms.data.Value{subPlotData.conditionIdx};

        
        hFigure = figure('NumberTitle', 'off', ...
            'Name', subPlotData.figureName, ...
            'ToolBar','none', ...
            'Units', 'normalized', ...
            'Position', subPlotPosition, ...
            'Tag', figureTag);

        hMainPlot.UserData.OpenSubPlots = [hMainPlot.UserData.OpenSubPlots hFigure];
       
        subPlotPrms = struct();
        subPlotPrms.MainPlot = hMainPlot;
        subPlotPrms.OriginalPosition = subPlotPosition;
        hFigure.UserData = subPlotPrms;

        scale = prms.plotsPrms.Scale;
        xLabel = prms.xLabel;

        WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'topoplot', ...
                subPlotData.data, data.chanlocs, 'electrodes', prms.labels, 'maplimits', ...
                scale, 'intrad', prms.peripheralElectrodes, 'numcontour', prms.contours);

        colormap(prms.colorMap);
        pace = linspace(min(scale), max(scale), 64);
        pace = pace(2) - pace(1);
        colorBar = colorbar('peer', gca, 'YTick', sort([0 scale]));
        
        set(get(colorBar,'xlabel'), 'String', ...
            xLabel.String, 'Rotation', xLabel.Rotation, 'FontSize', 12, ...
            'FontWeight', 'bold', 'Position', [xLabel.Position 2 * pace]);

        set(colorBar, 'visible', 'on');
        title(subPlotData.title, 'FontSize', 12, 'FontWeight', 'bold');
        hFigure.CloseRequestFcn = {@WTPlotUtils.childObjectCloseRequestCb, 'MainPlot', 'OpenSubPlots'};
        hFigure.WindowKeyPressFcn = {@WTPlotUtils.onKeyPressBringSingleObjectToFrontCb, 'm', 'MainPlot'};
    catch me
        WTLog().except(me);
    end 
end

function success = set2DScalpMapPlotsParams(logFlag, maxNumSubPlots)
    success = false;
    wtProject = WTProject();
    waveletTransformPrms = wtProject.Config.WaveletTransform;
    baselineChopPrms = wtProject.Config.BaselineChop;
    plotsPrms = copy(wtProject.Config.TwoDimensionalScalpMapPlots);

    if ~plotsPrms.exist()
        if waveletTransformPrms.exist()
            plotsPrms.Time = [waveletTransformPrms.TimeMin waveletTransformPrms.TimeMax];
            freqResolution = (waveletTransformPrms.FreqMax - waveletTransformPrms.FreqMin) / 10;
            plotsPrms.Frequency = [waveletTransformPrms.FreqMin freqResolution waveletTransformPrms.FreqMax];
        end
        if baselineChopPrms.exist()
            plotsPrms.Time = [baselineChopPrms.ChopTimeMin baselineChopPrms.ChopTimeMax];
        end
    end

    if ~WTPlotsGUI.define2DScalpMapPlotsSettings(plotsPrms, logFlag, maxNumSubPlots)
        return
    end
    
    if ~plotsPrms.persist()
        wtProject.notifyErr([], 'Failed to save 2D scalp map plots params');
        return
    end

    wtProject.Config.TwoDimensionalScalpMapPlots = plotsPrms;
    success = true;
end
