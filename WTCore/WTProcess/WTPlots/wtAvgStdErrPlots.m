% wtAvgStdErrPlots.m
% Created by Eugenio Parise
% CDC CEU 2013
% Based on wtAvgPlots.m Written by Morten Moerup (ERPWAVELABv1.1)
% One line of code has been taken from Luca Filippin's EGIWaveletPlot.m
% Plots the time-frequency activity of a frequency band with Standard Error bars on top.
% Channels are plotted in the correct head position according to each channel
% topographic location.
% Datafile are located in the folder 'grand', already separated by
% condition, baseline corrected and chopped.
% Add 'evok' as last argument to plot evoked oscillations
% (of course if they have been previously computed).
% DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
% Interactive user interface needs inputgui.m from EEGLab.
%
% Usage:
%
% At present thgis function only works for grand average files, thus
% subj='grand'
%
% wtAvgStdErrPlots(subj,tMin,tMax,FrMin,FrMax);
% wtAvgStdErrPlots(subj,tMin,tMax,FrMin,FrMax,'evok');
%
% wtAvgStdErrPlots('grand',-200,1200,10,90); %to plot the grand average
%
% wtAvgStdErrPlots('grand',-200,1200,10,90,'evok'); %to plot the grand
% average of evoked oscillations
%
% wtAvgStdErrPlots(); to run via GUI

% Plots only the grand average (subject is not a parameter)
function wtAvgStdErrPlots(conditionsToPlot, channelsToPlot, evokedOscillations)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkWaveletAnalysisDone() 
        return
    end

    interactive = wtProject.Interactive;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 3);
        WTValidations.mustBeALimitedLinearCellArrayOfString(conditionsToPlot);
        WTValidations.mustBeALinearCellArrayOfString(channelsToPlot);
        conditionsToPlot = unique(conditionsToPlot);
        WTValidations.mustBeLTE(length(conditionsToPlot), 2); 
        channelsToPlot = unique(channelsToPlot);
    end
    
    logFlag = wtProject.Config.WaveletTransform.LogarithmicTransform || ...
        wtProject.Config.BaselineChop.Log10Enable;

    if interactive
        [fileNames, ~, measure] = WTPlotsGUI.selectFilesToPlot(true, true, 2);
        if isempty(fileNames)
            return
        end
        if ~setAvgStdErrPlotsParams() 
            return
        end
    else
        measure = WTUtils.ifThenElse(evokedOscillations, ...
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

    [diffConsistency, grandConsistency] = WTMiscUtils.checkDiffAndGrandAvg(conditionsToPlot, grandAverage);
    if ~diffConsistency || ~grandConsistency
        return
    end

    [success, data] = WTMiscUtils.loadData(true, subject, conditionsToPlot{1}, measure);
    if ~success || ~WTConfigUtils.adjustTimeFreqDomains(wtProject.Config.AverageStdErrPlots, data) 
        return
    end

    plotsPrms = wtProject.Config.AverageStdErrPlots;
    timeRes = WTUtils.ifThenElse(length(data.tim) > 1, @()data.tim(2) - data.tim(1), 1); 
    timeIdxs = find(data.tim == plotsPrms.TimeMin) : find(data.tim == plotsPrms.TimeMax);
    timeIdxsReduced = timeIdxs(1) : 10 : timeIdxs(end);
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
    wtLog.info('Plotting grand average & standard error...');
    wtLog.pushStatus().HeaderOn = false;
    mainPlots = [];    
        
    try
        % The annotation text's height which will appear on the top left corner
        channelAnnotationHeight = 0.05;
        % The width / height ratio of the main figure
        figureWHRatio = 1;
        figuresPosition = WTPlotUtils.getFiguresPositions(1, figureWHRatio, 0.3, 0.1);
        % Create struct to store all the useful params used here and by the callbacks
        prms = struct();
        prms.timeIdxs = timeIdxs;
        prms.freqIdxs = freqIdxs;
        prms.timeRes = timeRes;
        prms.conditionsToPlot = conditionsToPlot;
        prms.channelsToPlotIdxs = channelsToPlotIdxs;
        prms.plotsPrms = copy(plotsPrms);
        prms.subPlotRelWidth = 0.1;
        prms.subPlotRelHeight = prms.subPlotRelWidth * 3/4;
        prms.yLabel = WTPlotUtils.getYLabelParams(logFlag);
        prms.channelsLocations = data.chanlocs(channelsToPlotIdxs);

        % Determine sub plots images size and position within the main figure
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

        prms.data = cell(1, nConditionsToPlot);
        hPrms = WTHandle(prms);

        % Create main plot figure
        figureName = sprintf('%s.[%s].[%d-%d Hz]', basicPrms.FilesPrefix, measure, plotsPrms.FreqMin, plotsPrms.FreqMax); 
        hFigure = figure('Position', figuresPosition{1});
        mainPlots(end+1) = hFigure;  
        hFigure.Name = figureName;
        hFigure.NumberTitle = 'off';
        hFigure.ToolBar = 'none';
        hFigure.Color = [1 1 1];
        hFigure.PaperUnits = 'centimeters';
        hFigure.PaperType = '<custom>';
        hFigure.PaperPosition = [0 0 12 12];
        hFigureAxes = axes('position', [0 0 1 1]);
        hFigureAxes.Visible = 'off';

        % Create annotation to display channel label on mouse hovering
        hWhichSubPlotAnnotation = annotation('textbox', [0.9, 0.95 .09 channelAnnotationHeight]);
        hWhichSubPlotAnnotation.Color = [1 0 0];
        hWhichSubPlotAnnotation.String = '';
        hWhichSubPlotAnnotation.EdgeColor = 'none';
        hWhichSubPlotAnnotation.HorizontalAlignment = 'right';
        hWhichSubPlotAnnotation.VerticalAlignment = 'middle';
        hWhichSubPlotAnnotation.FontName = 'Courier';
        hWhichSubPlotAnnotation.FontSize = 15;
        hWhichSubPlotAnnotation.FontWeight = 'bold';

        % User data
        hFigure.UserData.OpenSubPlots = [];
        hFigure.UserData.SubPlotsAxes = [];
        hFigure.UserData.SubPlotAnnotation = hWhichSubPlotAnnotation;
        hFigure.UserData.SubPlotAxesCenter = [xCenter' yCenter'];
        hFigure.UserData.onButtonDownCbPrms = hPrms;

        for cnd = 1:nConditionsToPlot
            wtLog.contextOn().info('Condition %s', conditionsToPlot{cnd});

            [success, data] = WTMiscUtils.loadData(true, subject, conditionsToPlot{cnd}, measure);
            if ~success
                wtLog.contextOff(); 
                break
            end

            prms.data{cnd} = data;     
            hPrms.Value = prms;

            % Set the callback to display the subPlot label as cursor info
            for chn = 1:nChannelsToPlot
                channelLabel = prms.channelsLocations(chn).labels;  
                wtLog.contextOn().dbg('Channel %s', channelLabel);
                channelIdx = channelsToPlotIdxs(chn);
                % Compute average across frequencies
                chnsAvg = squeeze(mean(data.WT(channelIdx, freqIdxs, timeIdxsReduced), 2));
                % Compute standard error
                chnsStdErr = squeeze(mean(std(data.SS(channelIdx, freqIdxs, timeIdxsReduced, :), 0, 4)./sqrt(size(data.SS, 4)), 2));
        
                if cnd == 1
                    axesPosition = [xBottomLeftCorner(chn), yBottomLeftCorner(chn), prms.subPlotRelWidth, prms.subPlotRelHeight];
                    hSubPlotAxes = axes('Position', axesPosition, 'nextplot', 'add');
                    hSubPlotAxes.UserData.OriginalPosition = axesPosition;
                    hSubPlotAxes.UserData.ChannelLabel = channelLabel;
                    hFigure.UserData.SubPlotsAxes = [hFigure.UserData.SubPlotsAxes hSubPlotAxes];
                    hold('on');
                    errorbar(hSubPlotAxes, chnsAvg, chnsStdErr, 'b');  % blue line
                else
                    hSubPlotAxes = hFigure.UserData.SubPlotsAxes(chn);
                    hold(hSubPlotAxes, 'on');
                    errorbar(hSubPlotAxes, chnsAvg, chnsStdErr,'r'); % red line
                end 

                if cnd == nConditionsToPlot
                    yLim = ylim();
                    title(hSubPlotAxes, channelLabel, 'FontSize', 8, 'FontWeight', 'bold', 'pos', [0, (yLim(1) - 0.22)]);
                end

                axis('off');   
                wtLog.contextOff();     
            end

            hold('off');
            % Callbacks settings
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
        prms = hMainPlot.UserData.onButtonDownCbPrms.Value;
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
        hFigure = openSubPlots(arrayfun(@(figure)strcmp(figure.Tag, figureTag), openSubPlots));
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

        nConditionsToPlot = length(prms.data);

        for cnd = 1:nConditionsToPlot
            data = prms.data{cnd};
            channelIdx = prms.channelsToPlotIdxs(subPlotIdx);
            % Compute average across frequencies
            chnsAvg = squeeze(mean(data.WT(channelIdx, prms.freqIdxs, prms.timeIdxs), 2));    
            % Compute standard error
            chnsStdErr = squeeze(mean(std(data.SS(channelIdx, prms.freqIdxs, prms.timeIdxs, :), 0, 4)./sqrt(size(data.SS, 4)), 2));

            if cnd == 1
                errorbar(chnsAvg, chnsStdErr, 'b');
                hold('on');
            else
                errorbar(chnsAvg, chnsStdErr, 'r'); 
                legend(prms.conditionsToPlot{1}, prms.conditionsToPlot{nConditionsToPlot});
            end

            if cnd == nConditionsToPlot
                set(gca, 'XTick', 1 : timePace/prms.timeRes : length(prms.timeIdxs))
                set(gca, 'XTickLabel', plotsPrms.TimeMin : timePace : plotsPrms.TimeMax);
                set(gca, 'XMinorTick', 'on', 'xgrid', 'on', 'YMinorTick', 'on',...
                    'ygrid', 'on', 'gridlinestyle', ':', 'YDIR', 'normal');
                axis('tight');
                title(figureName, 'FontSize', 16, 'FontWeight','bold');
                xlabel('ms', 'FontSize', 12, 'FontWeight', 'bold');
                ylabel(prms.yLabel.String, 'FontSize', 12, 'FontWeight', 'bold');
                hold('off');
            end 
        end
        
        hold('on');  
        % Set the callback to manage grid style change
        hFigure.WindowButtonDownFcn = @WTPlotUtils.setAxesGridStyleCb;
    catch me
        WTLog().except(me);
    end  
end

function success = setAvgStdErrPlotsParams()
    success = false;
    wtProject = WTProject();
    plotsPrms = copy(wtProject.Config.AverageStdErrPlots);

    if ~WTPlotsGUI.defineAvgStdErrPlotsSettings(plotsPrms)
        return
    end
    
    if ~plotsPrms.persist()
        wtProject.notifyErr([], 'Failed to save average with stderr plots params');
        return
    end

    wtProject.Config.AverageStdErrPlots = plotsPrms;
    success = true;
end
