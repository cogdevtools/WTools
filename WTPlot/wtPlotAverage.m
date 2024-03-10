% wtPlotAverage.m
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
% wtPlotAverage(subj,tMin,tMax,FrMin,FrMax,scale);
% wtPlotAverage(subj,tMin,tMax,FrMin,FrMax,scale,'evok');
%
% wtPlotAverage('01',-200,1200,10,90,[-0.5 0.5],1); %to plot a single subject
%
% wtPlotAverage('grand',-200,1200,10,90,[-0.5 0.5],0); %to plot the grand average
%
% wtPlotAverage('grand',-200,1200,10,90,[-0.5 0.5],0,'evok'); %to plot the grand
% average of evoked oscillations
%
% wtPlotAverage(); to run via GUI

% Now isempty(subject) => grand average
%     isempty(conditionsToPlot) => all conditions
%     isempty(channelsToPlot) => all channels

function success = wtPlotAverage(subject, conditionsToPlot, channelsToPlot, evokedOscillations)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();

    interactive = wtProject.Interactive;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 4);
        WTValidations.mustBeAStringOrChar(subject);
        WTValidations.mustBeALimitedLinearCellArrayOfString(conditionsToPlot, 1, -1, 0);
        WTValidations.mustBeALinearCellArrayOfString(channelsToPlot);
        subject = char(subject);
        conditionsToPlot = unique(conditionsToPlot);
        channelsToPlot = unique(channelsToPlot);
        evokedOscillations = any(logical(evokedOscillations));
    end
    
    logFlag = wtCheckEvokLog();

    if interactive
        [fileNames, ~, measure, subject] = WTPlotsGUI.selectFilesToPlot();
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

    prefixPrms = wtProject.Config.Prefix;
    conditionsGrandPrms = wtProject.Config.ConditionsGrand;
    conditions = [conditionsGrandPrms.ConditionsList(:)' conditionsGrandPrms.ConditionsDiff(:)'];
    grandAverage = strcmp(subject, '');

    if interactive
        conditionsToPlot = extractConditionsFromFileNames(fileNames);
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
        wtProject.notifyWrn([], 'Plotting aborted due to empty conditions selection')
        return
    end

    [diffConsistency, grandConsistency] = wtCheckDiffAndGrandAvg(conditionsToPlot, grandAverage);
    if ~diffConsistency || ~grandConsistency
        return
    end

    [success, data] = loadDataToPlot(subject, conditionsToPlot{1}, measure);
    if ~success || ~correctAvgPlotParams(data) 
        return
    end

    plotsPrms = wtProject.Config.AveragePlots;
    timeRes = WTUtils.ifThenElse(length(data.tim) > 1, data.tim(2) - data.tim(1), 1); 
    downsampleFactor = WTUtils.ifThenElse(timeRes == 1, 4, timeRes); % apply downsampling to speed up plotting
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
        [channelsToPlot, channelsToPlotIdxs] = WTUtils.stringsSelectDlg('Select channels\nto cut:', allChannelsLabels, false, true);
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
        wtProject.notifyWrn([], "Plotting aborted due to empty channels selection");
        return
    end

    nChannelsToPlot = numel(channelsToPlot);
    wtLog.info('Plotting %s...', WTUtils.ifThenElse(grandAverage, 'grand average', sprintf('subject %s', subject)));
    wtLog.pushStatus().HeaderOn = false;
    wtWorspace = WTWorkspace();
    wtWorspace.pushBase()
    mainPlots = [];

    try
        % Create struct to store all the useful params used here and by the callbacks
        prms = struct();
        prms.timeIdxs = timeIdxs;
        prms.freqIdxs = freqIdxs;
        prms.downsampleFactor = downsampleFactor;
        prms.channelsToPlotIdxs = channelsToPlotIdxs;
        prms.plotsPrms = copy(plotsPrms);
        prms.width = 0.1;
        prms.height = 0.1;
        [prms.defaultColorMap,  prms.cLabel,  prms.rotation,  prms.xcLabel] = wtSetFigure(logFlag);

        for cnd = 1: nConditionsToPlot
            wtLog.contextOn().info('Condition %s', conditionsToPlot{cnd});
            [success, data] = loadDataToPlot(subject, conditionsToPlot{cnd}, measure);
            if ~success
                break
            end 

            figureName = WTUtils.ifThenElse(grandAverage, ...
                char(strcat(prefixPrms.FilesPrefix,'.[AVG].[', conditionsToPlot{cnd}, '].[', measure, ']')), ...
                char(strcat(prefixPrms.FilesPrefix,'.[SBJ:', subject, '].[', conditionsToPlot{cnd}, '].[', measure, ']')));
            
            % convert the data back to non-log scale straight in percent change in case logFlag is set
            prms.WT = WTUtils.ifThenElse(logFlag, 100 * (10.^data.WT - 1), data.WT);
            prms.channelsLocations = data.chanlocs(channelsToPlotIdxs);
            prms.x = [];
            prms.y = [];

            for k = 1:nChannelsToPlot
                if ~isempty(prms.channelsLocations(k).radius)
                    prms.x(end+1) = sin(prms.channelsLocations(k).theta / 360 * 2 * pi) * prms.channelsLocations(k).radius;
                    prms.y(end+1) = cos(prms.channelsLocations(k).theta / 360 * 2 * pi) * prms.channelsLocations(k).radius;
                end
            end

            prms.xMin = min(prms.x);
            prms.yMin = min(prms.y);
            prms.xMax = max(prms.x);
            prms.yMax = max(prms.y);
            prms.xAirToEdge = (prms.xMax - prms.xMin) / 50; % air to edge of plot
            prms.yAirToEdge = (prms.yMax - prms.yMin) / 50; % air to edge of plot
            prms.xM = prms.xMax - prms.xMin + prms.width;
            prms.yM = prms.yMax - prms.yMin + prms.height;
            xBottomLeftCorner = (prms.x - prms.xMin + prms.xAirToEdge) / (prms.xM + 2 * prms.xAirToEdge);
            yBottomLeftCorner = (prms.y - prms.yMin + prms.yAirToEdge) / (prms.yM + 2 * prms.yAirToEdge);
            xCenter = xBottomLeftCorner + prms.width / (2 * prms.xM);
            yCenter = yBottomLeftCorner + prms.height / (2 * prms.yM);
            prms.subPlotAxesCenter = [xCenter' yCenter'];

            % Create the main figure & add shared user data
            hFigure = figure();
            mainPlots(end+1) = hFigure;
            colormap(prms.defaultColorMap);    
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
            % Create label which display the sub plot name when hovering on it with the mouse
            hSubPlotHoveringAnnotation = annotation('textbox', [0.9, 0.95 .09 .05]);
            hSubPlotHoveringAnnotation.Color = [1 0 0];
            hSubPlotHoveringAnnotation.String = '';
            hSubPlotHoveringAnnotation.EdgeColor = 'none';
            hSubPlotHoveringAnnotation.HorizontalAlignment = 'right';
            hSubPlotHoveringAnnotation.VerticalAlignment = 'middle';
            hSubPlotHoveringAnnotation.FontName = 'Courier';
            hSubPlotHoveringAnnotation.FontSize = 15;
            hSubPlotHoveringAnnotation.FontWeight = 'bold';
            % Add user data
            hFigure.UserData = struct();
            hFigure.UserData.OpenSubPlots = [];
            hFigure.UserData.SubPlotsAxes = [];
            hFigure.UserData.SubPlotAnnotation = hSubPlotHoveringAnnotation;
            hFigure.UserData.onButtonDownCbPrms = prms;
            % Set the callback to close open subplots when the master figure closes
            hFigure.CloseRequestFcn = @mainPLotCloseReqeuestCb;
            % Set the callback to display subplots
            hFigure.WindowButtonDownFcn = @mainPlotOnButtonDownCb;
            % Set the callback to resize/rearrange subplots 
            hFigure.WindowKeyPressFcn = @mainPlotOnKeyPressCb;
            hFigure.WindowScrollWheelFcn = @mainPlotOnMouseScrollCb;
            % Set the callback to display sub plot lable when mouse hover on it
            hFigure.WindowButtonMotionFcn = @mainPlotOnMouseMotionCb;
            % Set the callback to display the subPlot label as cursor info
            
            for chn = 1:nChannelsToPlot  
                wtLog.contextOn().dbg('Channel %s', channelsToPlot{chn});
                % Create axes for each channel: axes(x,y, xWidth, yWidth) (original below) 
                axesPosition = [xBottomLeftCorner(chn), yBottomLeftCorner(chn), ...
                     prms.width / prms.xM, prms.height / prms.yM];
                hSubPlotAxes = axes('Position', axesPosition);
                % Set axes user data that will be used for resizing the  plot via +/- keypress
                hSubPlotAxes.UserData = struct();
                hSubPlotAxes.UserData.OriginalPosition = axesPosition;
                hFigure.UserData.SubPlotsAxes = [hFigure.UserData.SubPlotsAxes hSubPlotAxes];
                hold('on');        
                image = imagesc(squeeze(prms.WT(channelsToPlotIdxs(chn), freqIdxs, timeIdxs)));
                channelLabel = prms.channelsLocations(chn).labels;
                image.UserData = struct('ChannelLabel', channelLabel); % save channel label for data cursor mode
                clim(plotsPrms.Scale);
                axis('off');
                text(0, 0, channelLabel, 'FontSize', 8, 'FontWeight', 'bold');
                hold('off');   
                wtLog.contextOff();     
            end

            wtLog.contextOff();
        end
    catch me
        wtWorspace.popToBase();
        wtLog.except(me);
        wtLog.popStatus();
    end

    % Wait for all main plots to close
    waitUIs(mainPlots);
    wtLog.info('Plotting done.');
end

function waitUIs(UIs) 
    for i = 1:length(UIs)
        try
            uiwait(UIs(i));
        catch
        end
    end
end

% This callback function called when the master condition figure is closed, will perform the
% close of all open subplot related to the master figure
function mainPLotCloseReqeuestCb(hObject, event)
    try
        arrayfun(@(subPlot)subPlot.CloseRequestFcn(subPlot, event), hObject.UserData.OpenSubPlots);   
    catch me
        WTLog().except(me);
    end
    delete(hObject);
end

function subPlotResize(subPlotsAxes, incdec)
    for i = 1 : length(subPlotsAxes)
        spa = subPlotsAxes(i);
        position = spa.Position;
        origPosition = spa.UserData.OriginalPosition;
        origWidth = origPosition(3);
        origHeight = origPosition(4);
        tickWidth = origWidth / 20;
        tickHeight = origHeight / 20;

        switch incdec
            case '+'
                if position(3) <= origWidth - tickWidth 
                    position(1) = position(1) - tickWidth / 2;
                    position(2) = position(2) - tickHeight / 2;
                    position(3) = position(3) + tickWidth;
                    position(4) = position(4) + tickHeight;
                    spa.Position = position;
                end
            case '-'
                if position(3) >= 2 * tickWidth 
                    position(1) = position(1) + tickWidth / 2;
                    position(2) = position(2) + tickHeight / 2;
                    position(3) = position(3) - tickWidth;
                    position(4) = position(4) - tickHeight;
                    spa.Position = position;
                end
        end
    end
end

function mainPlotOnKeyPressCb(hObject, event)
    try
        switch event.Character
            case 'r' % rearrange open plots into the original opening position
                subPlots = hObject.UserData.OpenSubPlots;
                for i = 1:length(subPlots)
                    subPlots(i).Position = subPlots(i).UserData.OriginalPosition;
                end
            case '+'  
                subPlotResize(hObject.UserData.SubPlotsAxes, event.Character)
            case '-'
                subPlotResize(hObject.UserData.SubPlotsAxes, event.Character)
            otherwise
                return
        end
    catch me
        WTLog().except(me);
    end
end

function mainPlotOnMouseScrollCb(hObject, event) 
    try
        if event.VerticalScrollCount >= 1
            subPlotResize(hObject.UserData.SubPlotsAxes, '+')
        elseif event.VerticalScrollCount <= -1
            subPlotResize(hObject.UserData.SubPlotsAxes, '-')
        end
    catch me
        WTLog().except(me);
    end
end

% This function can be relative expensive, especially if called on mouse motion but havent found
% any better solution for such case...
function [subPlotIdx, clickPosRelToAxes] = getClickedSubPlotIndex(hMainPlot) 
    prms = hMainPlot.UserData.onButtonDownCbPrms;
    % Find the index of the sub plot to open, by min distance from the click point
    clickPoint = hMainPlot.CurrentPoint;
    mainPlotPosition = hMainPlot.Position;
    relClickPoint = clickPoint ./ mainPlotPosition(3:4);
    distance = sum((prms.subPlotAxesCenter - repmat(relClickPoint, [size(prms.subPlotAxesCenter,1), 1])) .^ 2, 2);
    [~, minDistanceAxesIdx] = min(distance);
    clickPosRelToAxes = abs(relClickPoint - prms.subPlotAxesCenter(minDistanceAxesIdx,:));
    % Check if the click point falls into the axes extent, if not quit 
    subPlotIdx = minDistanceAxesIdx;
end

function mainPlotOnMouseMotionCb(hMainPlot, ~) 
    try
        [subPlotIdx, clickPosRelToAxes] = getClickedSubPlotIndex(hMainPlot);
        subPlotAxesPos = hMainPlot.UserData.SubPlotsAxes(subPlotIdx).Position;
        annotation = hMainPlot.UserData.SubPlotAnnotation;
        if clickPosRelToAxes(1) > subPlotAxesPos(3)/2 || clickPosRelToAxes(2) > subPlotAxesPos(4)/2
            annotation.String = '';
        else
            prms = hMainPlot.UserData.onButtonDownCbPrms;
            annotation.String = prms.channelsLocations(subPlotIdx).labels;
        end
    catch me
        WTLog().except(me);
    end
end

function mainPlotOnButtonDownCb(hMainPlot, ~)
    try
        prms = hMainPlot.UserData.onButtonDownCbPrms;
        plotsPrms = prms.plotsPrms;
        
        % Check if the click point falls into the axes extent, if not quit 
        [subPlotIdx, clickPosRelToAxes] = getClickedSubPlotIndex(hMainPlot);
        subPlotAxesPos = hMainPlot.UserData.SubPlotsAxes(subPlotIdx).Position;
        if clickPosRelToAxes(1) > subPlotAxesPos(3)/2 || clickPosRelToAxes(2) > subPlotAxesPos(4)/2
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
        
        % Determine positiion and size of the subplot on screen
        sreenSize = get(groot, 'screensize');
        whScreenRatio =  sreenSize(3)/sreenSize(4);
        widthOnScreen = 0.15;
        heightOnScreen = widthOnScreen * whScreenRatio;
        xSpan = (prms.xMax - prms.xMin + widthOnScreen);
        ySpan = (prms.yMax - prms.yMin + heightOnScreen);
        xOnScreen = (prms.x(subPlotIdx) - prms.xMin) / xSpan;
        yOnScreen = (prms.y(subPlotIdx) - prms.yMin) / ySpan;

        position = [ ...
            (xOnScreen * sreenSize(3)) ... 
            (yOnScreen * sreenSize(4)) ...
            (widthOnScreen * sreenSize(3)) ...
            (heightOnScreen * sreenSize(4)) ...
        ];

        figureName = sprintf('%s.%s', hMainPlot.Name, figureTag);
        hFigure = figure('NumberTitle', 'off', 'Name', figureName, 'ToolBar', 'none', 'Position', position);
        % Set the unique tag, so we can check if the figure has been already opened
        hFigure.Tag = figureTag;
        hMainPlot.UserData.OpenSubPlots = [openSubPlots hFigure];
        hFigure.CloseRequestFcn = @subPlotCloseRequestCb;
        % Save the original position and the main plot handle in the UserData
        subPlotPrms = struct();
        subPlotPrms.MainPlot = hMainPlot;
        subPlotPrms.OriginalPosition = position;
        hFigure.UserData = subPlotPrms;
        % Set the callback to manage grid style change
        hFigure.WindowButtonDownFcn = @subPlotOnMouseButtonDownCb;

        colormap(prms.defaultColorMap);
        imagesc([plotsPrms.TimeMin plotsPrms.TimeMax], [plotsPrms.FreqMin plotsPrms.FreqMax], ...
            interp2(squeeze(prms.WT(prms.channelsToPlotIdxs(subPlotIdx), prms.freqIdxs, prms.timeIdxs)), 4, 'spline'));
        hold('on');
        
        if plotsPrms.Contours
            timePace = WTUtils.ifThenElse(prms.downsampleFactor == 4, 4, prms.downsampleFactor ^ 2);
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
        set(get(colorBar, 'xlabel'), 'String', prms.cLabel, 'Rotation', prms.rotation, 'FontSize', 12, 'FontWeight', 'bold', 'Position', [prms.xcLabel 2 * pace]); 
    catch me
        WTLog().except(me);
    end  
end

function subPlotCloseRequestCb(hObject, ~)
    try
        hMainPlot = hObject.UserData.MainPlot;
        if isvalid(hMainPlot)
            openSubPlots = hMainPlot.UserData.OpenSubPlots;
            figureIdx = arrayfun(@(figure)strcmp(figure.Tag, hObject.Tag), openSubPlots);
            hMainPlot.UserData.OpenSubPlots(figureIdx) = [];
        end
    catch me
        WTLog().except(me);
    end
    delete(hObject);
end

function subPlotOnMouseButtonDownCb(~, ~)
    try
        gridLineStyle = get(gca, 'gridlinestyle');
        switch gridLineStyle
            case '-'
                set(gca, 'xgrid', 'on', 'ygrid', 'on', 'gridlinestyle', '--');
            case '--'
                set(gca, 'xgrid', 'on', 'ygrid', 'on', 'gridlinestyle', ':');
            case ':'
                set(gca, 'xgrid', 'on', 'ygrid', 'on', 'gridlinestyle', 'none');
            case 'none'
                set(gca, 'xgrid', 'on', 'ygrid', 'on', 'gridlinestyle', '-');
        end
    catch me
        WTLog().except(me);
    end     
end

function conditions = extractConditionsFromFileNames(fileNames)
    conditions = cell(1, length(fileNames));
    for i = 1:length(fileNames) 
        [~, condition] = WTIOProcessor.splitBaselineCorrectedFileName(fileNames{i});
        conditions{i} = condition;
    end
end

function [success, data] = loadDataToPlot(subject, condition, measure) 
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;
    grandAverage = isempty(subject);

    if grandAverage
        [success, data] = ioProc.loadGrandAverage(condition, measure, false);
    else
        [success, data] = ioProc.loadBaselineCorrection(subject, condition, measure);
    end
    if ~success 
        wtProject.notifyErr([], 'Failed to load data for condition ''%s''', condition);
    end
end

% Adjust 'edge' to the closest value in the ORDERED vector 'values'.
function adjEdge = adjustEdge(edge, values)
    edgeL = values(find(values <= edge, 1, 'last'));
    edgeR = values(find(values >= edge, 1, 'first'));
    if isempty(edgeL)
        adjEdge = edgeR;
    elseif isempty(edgeR)
        adjEdge = edgeL;
    elseif edge - edgeL <= edgeR - edge
        adjEdge = edgeL;
    else 
        adjEdge = edgeR;
    end
end

function success = correctAvgPlotParams(data)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    
    plotParams = copy(wtProject.Config.AveragePlots);
    tMin = data.tim(1);
    tMax = data.tim(end);

    plotTimeMin = adjustEdge(plotParams.TimeMin, data.tim);
    if plotParams.TimeMin > tMax 
        wtLog.warn('Average plots param TimeMin auto-corrected to minimum sample time %d ms (was %d ms > maximum sample time)', plotTimeMin, plotParams.TimeMin);
    elseif plotTimeMin ~=  plotParams.TimeMin
        wtLog.warn('Average plots param TimeMin adjusted to closest sample time %d ms (was %d ms)', plotTimeMin, plotParams.TimeMin);
    end

    plotTimeMax = adjustEdge(plotParams.TimeMax, data.tim);
    if plotParams.TimeMax < tMin 
        wtLog.warn('Average plots param TimeMax auto-corrected to maximum sample time %d ms (was %d ms < minimum sample time)', plotTimeMax, plotParams.TimeMax);
    elseif plotTimeMin ~=  plotParams.TimeMin
        wtLog.warn('Average plots param TimeMax adjusted to closest sample time %d ms (was %d ms)', plotTimeMax, plotParams.TimeMax);
    end

    if plotTimeMin > plotTimeMax 
        wtProject.notifyErr([], 'Bad average plots range [TimeMin,TimeMax] = [%d,%d] after adjustments...', plotTimeMin, plotTimeMax);
        return
    end

    fMin = data.Fa(1);
    fMax = data.Fa(end);

    plotFreqMin = adjustEdge(plotParams.FreqMin, data.Fa);
    if plotParams.FreqMin > fMax 
        wtLog.warn('Average plots param FreqMin auto-corrected to minimum frequency %d Hz (was %d Hz > maximum frequency)', plotFreqMin, plotParams.FreqMin);
    elseif plotTimeMin ~=  plotParams.TimeMin
        wtLog.warn('Average plots param FreqMin adjusted to closest frequency %d Hz (was %d Hz)', plotFreqMin, plotParams.FreqMin);
    end

    plotFreqMax = adjustEdge(plotParams.FreqMax, data.Fa);
    if plotParams.FreqMax < fMin 
        wtLog.warn('Average plots param FreqMax auto-corrected to maximum frequency %d Hz (was %d Hz < minimum frequency)', plotFreqMax, plotParams.FreqMax);
    elseif plotTimeMin ~=  plotParams.TimeMin
        wtLog.warn('Average plots param FreqMax adjusted to closest frequency %d Hz (was %d Hz)', plotFreqMax, plotParams.FreqMax);
    end

    if plotFreqMin > plotFreqMax 
        wtProject.notifyErr([], 'Bad average plots range [FreqMin,FreqMax] = [%d,%d] after adjustments...', plotFreqMin, plotFreqMax);
        return
    end

    plotParams.TimeMin = plotTimeMin;
    plotParams.TimeMax = plotTimeMax;
    plotParams.FreqMin = plotFreqMin;
    plotParams.FreqMax = plotFreqMax;
    
    if ~plotParams.persist() 
        wtProject.notifyErr([], 'Failed to save average plots params');
        return
    end

    wtProject.Config.AveragePlots = plotParams;
    success = true;
end

 function success = setAvgPlotsParams(logFlag)
    success = false;
    logFlag = any(logical(logFlag));
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