% smavr.m
% Created by Eugenio Parise
% CDC CEU 2011
% A small portion of code has been taken from pop_topoplot.m EEGLab fuction.
% One line of code has been taken from Luca Filippin's EGIWaveletPlot.m
% It plots 2D scalpmaps/scalpmap series of wavelet transformed EEG channels (for each condition).
% It uses topoplot function from EEGLab, so EEGLab must be installed and
% included in Matlab path.
% It can plot a single timepoint, the average of a time window, a series of time points, as well as a
% single frequency, an averaged frequency band or a series of frequencies.
%
% WARNING: it is not possible to plot simultaneously a time and a frequency series
% (e.g. tMintMax=[0:50:350],FrMinFrMax=[5:15]), either the time or the frequency
% series must be a single number (e.g. tMintMax=300) or a 2 numbers vector
% (e.g. FrMinFrMax=[10 50]). tMintMax and FrMinFrMax cannot be
% simultaneously more than 3 numbers.
% DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
% Interactive user interface needs inputgui.m from EEGLab.
%
% Add 'evok' as last argument to compute scalp maps of evoked
% oscillations (of course, if they have been previously computed).
%
% Usage:
%
% smavr(subj,tMintMax,FrMinFrMax,scale);
%
% smavr('01',800,15,[-0.2 0.2]); %to plot a single subject,
% at 800 ms and at 15 Hz
%
% smavr('05',[240 680],5,[-0.2 0.2]); %to plot a single subject,
% average between 240 and 680 ms at 5 Hz
%
% smavr('grand',350,[10 60],[-0.2 0.2]); %to plot the grand average,
% average between at 350 ms in the 10 to 60 Hz averaged band
%
% smavr('grand',[100 400],[10 60],[-0.2 0.2]); %to plot the grand average,
% average between 100 and 400 ms in the 10 to 60 Hz averaged band
%
% smavr('grand',[100 400],[7:12],[-0.2 0.2]); %to plot the grand average,
% average between 100 and 400 ms at 7, 8, 9, 10, 11, 12 Hz
%
% smavr('grand',[100:100:500],[7 12],[-0.2 0.2]); %to plot the grand average,
% average at 100, 200, 300, 400, 500 ms in the 7 to 12 Hz averaged band
%
% smavr('grand',[100:100:500],[7 12],[-0.2 0.2],'evok'); %to plot the grand average,
% average at 100, 200, 300, 400, 500 ms in the 7 to 12 Hz averaged band, of
% evoked oscillations
%
% smavr(); to run via GUI

function wt2DScalpMapPlots(subject, conditionsToPlot, evokedOscillations)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkWaveletAnalysisDone() 
        return
    end

    interactive = wtProject.Interactive;
    maxNumSubPlots = 100;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 3);
        WTValidations.mustBeAStringOrChar(subject);
        WTValidations.mustBeALimitedLinearCellArrayOfString(conditionsToPlot);
        subject = char(subject);
        conditionsToPlot = unique(conditionsToPlot);
    end
    
    logFlag = wtProject.Config.WaveletTransform.LogarithmicTransform || ...
        wtProject.Config.BaselineChop.Log10Enable;

    if interactive
        [fileNames, ~, measure, subject] = WTPlotsGUI.selectFilesToPlot(false, false, -1);
        if isempty(fileNames)
            return
        end
        if ~set2DScalpMapPlotsParams(logFlag, maxNumSubPlots) 
            return
        end
    else
        measure = WTUtils.ifThenElse(evokedOscillations, ...
            WTIOProcessor.WaveletsAnalisys_evWT,  WTIOProcessor.WaveletsAnalisys_avWT);
    end

    basicPrms = wtProject.Config.Basic;
    conditionsGrandPrms = wtProject.Config.ConditionsGrand;
    conditions = [conditionsGrandPrms.ConditionsList(:)' conditionsGrandPrms.ConditionsDiff(:)'];
    grandAverage = isempty(subject);

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

    [diffConsistency, grandConsistency] = WTMiscUtils.checkDiffAndGrandAvg(conditionsToPlot, grandAverage);
    if ~diffConsistency || ~grandConsistency
        return
    end

    [success, data] = WTMiscUtils.loadData(false, subject, conditionsToPlot{1}, measure);
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

    peripheralElectrodes = WTUtils.ifThenElse(plotsPrms.PeripheralElectrodes, 1, 0.5);
    contours = WTUtils.ifThenElse(plotsPrms.Contours, 6, 0);
    labels = WTUtils.ifThenElse(plotsPrms.ElectrodesLabel, 'labels', 'on');
    nSubPlots = WTUtils.ifThenElse(isempty(plotsPrms.TimeResolution), 1, length(timeIdxs));
    nSubPlots = WTUtils.ifThenElse(isempty(plotsPrms.FreqResolution), nSubPlots, length(freqIdxs));

    wtLog.info('Plotting %s...', WTUtils.ifThenElse(grandAverage, 'grand average', @()sprintf('subject %s', subject)));
    wtLog.pushStatus().HeaderOn = false;
    mainPlots = [];

    try
        % The width / height ratio of the main figure
        [figureRelWidth, figureWHRatio] = getMainFigureRelativeSize(nSubPlots);
        figuresPosition = WTPlotUtils.getFiguresPositions(nConditionsToPlot, figureWHRatio, figureRelWidth, 0.1, true);
        xLabel = WTPlotUtils.getXLabelParams(logFlag);
        channelAnnotationHeight = 0.05;

        if nSubPlots > 1
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
            prms.nSubPlotsGridRows = ceil(nSubPlots / prms.nSubPlotsGridCols);;
            prms.data = WTHandle(cell(1, nConditionsToPlot));
            prms.subPlotsPrms = WTHandle(cell(1, nSubPlots));
        end

        for cnd = 1:nConditionsToPlot
            wtLog.contextOn().info('Condition %s', conditionsToPlot{cnd});

            [success, data] = WTMiscUtils.loadData(false, subject, conditionsToPlot{cnd}, measure);
            if ~success
                wtLog.contextOff();
                continue
            end 

            figureNamePrefix = WTUtils.ifThenElse(grandAverage, ...
                @()char(strcat(basicPrms.FilesPrefix, '.[AVG].[', conditionsToPlot{cnd}, '].[', measure, ']')), ...
                @()char(strcat(basicPrms.FilesPrefix, '.[SBJ:', subject, '].[', conditionsToPlot{cnd}, '].[', measure, ']')));

            figureName = [figureNamePrefix '.[' plotsPrms.TimeString ' ms].[' plotsPrms.FreqString ' Hz]'];
            
            hFigure = figure('NumberTitle', 'off', ...
                'Name', figureName, 'ToolBar', 'none', 'Units', 'normalized', 'Position', figuresPosition{cnd});

            mainPlots(cnd) = hFigure;

            % Convert the data back to non-log scale straight in percent change in case logFlag is set
            data.WT = WTUtils.ifThenElse(logFlag, @()100 * (10.^data.WT - 1), data.WT);
            
            if isempty(plotsPrms.TimeResolution)
                % Average along times
                data.WT = mean(data.WT(:,:,timeIdxs), 3);
            end
            if isempty(plotsPrms.FreqResolution)
                % Average along frequencies
                data.WT = mean(data.WT(:,freqIdxs,:), 2);
            end
           
            if nSubPlots == 1
                WTUtils.eeglabRun(WTLog.LevelDbg, false, 'topoplot', ...
                        data.WT, data.chanlocs, 'electrodes', labels, 'maplimits', ...
                        plotsPrms.Scale, 'intrad', peripheralElectrodes,'numcontour', contours);
                pace = linspace(min(plotsPrms.Scale), max(plotsPrms.Scale), 64);
                pace = pace(2) - pace(1);
                colorBar = colorbar('peer', gca, 'YTick', sort([0 plotsPrms.Scale]));
                set(get(colorBar,'xlabel'), 'String', xLabel.String, 'FontSize', 12, ...
                    'FontWeight', 'bold', 'Rotation', xLabel.Rotation, 'Position', [xLabel.Position 2 * pace]);
            else
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
                    WTUtils.eeglabRun(WTLog.LevelDbg, false, 'topoplot', ...
                            subPlotData.data, data.chanlocs, 'electrodes', labels, 'maplimits',...
                            plotsPrms.Scale, 'intrad', peripheralElectrodes, 'numcontour', contours);
                    title(subPlotData.title, 'FontSize', 8, 'FontWeight', 'bold');
                    figure(hFigure);

                    subPlotTiles{i} = hSubPlotFigure;
                    prms.subPlotsPrms.Value{i} = subPlotData;
                end

                % Set main figure user data
                hFigure.UserData.OpenSubPlots = [];
                hFigure.UserData.Annotation = hWhichSubPlotAnnotation;
                hFigure.UserData.SubPlotsPolys = cellfun(@(x)[ x(1), x(1)+x(3), x(1)+x(3), x(1); x(2), x(2), x(2)+x(4), x(2)+x(4) ], ...
                    get([subPlotTiles{:}], 'position'), 'uniformoutput', false);
                % Set callbacks
                hFigure.CloseRequestFcn = {@WTPlotUtils.parentObjectCloseRequestCb, 'OpenSubPlots'};
                hFigure.WindowButtonDownFcn = {@mainPlotOnButtonDownCb, prms};
                hFigure.WindowKeyPressFcn = {@WTPlotUtils.onKeyPressResetObjectsPositionCb, 'OpenSubPlots',  'OriginalPosition'};
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
    WTPlotUtils.waitUIs(mainPlots);
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
    maxSubPlotWidth = WTUtils.ifThenElse(nSubPlots == 1, screenSize(3)/3, screenSize(3)/6);
    nSubPlotsGridCols = ceil(sqrt(nSubPlots));
    width = screenSize(3) / nSubPlotsGridCols;
    relWidth = WTUtils.ifThenElse(width < maxSubPlotWidth, 1, ...
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

function bringSubPlotsToFront(hMainPlot)
    subPlots = hMainPlot.UserData.OpenSubPlots;
    for i=1:length(subPlots)
        if isvalid(subPlots(i))
            figure(subPlots(i));
        end
    end
end

function mainPlotOnButtonDownCb(hMainPlot, ~, prms)
    try
        hGraphicObject = gca;
        if ~isfield(hGraphicObject.UserData, 'FigureSubPlotIdx')
            figure(hMainPlot);
            return
        end
        % If the click of the mouse is off any sub plot, gca returns the main plot current axes.
        % In such case we want to avoid opening the corresponding sub-plot so we have to check 
        % if the position of the moouse is inside the gca object. If not, we return.
        if hGraphicObject == hMainPlot.CurrentAxes && ...
            ~WTPlotUtils.isPointInCurrentAxes(hMainPlot.CurrentPoint)
            return
        end

        subPlotIdx = hGraphicObject.UserData.FigureSubPlotIdx;
        % Determine if the subPlot has been already drawed, in which case put it in foreground and exit
        openSubPlots = hMainPlot.UserData.OpenSubPlots;
        figureTag = [ 'SubPlot.' num2str(subPlotIdx) ];
        hFigure = openSubPlots(arrayfun(@(figure)strcmp(figure.Tag, figureTag), openSubPlots));
        if ~isempty(hFigure)
            bringSubPlotsToFront(hMainPlot);
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
        hFigure.CloseRequestFcn = {@WTPlotUtils.childObjectCloseRequestCb, 'MainPlot', 'OpenSubPlots'};
        subPlotPrms = struct();
        subPlotPrms.MainPlot = hMainPlot;
        subPlotPrms.OriginalPosition = subPlotPosition;
        hFigure.UserData = subPlotPrms;

        scale = prms.plotsPrms.Scale;
        xLabel = prms.xLabel;

        WTUtils.eeglabRun(WTLog.LevelDbg, false, 'topoplot', ...
                subPlotData.data, data.chanlocs, 'electrodes', prms.labels, 'maplimits', ...
                scale, 'intrad', prms.peripheralElectrodes, 'numcontour', prms.contours);

        pace = linspace(min(scale), max(scale), 64);
        pace = pace(2) - pace(1);
        colorBar = colorbar('peer', gca, 'YTick', sort([0 scale]));
        
        set(get(colorBar,'xlabel'), 'String', ...
            xLabel.String, 'Rotation', xLabel.Rotation, 'FontSize', 12, ...
            'FontWeight', 'bold', 'Position', [xLabel.Position 2 * pace]);

        set(colorBar, 'visible', 'on');
        title(subPlotData.title, 'FontSize', 12, 'FontWeight', 'bold');

        % Bring all open subplots to front
        bringSubPlotsToFront(hMainPlot);
    catch me
        WTLog().except(me);
    end 
end

function success = set2DScalpMapPlotsParams(logFlag, maxNumSubPlots)
    success = false;
    wtProject = WTProject();
    plotsPrms = copy(wtProject.Config.TwoDimensionalScalpMapPlots);

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
