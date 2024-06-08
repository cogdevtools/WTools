function wt3DScalpMapPlots(subject, conditionsToPlot, evokedOscillations)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkChopAndBaselineCorrectionDone() 
        return
    end

    interactive = wtProject.Interactive;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 3);
        WTValidations.mustBeAStringOrChar(subject);
        WTValidations.mustBeALimitedLinearCellArrayOfString(conditionsToPlot);
        subject = char(subject);
        conditionsToPlot = unique(conditionsToPlot);
    end
    
    ioProc = WTIOProcessor;
    channelsPrms = wtProject.Config.Channels;

    splineFile = fullfile(WTLayout.getDevicesDir(), channelsPrms.SplineFile);
    if ~WTIOUtils.fileExist(splineFile)
        wtProject.notifyErr([], 'Spline file not found: %s', splineFile);
        return
    end

    [success, meshFile] = ioProc.getMeshFileFromSplineFile(splineFile);
    if ~success 
        wtProject.notifyErr([], 'Can''t get mesh file name from: %s', splineFile);
        return
    end

    if ~WTIOUtils.fileExist(meshFile)
        wtLog.warn('Mesh file ''%s'' not found: default one will be used instead', meshFile);
        meshFile = [];
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
        if ~set3DScalpMapPlotsParams(logFlag) 
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
    if ~success || ~WTConfigUtils.adjustPacedTimeFreqDomains(wtProject.Config.ThreeDimensionalScalpMapPlots, data) 
        return
    end

    plotsPrms = wtProject.Config.ThreeDimensionalScalpMapPlots;

    if ~isempty(plotsPrms.TimeMax)
        timeIdxs = find(data.tim == plotsPrms.TimeMin) : find(data.tim == plotsPrms.TimeMax);
    else 
        timeIdxs = find(data.tim == plotsPrms.TimeMin);
    end

    if ~isempty(plotsPrms.FreqMax)
        freqIdxs = find(data.Fa == plotsPrms.FreqMin) : find(data.Fa == plotsPrms.FreqMax);
    else 
        freqIdxs = find(data.Fa == plotsPrms.FreqMin);
    end

    wtLog.info('Plotting %s...', WTCodingUtils.ifThenElse(grandAverage, 'grand average', @()sprintf('subject %s', subject)));
    wtLog.pushStatus().HeaderOn = false;
    hMainPlots = WTHandle(cell(1, nConditionsToPlot));

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

            figureNamePrefix = WTCodingUtils.ifThenElse(grandAverage, ...
                @()char(strcat(basicPrms.FilesPrefix, '.[AVG].[', conditionsToPlot{cnd}, '].[', measure, ']')), ...
                @()char(strcat(basicPrms.FilesPrefix, '.[SBJ:', subject, '].[', conditionsToPlot{cnd}, '].[', measure, ']')));

            figureName = [figureNamePrefix '.[' plotsPrms.TimeString ' ms].[' plotsPrms.FreqString ' Hz]'];
            
            
            hFigure = figure('NumberTitle', 'off', ...
                'Name', figureName, 'ToolBar', 'none', 'Position', figuresPosition{cnd});

            hMainPlots.Value{cnd} = hFigure;
            hFigure.UserData.MainPlots = hMainPlots;

            % Convert the data back to non-log scale straight in percent change in case logFlag is set
            data.WT = WTCodingUtils.ifThenElse(logFlag, @()100 * (10.^data.WT - 1), data.WT);
            % Average on time
            data.WT = mean(data.WT(:,:,timeIdxs), 3);
            % Average on frequence
            data.WT = mean(data.WT(:,freqIdxs,:), 2);

            if isempty(meshFile)
                [~, hColorbar] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, ...
                    'headplot', data.WT, splineFile, 'electrodes', 'off', ...
                    'maplimits', plotsPrms.Scale, 'cbar', 0);
            else
                [~, hColorbar] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false,  ...
                    'headplot', data.WT, splineFile, 'meshfile', meshFile, ...
                    'electrodes', 'off', 'maplimits', plotsPrms.Scale, 'cbar', 0);
            end
            
            colormap(colorMap);

            set(get(hColorbar,'xlabel'), 'String', ...
                xLabel.String, 'Rotation', xLabel.Rotation, 'FontSize', 12, ...
                'FontWeight', 'bold', 'Position', [8 0.55]);

            % Disable listeners that block figure callbacks udpate
            hManager = uigetmodemanager(hFigure);
            arrayfun(@(h)setfield(h, 'Enabled', 0), hManager.WindowListenerHandles);
            % Set the callback to manage keys
            hFigure.WindowKeyPressFcn = WTPlotUtils.composeGraphicCallbacks(...
                hFigure.WindowKeyPressFcn, ...
                {@WTPlotUtils.onKeyPressBringObjectsToFrontCb, 'a', 'MainPlots.Value'}, ...
                {@WTPlotUtils.onKeyPressCloseObjectsCb, 'q', 'MainPlots.Value'});
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

function success = set3DScalpMapPlotsParams(logFlag)
    success = false;
    wtProject = WTProject();
    plotsPrms = copy(wtProject.Config.ThreeDimensionalScalpMapPlots);

    if ~WTPlotsGUI.define3DScalpMapPlotsSettings(plotsPrms, logFlag)
        return
    end
    
    if ~plotsPrms.persist()
        wtProject.notifyErr([], 'Failed to save 3D scalp map plots params');
        return
    end

    wtProject.Config.ThreeDimensionalScalpMapPlots = plotsPrms;
    success = true;
end
