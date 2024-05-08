% wtAvgPlots.m
% Created by Eugenio Parise
% CDC CEU 2010 - 2011
% Based on topmontageplot.m Written by Morten Moerup (ERPWAVELABv1.1)
% One line of code has been taken from Luca Filippin's EGIWaveletPlot.m
% Plots the time-frequency activity of the 3-way array WT in the
% correct position according to each channels topographic location.
% Datafile are located in the folder 'grand', already separated by
% condition, baseline corrected and chopped.
% Add 'evok' as last argument to plot evoked oscillations
% (of course if they have been previously computed).
% DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
% Interactive user interface needs inputgui.m from EEGLab.
%
% Usage:
%
% contr=0, no contours will be plotted; set to 1 to plot them.
%
% wtAvgPlots(subj,tMin,tMax,FrMin,FrMax,scale);
% wtAvgPlots(subj,tMin,tMax,FrMin,FrMax,scale,'evok');
%
% wtAvgPlots('01',-200,1200,10,90,[-0.5 0.5],1); %to plot a single subject
%
% wtAvgPlots('grand',-200,1200,10,90,[-0.5 0.5],0); %to plot the grand average
%
% wtAvgPlots('grand',-200,1200,10,90,[-0.5 0.5],0,'evok'); %to plot the grand
% average of evoked oscillations
%
% wtAvgPlots(); to run via GUI

% Now isempty(subject) => grand average
%     isempty(conditionsToPlot) => all conditions
%     isempty(channelsToPlot) => all channels

function wtAvgPlots(subject, conditionsToPlot, channelsToPlot, evokedOscillations)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkWaveletAnalysisDone() 
        return
    end

    interactive = wtProject.Interactive;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 4);
        WTValidations.mustBeAStringOrChar(subject);
        WTValidations.mustBeALinearCellArrayOfString(conditionsToPlot);
        WTValidations.mustBeALinearCellArrayOfString(channelsToPlot);
        subject = char(subject);
        conditionsToPlot = unique(conditionsToPlot);
        channelsToPlot = unique(channelsToPlot);
    end
    
    logFlag = wtProject.Config.WaveletTransform.LogarithmicTransform || ...
        wtProject.Config.BaselineChop.Log10Enable;

    if interactive
        [fileNames, ~, measure, subject] = WTPlotsGUI.selectFilesToPlot(false, false, -1);
        if isempty(fileNames)
            return
        end
        if ~setAvgPlotsParams(logFlag) 
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
    if ~success || ~WTConfigUtils.adjustTimeFreqDomains(wtProject.Config.AveragePlots, data) 
        return
    end

    plotsPrms = wtProject.Config.AveragePlots;
    timeRes = data.tim(2) - data.tim(1); 
    downsampleFactor = WTUtils.ifThenElse(timeRes <= 1, 4, @()WTUtils.ifThenElse(timeRes <= 2, 2, 1)); % apply downsampling to speed up plotting
    timeIdxs = find(data.tim == plotsPrms.TimeMin) : downsampleFactor : find(data.tim == plotsPrms.TimeMax);
    freqIdxs = find(data.Fa == plotsPrms.FreqMin) : find(data.Fa == plotsPrms.FreqMax);
    allChannelsLabels = {data.chanlocs.labels}';

    if plotsPrms.AllChannels
        if ~interactive && numel(channelsToPlot) > 0
            wtLog.warn('All channels will be plotted: subset ignored: %s', char(join(channelsToPlot, ','))); 
        end
        channelsToPlot = allChannelsLabels;
        channelsToPlotIdxs = 1:numel(allChannelsLabels);
    elseif interactive 
        [channelsToPlot, channelsToPlotIdxs] = WTUtils.stringsSelectDlg('Select channels\nto plot:', allChannelsLabels, false, true);
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

    nChannelsToPlot = numel(channelsToPlot);
    wtLog.info('Plotting %s...', WTUtils.ifThenElse(grandAverage, 'grand average', @()sprintf('subject %s', subject)));
    wtLog.pushStatus().HeaderOn = false;
    mainPlots = [];
   
    try
        % The annotation text's height which will appear on the top left corner
        channelAnnotationHeight = 0.05; 
        % The width / height ratio of the main figure
        figureWHRatio = 1; 
        figuresPosition = WTPlotUtils.getFiguresPositions(nConditionsToPlot, figureWHRatio, 0.3, 0.1);
        % Create struct to store all the useful params used here and by the callbacks
        prms = struct();
        prms.timeIdxs = timeIdxs;
        prms.freqIdxs = freqIdxs;
        prms.timeRes = timeRes;
        prms.downsampleFactor = downsampleFactor;
        prms.channelsToPlotIdxs = channelsToPlotIdxs;
        prms.plotsPrms = copy(plotsPrms);
        prms.subPlotRelWidth = 0.1;
        prms.subPlotRelHeight = prms.subPlotRelWidth * 3/4;
        prms.xLabel = WTPlotUtils.getXLabelParams(logFlag);
        prms.colorMap =  WTPlotUtils.getPlotsColorMap();
        
        for cnd = 1: nConditionsToPlot
            wtLog.contextOn().info('Condition %s', conditionsToPlot{cnd});

            [success, data] = WTMiscUtils.loadData(false, subject, conditionsToPlot{cnd}, measure);
            if ~success
                wtLog.contextOff();
                continue
            end 

            figureName = WTUtils.ifThenElse(grandAverage, ...
                @()char(strcat(basicPrms.FilesPrefix,'.[AVG].[', conditionsToPlot{cnd}, '].[', measure, ']')), ...
                @()char(strcat(basicPrms.FilesPrefix, '.[SBJ:', subject, '].[', conditionsToPlot{cnd}, '].[', measure, ']')));
            
           % Convert the data back to non-log scale straight in percent change in case logFlag is set
            prms.WT = WTUtils.ifThenElse(logFlag, @()100 * (10.^data.WT - 1), data.WT);
            prms.channelsLocations = data.chanlocs(channelsToPlotIdxs);

            [prms.x, prms.y] = WTPlotUtils.getChannelsXY(prms.channelsLocations);
            prms.xMin = min(prms.x);
            prms.yMin = min(prms.y);
            prms.xMax = max(prms.x);
            prms.yMax = max(prms.y);
            prms.subPlotRelHeight = prms.subPlotRelHeight * figureWHRatio;
            prms.xAirToEdge = 1 / 50; % air to edge of plot
            prms.yAirToEdge = figureWHRatio / 50; % air to edge of plot
            xSpanRel = 1 - 2 * prms.xAirToEdge - prms.subPlotRelWidth;
            ySpanRel = 1 - 2 * prms.yAirToEdge - prms.subPlotRelHeight - channelAnnotationHeight;
            xSpan = WTUtils.ifThenElse(prms.xMax == prms.xMin, 1, prms.xMax - prms.xMin);
            ySpan = WTUtils.ifThenElse(prms.yMax == prms.yMin, 1, prms.yMax - prms.yMin);
            xBottomLeftCorner = prms.xAirToEdge + ((prms.x - prms.xMin) / xSpan) * xSpanRel;
            yBottomLeftCorner = prms.yAirToEdge + ((prms.y - prms.yMin) / ySpan) * ySpanRel;
            xCenter = xBottomLeftCorner + (prms.subPlotRelWidth / 2);
            yCenter = yBottomLeftCorner + (prms.subPlotRelHeight / 2);

            % Create the main figure & add shared user data
            hFigure = figure('Position', figuresPosition{cnd});
            mainPlots(end+1) = hFigure;
            colormap(prms.colorMap);    
            hFigure.Name = figureName;
            hFigure.NumberTitle = 'off';
            hFigure.ToolBar = 'none';
            hFigure.Color = [1 1 1];
            hFigure.PaperUnits = 'centimeters';
            hFigure.PaperType = '<custom>';
            hFigure.PaperPosition = [0 0 12 12];
            % Create axes for the main figure
            hFigureAxes = axes('position', [0 0 1 1]);
            hFigureAxes.Visible = 'off';
            % Create label which displays the sub plot name when hovering on it with the mouse
            hWhichSubPlotAnnotation = annotation('textbox', [0.9, 0.95 .09 channelAnnotationHeight]);
            hWhichSubPlotAnnotation.Color = [1 0 0];
            hWhichSubPlotAnnotation.String = '';
            hWhichSubPlotAnnotation.EdgeColor = 'none';
            hWhichSubPlotAnnotation.HorizontalAlignment = 'right';
            hWhichSubPlotAnnotation.VerticalAlignment = 'middle';
            hWhichSubPlotAnnotation.FontName = 'Courier';
            hWhichSubPlotAnnotation.FontSize = 15;
            hWhichSubPlotAnnotation.FontWeight = 'bold';
            % Add user data
            hFigure.UserData.OpenSubPlots = [];
            hFigure.UserData.SubPlotsAxes = [];
            hFigure.UserData.SubPlotAnnotation = hWhichSubPlotAnnotation;
            hFigure.UserData.SubPlotAxesCenter = [xCenter' yCenter'];
            hFigure.UserData.onButtonDownCbPrms = prms;

            % Set the callback to display the subPlot label as cursor info
            for chn = 1:nChannelsToPlot
                channelLabel = prms.channelsLocations(chn).labels;  
                wtLog.contextOn().dbg('Channel %s', channelLabel);
                % Create axes for each channel: axes(x,y, xWidth, yWidth) (original below) 
                axesPosition = [xBottomLeftCorner(chn), yBottomLeftCorner(chn), prms.subPlotRelWidth, prms.subPlotRelHeight];
                hSubPlotAxes = axes('Position', axesPosition);
                % Set axes user data that will be used for resizing the  plot via +/- keypress
                hSubPlotAxes.UserData.OriginalPosition = axesPosition;
                hSubPlotAxes.UserData.ChannelLabel = channelLabel;
                hFigure.UserData.SubPlotsAxes = [hFigure.UserData.SubPlotsAxes hSubPlotAxes];
                hold('on');        
                imagesc(squeeze(prms.WT(channelsToPlotIdxs(chn), freqIdxs, timeIdxs)));
                clim(plotsPrms.Scale);
                axis('off');
                text(0, 0, channelLabel, 'FontSize', 8, 'FontWeight', 'bold');
                hold('off');   
                wtLog.contextOff();     
            end

            % Set the callback to keep the window size ratio constant
            hFigure.SizeChangedFcn = {@WTPlotUtils.keepWindowSizeRatioCb, figureWHRatio};
            % Set the callback to close open subplots when the master figure closes
            hFigure.CloseRequestFcn = {@WTPlotUtils.parentObjectCloseRequestCb, 'OpenSubPlots'};
            % Set the callback to display subplots
            hFigure.WindowButtonDownFcn = @mainPlotOnButtonDownCb;
            % Set the callback to resize/rearrange subplots 
            hFigure.WindowKeyPressFcn = WTPlotUtils.composeGraphicCallbacks(...
                {@WTPlotUtils.onKeyPressResizeObjectsCb, 'SubPlotsAxes', 'OriginalPosition'}, ...
                {@WTPlotUtils.onKeyPressResetObjectsPositionCb, 'OpenSubPlots',  'OriginalPosition'});
            hFigure.WindowScrollWheelFcn = {@WTPlotUtils.onMouseScrollResizeObjectsCb, ...
                'SubPlotsAxes', 'OriginalPosition'};
            % Set the callback to display sub plot lable when mouse hover on it
            hFigure.WindowButtonMotionFcn = {@WTPlotUtils.onMouseOverSubObjectsDoCb, ...
                'SubPlotAxesCenter', 'SubPlotsAxes', @setSubPlotAnnotationSetCb};

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

function setSubPlotAnnotationSetCb(hObject, hSubObject, subObjIdx) 
    newAnnotatonString = WTUtils.ifThenElse(isempty(hSubObject), '', @()hSubObject.UserData.ChannelLabel); 
    hAnnotation = hObject.UserData.SubPlotAnnotation;
    if ~strcmp(hAnnotation.String, newAnnotatonString)
        hAnnotation.String = newAnnotatonString;
        drawnow();
    end
end

function mainPlotOnButtonDownCb(hMainPlot, event)
    try
        prms = hMainPlot.UserData.onButtonDownCbPrms;
        plotsPrms = prms.plotsPrms;
        
        % Check if the click point falls into the axes extent, if not quit 
        [subPlotIdx, clickPosRelToAxes] = WTPlotUtils.getClickedSubObjectIndex(hMainPlot, hMainPlot.UserData.SubPlotAxesCenter);
        subPlotAxesPos = hMainPlot.UserData.SubPlotsAxes(subPlotIdx).Position;
        clickPosRelToAxes = abs(clickPosRelToAxes);
        if clickPosRelToAxes(1) > subPlotAxesPos(3)/2 || ...
            clickPosRelToAxes(2) > subPlotAxesPos(4)/2
            return
        end

        % Check if the subPlot figure is already open (already clicked on), if yes, just focus on it...
        % This prevent to reopen many times the same plot and so clutter the screen with no use.
        figureTag = prms.channelsLocations(subPlotIdx).labels;
        openSubPlots = hMainPlot.UserData.OpenSubPlots;
        hFigure = openSubPlots(arrayfun(@(figure)strcmp(figure.Tag, figureTag),openSubPlots));
        if ~isempty(hFigure)
            figure(hFigure);
            return
        end
        
        % Determine position and size of the new subplot which opens on screen
        screenSize = get(groot, 'screensize');
        whScreenRatio =  screenSize(3)/screenSize(4);
        widthOnScreen = max(0.5 / sqrt(length(prms.x)), 0.15);
        heightOnScreen = widthOnScreen * whScreenRatio * subPlotAxesPos(4) / subPlotAxesPos(3);
        xSpan = WTUtils.ifThenElse(prms.xMax == prms.xMin, 1, prms.xMax - prms.xMin);
        ySpan = WTUtils.ifThenElse(prms.yMax == prms.yMin, 1, prms.yMax - prms.yMin);
        xOnScreen = (prms.x(subPlotIdx) - prms.xMin) / xSpan;
        yOnScreen = (prms.y(subPlotIdx) - prms.yMin) / ySpan;
        
        position = [ ...
            (xOnScreen * (1 - widthOnScreen) * screenSize(3)) + 1 ... 
            (yOnScreen * (1 - heightOnScreen) * screenSize(4)) + 1 ...
            (widthOnScreen * screenSize(3)) ...
            (heightOnScreen * screenSize(4)) ...
        ];

        figureName = sprintf('%s.%s', hMainPlot.Name, figureTag);
        hFigure = figure('NumberTitle', 'off', 'Name', figureName, 'ToolBar', 'none', 'Position', position);
        % Set the unique tag, so we can check if the figure has been already opened
        hFigure.Tag = figureTag;
        hMainPlot.UserData.OpenSubPlots = [openSubPlots hFigure];
        hFigure.CloseRequestFcn = {@WTPlotUtils.childObjectCloseRequestCb, 'MainPlot', 'OpenSubPlots'};
        % Save the original position and the main plot handle in the UserData
        subPlotPrms = struct();
        subPlotPrms.MainPlot = hMainPlot;
        subPlotPrms.OriginalPosition = position;
        hFigure.UserData = subPlotPrms;

        colormap(prms.colorMap);
        imagesc([plotsPrms.TimeMin plotsPrms.TimeMax], [plotsPrms.FreqMin plotsPrms.FreqMax], ...
            interp2(squeeze(prms.WT(prms.channelsToPlotIdxs(subPlotIdx), prms.freqIdxs, prms.timeIdxs)), 4, 'spline'));
        hold('on');
        
        if plotsPrms.Contours
            timePace = prms.downsampleFactor * prms.timeRes;
            contour(plotsPrms.TimeMin:timePace:plotsPrms.TimeMax, ... 
                    plotsPrms.FreqMin:plotsPrms.FreqMax, ...
                    squeeze(prms.WT(subPlotIdx, prms.freqIdxs, prms.timeIdxs)), 'k');
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
        set(gca, 'xgrid', 'on', 'ygrid', 'on', 'gridlinestyle', '-', 'YDIR', 'normal', 'XTick', xTick, 'YTick', yTick);
        axis('tight');
        title(figureTag, 'FontSize', 16, 'FontWeight', 'bold');
        xlabel('ms', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Hz', 'FontSize', 12, 'FontWeight', 'bold');
        pace = linspace(min(plotsPrms.Scale), max(plotsPrms.Scale), 64);
        pace = pace(2) - pace(1);
        colorBar = colorbar('peer', gca, 'YTick', sort([0 plotsPrms.Scale]));
        set(get(colorBar, 'xlabel'), ...
            'String', prms.xLabel.String, ...
            'Rotation', prms.xLabel.Rotation, ...
            'Position', [prms.xLabel.Position 2 * pace], ...
            'FontSize', 12, 'FontWeight', 'bold'); 

        % Set the callback to manage grid style change
        hFigure.WindowButtonDownFcn = @WTPlotUtils.setAxesGridStyleCb;
    catch me
        WTLog().except(me);
    end  
end

 function success = setAvgPlotsParams(logFlag)
    success = false;
    wtProject = WTProject();
    plotsPrms = copy(wtProject.Config.AveragePlots);

    if ~WTPlotsGUI.defineAvgPlotsSettings(plotsPrms, logFlag)
        return
    end
    
    if ~plotsPrms.persist()
        wtProject.notifyErr([], 'Failed to save average plots params');
        return
    end

    wtProject.Config.AveragePlots = plotsPrms;
    success = true;
end