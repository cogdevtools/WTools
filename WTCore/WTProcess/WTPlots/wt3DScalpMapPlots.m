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

function wt3DScalpMapPlots(subject, conditionsToPlot, evokedOscillations)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkChopAndBaselineCorrectionDone() 
        return
    end

    interactive = wtProject.Interactive;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 3);
        WTValidations.mustBeStringOrChar(subject);
        WTValidations.mustBeLimitedLinearCellArrayOfChar(conditionsToPlot);
        subject = char(subject);
        conditionsToPlot = unique(conditionsToPlot);
    end
    
    ioProc = wtProject.Config.IOProc;
    waveletTransformPrms = wtProject.Config.WaveletTransform;
    baselineChopPrms = wtProject.Config.BaselineChop;
    logFlag = waveletTransformPrms.LogarithmicTransform || baselineChopPrms.LogarithmicTransform;
    evokFlag = waveletTransformPrms.EvokedOscillations;

    if interactive
        [fileNames, ~, measure, subject] = WTPlotsGUI.selectFilesToPlot(evokFlag, false, false, -1);
        if isempty(fileNames)
            return
        end
    else
        measure = WTCodingUtils.ifThenElse(evokedOscillations, ...
            WTIOProcessor.WaveletsAnalisys_evWT,  WTIOProcessor.WaveletsAnalisys_avWT);
    end

    grandAverage = isempty(subject);
    if grandAverage && ~wtProject.checkGrandAverageDone()
        return
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
    if ~success 
        return
    end

    if interactive && ~set3DScalpMapPlotsParams(logFlag, data) 
        return
    end
 
    plotsPrms = wtProject.Config.ThreeDimensionalScalpMapPlots;
    splineFile = ioProc.getSplineFile(plotsPrms.SplineFile, plotsPrms.SplineLocal);   
    splineFileDev = ioProc.getSplineFile(plotsPrms.SplineFile, 0);  
    
    [success, meshFile] = ioProc.getMeshFileFromSplineFile(splineFileDev);
    if ~success 
        wtProject.notifyErr([], 'Can''t get mesh file name from: %s', splineFileDev);
        return
    end

    if ~WTIOUtils.fileExist(meshFile)
        wtLog.warn('Mesh file ''%s'' not found: default one will be used instead', meshFile);
        meshFile = [];
    end

    if ~WTConfigUtils.adjustPacedTimeFreqDomains(plotsPrms, data) 
        return
    end

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
                [~, hColorbar] = WTEEGLabUtils.eeglabRun(WTLog.LevelInf, false, ...
                    'headplot', data.WT, splineFile, 'electrodes', 'off', ...
                    'maplimits', plotsPrms.Scale, 'cbar', 0);
            else
                [~, hColorbar] = WTEEGLabUtils.eeglabRun(WTLog.LevelInf, false,  ...
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
            % Not much sure about deleting the global key management, but it interferes otherwise...
            hFigure.KeyPressFcn = [];
            hFigure.KeyReleaseFcn = [];
            % Enable listeners
            arrayfun(@(h)setfield(h, 'Enabled', 1), hManager.WindowListenerHandles);

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

function success = set3DScalpMapPlotsParams(logFlag, data)
    success = false;
    wtProject = WTProject();
    waveletTransformPrms = wtProject.Config.WaveletTransform;
    baselineChopPrms = wtProject.Config.BaselineChop;
    plotsPrms = copy(wtProject.Config.ThreeDimensionalScalpMapPlots);

    if ~plotsPrms.exist() 
        if waveletTransformPrms.exist()
            plotsPrms.Time = [waveletTransformPrms.TimeMin waveletTransformPrms.TimeMax];
            plotsPrms.Frequency = [waveletTransformPrms.FreqMin waveletTransformPrms.FreqMax];
        end
        if baselineChopPrms.exist()
            plotsPrms.Time = [baselineChopPrms.ChopTimeMin baselineChopPrms.ChopTimeMax];
        end
    end

    while true
        if ~WTPlotsGUI.define3DScalpMapPlotsSettings(plotsPrms, logFlag)
            return
        end
        if checkUpdateSplineFile(plotsPrms, data)
            break
        end
    end
    
    if ~plotsPrms.persist()
        wtProject.notifyErr([], 'Failed to save 3D scalp map plots params');
        return
    end

    wtProject.Config.ThreeDimensionalScalpMapPlots = plotsPrms;
    success = true;
end

function success = checkUpdateSplineFile(plotsPrms, data)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();

    ioProc = wtProject.Config.IOProc;
    localSplineFile = ioProc.getSplineFile(plotsPrms.SplineFile, 1);
    plotsPrms.SplineLocal = 0;

    if WTIOUtils.fileExist(localSplineFile)
        wtLog.info('Found local spline file, check skipped: %s', localSplineFile);
        plotsPrms.SplineLocal = 1;
        success = true;
        return
    end

    [ok, spline] = ioProc.readSpline(plotsPrms.SplineFile, 0);
    if ~ok 
        wtProject.notifyErr([], 'Spline file not found:\n%s', ioProc.getSplineFile(plotsPrms.SplineFile, 0));
        return
    end

    nChans = length(data.chanlocs);
    electrodes = cellstr(spline.ElectrodeNames);
    channels = {data.chanlocs.labels}';

    wtLog.info('Checking channels against spline data...');
    wtLog.contextOn().HeaderOn = false;
   
    if ~isfield(spline, 'indices')
        wtLog.warn('> Spline data without ''indices'' field!')
    end

    diffEC = setdiff(electrodes, channels);

    if ~isempty(diffEC)
        wtLog.info('> Spline data with extra channels: %s', char(join(diffEC,', ')));
    end

    elMap = containers.Map(electrodes, 1:length(electrodes));
    nChansMismatches = 0;
    nChansMissing = 0;

    for i = 1:nChans
        chan = channels{i};

        if ~elMap.isKey(chan)
            wtLog.err('+ ''%s''\tchannel missing...', chan);
            nChansMissing = nChansMissing + 1;
            continue
        elseif ~isfield(spline, 'indices')
            continue 
        end
        idx = spline.indices(elMap(chan));
        if idx == i
            wtLog.info('+ ''%s''\tchannel found', chan);
        else 
            wtLog.warn('+ ''%s''\tchannel found, but index mismatch: expected %d, got %d', chan, i, idx);
            nChansMismatches = nChansMismatches + 1;
        end
    end

    nChansFound = nChans - nChansMissing;
    wtLog.info('> Channels found = %d, index mismtaches = %d, channels missing = %d', ...
        nChansFound, nChansMismatches, nChansMissing);
    wtLog.contextOff().HeaderOn = true;

    if nChansMissing == 0 && nChansMismatches == 0 && isempty(diffEC)
        success = true;
        return
    elseif nChansFound == 0 
        wtProject.notifyErr([], 'Spline electrodes and data channels are disjoint sets!');
        return
    elseif ~WTEEGLabUtils.eeglabYesNoDlg('Warning', ...
            ['Spline check result:\n' ...
             '    + Extra channels = %d\n' ...
             '    + Channels found = %d\n' ...
             '    + Index mismatches = %d\n'...
             '    + Channels missing = %d (won''t be displayed)\n' ...
             'Check the log for details.\nFix mismatches and continue?'], ... 
            length(diffEC), nChansFound, nChansMismatches, nChansMissing)
        return
    end 

    elMap = containers.Map(electrodes, 1:length(electrodes));
    splineOut = spline;
    n = 1;

    for i = 1:length(channels)
        if ~elMap.isKey(channels{i})
            continue
        end
        j = elMap(channels{i});
        splineOut.indices(n) = i;
        splineOut.ElectrodeNames(n,:) = spline.ElectrodeNames(j,:);
        splineOut.Xe(n) = spline.Xe(j);
        splineOut.Ye(n) = spline.Xe(j);
        splineOut.Ze(n) = spline.Xe(j);
        splineOut.G(n,:) = spline.G(j,:);
        splineOut.G(:,n) = spline.G(:,j);
        splineOut.gx(:,n) = spline.gx(:,j); 
        splineOut.newElect(n,:) = spline.newElect(j,:);
        n = n+1;
    end

    splineOut.indices(n:end) = [];
    splineOut.ElectrodeNames(n:end,:) = [];
    splineOut.Xe(n:end) = [];
    splineOut.Ye(n:end) = [];
    splineOut.Ze(n:end) = [];
    splineOut.G(n:end,:) = [];
    splineOut.G(:,n:end) = [];
    splineOut.gx(:,n:end) = [];
    splineOut.newElect(n:end,:) = [];
    splineOut.comment = [spline.comment ' (Modified by WTools)']; 

    if ~ioProc.writeSpline(splineOut, plotsPrms.SplineFile)
        wtProject.notifyErr([], 'Failed to save updated spline data file:\n%s', localSplineFile);
        return
    end

    plotsPrms.SplineLocal = 1;
    success = true;
end