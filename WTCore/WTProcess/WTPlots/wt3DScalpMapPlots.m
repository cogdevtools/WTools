% wt3DScalpMapPlots.m
% Created by Eugenio Parise
% CDC CEU 2011
% One line of code has been taken from Luca Filippin's EGIWaveletPlot.m
% It plots 3D scalpmaps of wavelet transformed EEG channels (for each condition).
% It uses headplot function from EEGLab, so EEGLab must be installed and
% included in Matlab path.
% It can plot a single timepoint, the average of a time window, as well as a
% single frequency or an averaged frequency band.
%
% It does not plot scalpmap series! Please, use smavr.m for this purpose.
%
% Add 'evok' as last argument to compute 3D scalp maps of evoked
% oscillations (of course, if they have been previously computed).
% DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
% Interactive user interface needs inputgui.m from EEGLab.
%
% Usage:
%
% wt3DScalpMapPlots(subj,tMintMax,FrMinFrMax,scale);
%
% wt3DScalpMapPlots('01',800,15,[-0.2 0.2]); % to plot a single subject,
% at 800 ms and at 15 Hz
%
% wt3DScalpMapPlots('05',[240 680],5,[-0.2 0.2]); % to plot a single subject,
% average between 240 and 680 ms at 5 Hz
%
% wt3DScalpMapPlots('grand',350,[10 60],[-0.2 0.2]); % to plot the grand average,
% average between at 350 ms in the 10 to 60 Hz averaged band
%
% wt3DScalpMapPlots('grand',[100 400],[10 60],[-0.2 0.2]); % to plot the grand average,
% average between 100 and 400 ms in the 10 to 60 Hz averaged band
%
% wt3DScalpMapPlots(); to run via GUI

function wt3DScalpMapPlots(subject, conditionsToPlot, evokedOscillations)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkWaveletAnalysisDone() 
        return
    end

    interactive = wtProject.Interactive;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 3);
        WTValidations.mustBeAStringOrChar(subject);
        WTValidations.mustBeALimitedLinearCellArrayOfString(conditionsToPlot, 1, -1, 0);
        subject = char(subject);
        conditionsToPlot = unique(conditionsToPlot);
    end
    
    ioProc = WTIOProcessor;
    channelsPrms = wtProject.Config.Channels;

    splineFile = fullfile(WTLayout.getDevicesDir(), channelsPrms.SplineFile);
    if ~WTUtils.fileExist(splineFile)
        wtProject.notifyErr([], 'Spline file not found: %s', splineFile);
        return
    end

    [success, meshFile] = ioProc.getMeshFileFromSplineFile(splineFile);
    if ~success 
        wtProject.notifyErr([], 'Can''t get mesh file name from: %s', splineFile);
        return
    end

    if ~WTUtils.fileExist(splineFile)
        wtLog.warn('Mesh file not found: %s', meshFile);
        meshFile = [];
    end

    logFlag = wtProject.Config.WaveletTransform.LogarithmicTransform || ...
        wtProject.Config.BaselineChop.Log10Enable;

    if interactive
        [fileNames, ~, measure, subject] = WTPlotsGUI.selectFilesToPlot(false, false, -1);
        if isempty(fileNames)
            return
        end
        if ~set3DScalpMapPlotsParams(logFlag) 
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

    [diffConsistency, grandConsistency] = WTPlotUtils.checkDiffAndGrandAvg(conditionsToPlot, grandAverage);
    if ~diffConsistency || ~grandConsistency
        return
    end

    [success, data] = WTPlotUtils.loadDataToPlot(false, subject, conditionsToPlot{1}, measure);
    if ~success || ~WTPlotUtils.adjustScalpMapPlotTimeFreqRanges(wtProject.Config.ThreeDimensionalScalpMapPlots, data) 
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

    wtLog.info('Plotting %s...', WTUtils.ifThenElse(grandAverage, 'grand average', @()sprintf('subject %s', subject)));
    wtLog.pushStatus().HeaderOn = false;
    mainPlots = [];

    try
        figureWHRatio = 4/3; 
        figuresPosition = WTPlotUtils.getFiguresPositions(nConditionsToPlot, figureWHRatio, 0.3, 0.1);
        xLabel = WTPlotUtils.getXLabelParams(logFlag);

        for cnd = 1:nConditionsToPlot
            wtLog.contextOn().info('Condition %s', conditionsToPlot{cnd});

            [success, data] = WTPlotUtils.loadDataToPlot(false, subject, conditionsToPlot{cnd}, measure);
            if ~success
                wtLog.contextOff();
                continue
            end 

            figureNamePrefix = WTUtils.ifThenElse(grandAverage, ...
                @()char(strcat(basicPrms.FilesPrefix, '.[AVG].[', conditionsToPlot{cnd}, '].[', measure, ']')), ...
                @()char(strcat(basicPrms.FilesPrefix, '.[SBJ:', subject, '].[', conditionsToPlot{cnd}, '].[', measure, ']')));

            figureName = [figureNamePrefix '.[' plotsPrms.TimeString ' ms].[' plotsPrms.FreqString ' Hz]'];
            
            hFigure = figure('NumberTitle', 'off', ...
                'Name', figureName, 'ToolBar', 'none', 'Position', figuresPosition{cnd});

            mainPlots(cnd) = hFigure;

            % Convert the data back to non-log scale straight in percent change in case logFlag is set
            data.WT = WTUtils.ifThenElse(logFlag, @()100 * (10.^data.WT - 1), data.WT);
            % Average on time
            data.WT = mean(data.WT(:,:,timeIdxs), 3);
            % Average on frequence
            data.WT = mean(data.WT(:,freqIdxs,:), 2);

            if isempty(meshFile)
                [~, hColorbar] = WTUtils.eeglabRun(WTLog.LevelDbg, false, ...
                    'headplot', data.WT, splineFile, 'electrodes', 'off', ...
                    'maplimits', plotsPrms.Scale, 'cbar', 0);
            else
                [~, hColorbar] = WTUtils.eeglabRun(WTLog.LevelDbg, false,  ...
                    'headplot', data.WT, splineFile, 'meshfile', meshFile, ...
                    'electrodes', 'off', 'maplimits', plotsPrms.Scale, 'cbar', 0);
            end

            set(get(hColorbar,'xlabel'), 'String', ...
                xLabel.String, 'Rotation', xLabel.Rotation, 'FontSize', 12, ...
                'FontWeight', 'bold', 'Position', [8 0.55]);

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
