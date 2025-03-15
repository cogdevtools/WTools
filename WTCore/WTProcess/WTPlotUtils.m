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

classdef WTPlotUtils

    properties(Constant)
        ScaleRelative                = '(Ratio)'
        ScaleDecibel                 = 'dB'
        ScaleEvokedOscillations      = 'EO'
        ScalePower                   = 'Pw'
        ScaleBaselineSubtraction     = 'BS'
        ScaleBaselineNormalization   = 'BN'
        ScaleBaselineSubtractionAndNormalization  = 'BSN'
        
        DimensionMicroVolt           = '\muV'
        DimensionSquaredMicroVolt    = '\muV^{2}'

        DimensionMicroVoltTxt        = 'uV'
        DimensionSquaredMicroVoltTxt = 'uV^2'
    end

    methods(Static)
        % waitUIs() wait for all UI objects to terminate
        function waitUIs(UIs) 
            for i = 1:length(UIs)
                try
                    uiwait(UIs{i});
                catch
                end
            end
        end

        % getFiguresPositions() given a number of figures (nFigures), their width/height ratio (whRation)
        % their relative width (rWidth: [0,1]) and the relative width offset between each other (rWidthOffs) 
        % returns a cell array sorting their position [x y w h] on screen. The positions are such that the 
        % figures will appear along the screen diagonal, with a certain offset which depends on rWidthOffs
        % (although the function might correct rWidthOffs if the window fall off the screen). The window 
        % size is a constant.
        function positions = getFiguresPositions(nFigures, whRatio, rWidth, rWidthOffs, relative)
            WTValidations.mustBeInt(nFigures);
            WTValidations.mustBeGTE(nFigures,1,0,1);
            WTValidations.mustBeGT(whRatio,0,0,0);
            WTValidations.mustBeInRange(rWidth,0,1,0,1);
            WTValidations.mustBeInRange(rWidthOffs,0,1,1,1);
            relative = nargin > 4 && relative;

            screenSize = get(groot, 'screensize');
            WHRatio = screenSize(3)/screenSize(4);
            rHeight = rWidth * WHRatio / whRatio;
            rWOffsMax = (1-rWidth) / nFigures;
            rHOffsMax = (1-rHeight) / nFigures;
            if rHOffsMax < rWOffsMax / WHRatio
                rWOffsMax = rHOffsMax / WHRatio;
            end
            rWOffs = min(rWidthOffs, rWOffsMax);
            rHOffs = rWOffs/WHRatio;
            xC = (1-((nFigures-1)*rWOffs + rWidth)) / 2;
            yC = 1-((1-((nFigures-1)*rHOffs + rHeight)) / 2)-rHeight;
            positions = cell(1, nFigures);
            sizeFactors = WTCodingUtils.ifThenElse(relative, [1 1], screenSize(3:4));
            minPos = WTCodingUtils.ifThenElse(relative, 0, 1);
            for i = 1:nFigures
                xRel = xC + (i-1)*rWOffs;
                yRel = yC - (i-1)*rHOffs;
                positions{i} = [ ...
                    min(max(xRel * sizeFactors(1), minPos), sizeFactors(1)) ... 
                    min(max(yRel * sizeFactors(2), minPos), sizeFactors(2)) ...
                    rWidth * sizeFactors(1) ...
                    rHeight * sizeFactors(2) ];
            end
        end

        % getScaleType() returns the scale type to use based on the flag passed on.
        function scaleType = getScaleType(isEvokedOscillations, isPower, isBaselineSubtracted, isBaselineNormalized, isDecibel)
            eO = WTCodingUtils.ifThenElse(isEvokedOscillations, WTPlotUtils.ScaleEvokedOscillations, '');
            pw = WTCodingUtils.ifThenElse(isPower, WTPlotUtils.ScalePower, '');
            bL = WTCodingUtils.ifThenElse(isBaselineSubtracted && isBaselineNormalized, WTPlotUtils.ScaleBaselineSubtractionAndNormalization, ...
                @()WTCodingUtils.ifThenElse(isBaselineSubtracted, WTPlotUtils.ScaleBaselineSubtraction, ... 
                @()WTCodingUtils.ifThenElse(isBaselineNormalized, WTPlotUtils.ScaleBaselineNormalization, '')));
            dr = WTCodingUtils.ifThenElse(isDecibel, WTPlotUtils.ScaleDecibel, ...
                @()WTCodingUtils.ifThenElse(isBaselineNormalized, WTPlotUtils.ScaleRelative, ''));
            items = {eO pw bL dr};
            scaleType = char(join(items(~cellfun('isempty', items)), '.'));
        end

        % getSuggestedScaleRange() returns the suggested scale range based on the flags passed on. For 
        % power data the value are expressed in microVolt^2, for non-power data the values are expressed
        % in microVolt. The range is expressed in decibel if isDecibel is true. For non-power data the 
        % range is expressed in relative units respect to the baseline.
        function rng = getSuggestedScaleRange(isPower, isBaselineSubtracted, isBaselineNormalized, isDecibel)
            if isPower
                if isBaselineSubtracted
                    if isBaselineNormalized
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-40 40], [-1 5]);
                    else 
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-60 40], [-5 25]);
                    end
                else
                    if isBaselineNormalized
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-60 30], [0 9]);
                    else
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-60 30], [0 25]);
                    end
                end
            else 
                if isBaselineSubtracted
                    if isBaselineNormalized
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-40 40], [-1 4]);
                    else 
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-60 40], [-2 7]);
                    end
                else
                    if isBaselineNormalized
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-60 40], [0 3]);
                    else
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-60 40], [0 5]); 
                    end
                end
            end
        end
        
        % getMaxScaleRange() similar to getSuggestedScaleRange() but returns the maximum range to use.
        function rng = getMaxScaleRange(isPower, isBaselineSubtracted, isBaselineNormalized, isDecibel)
            if isPower
                if isBaselineSubtracted
                    if isBaselineNormalized
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-100 100], [-20000 160000]);
                    else 
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-100 100], [-20000 40000]);
                    end
                else
                    if isBaselineNormalized
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-100 100], [0 80000]);
                    else
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-100 100], [0 40000]);
                    end
                end
            else 
                if isBaselineSubtracted
                    if isBaselineNormalized
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-100 100], [-100 400]);
                    else 
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-100 100], [-100 200]);
                    end
                else
                    if isBaselineNormalized
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-100 100], [0 400]);
                    else
                        rng = WTCodingUtils.ifThenElse(isDecibel, [-100 100], [0 200]); 
                    end
                end
            end
        end

        function label = getLabel(scaleType, dimension)
            label = WTCodingUtils.ifThenElse(isempty(scaleType), dimension, @()sprintf('%s [%s]', scaleType, dimension));
        end

        function label = getPlotConfigLabel(isEvokedOscillations, isPower, isBaselineCorrection, isBaselineNormalization, isDecibel)
            scaleType = WTPlotUtils.getScaleType(isEvokedOscillations, isPower, isBaselineCorrection, isBaselineNormalization, isDecibel);
            dimension = WTCodingUtils.ifThenElse(isPower, WTPlotUtils.DimensionSquaredMicroVoltTxt, ...
                WTPlotUtils.DimensionMicroVoltTxt);
            label = sprintf('Scale %s', WTPlotUtils.getLabel(scaleType, dimension));
        end

        function label = getPlotLabel(isEvokedOscillations, isPower, isBaselineCorrection, isBaselineNormalization, isDecibel)
            scaleType = WTPlotUtils.getScaleType(isEvokedOscillations, isPower, isBaselineCorrection, isBaselineNormalization, isDecibel);
            dimension = WTCodingUtils.ifThenElse(isPower, WTPlotUtils.DimensionSquaredMicroVolt, ...
                WTPlotUtils.DimensionMicroVolt);
            label = sprintf('%s', WTPlotUtils.getLabel(scaleType, dimension));
        end

        function params = getPlotLabelParams(label, rotateFun, positionFun) 
            params = struct();
            params.String = label;
            params.Rotation = 0;
            if nargin > 1 
                params.Rotation = rotateFun(params);
            end
            if nargin > 2
                params.Position = positionFun(params);
            end
        end

        function params = getPlotYLabelParams(label) 
            params = WTPlotUtils.getPlotLabelParams(label);
        end

        function params = getPlotXLabelParams(label, rotateLen) 
            rotate = @(p) WTCodingUtils.ifThenElse(length(p.String) >  rotateLen, 90, 0);
            position = @(p) WTCodingUtils.ifThenElse(verLessThan('matlab', '8.4'), 0.5, 0.2);
            params = WTPlotUtils.getPlotLabelParams(label, rotate, position);
        end

        function palette = generateHighContrastPalette(N)
            basic_colors = ['b', 'r', 'g', 'c', 'm', 'y', 'k'];
            if N < length(basic_colors)
                palette = basic_colors(1:N);
                return
            end
            colors = hsv(N);
            palette = hsv2rgb(colors);
        end

        function icon = createLetterIcon(letter, color)
            hF = figure('Visible', 'off');
            axes('Position', [0 0 1 1], 'Units', 'normalized', 'Visible', 'off');
            text(0.5, 0.5, letter, 'FontSize', 500, 'FontWeight', 'bold', ...
                'Color', color, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
            rectangle('Position', [0, 0, 1, 1], 'EdgeColor', 'black', 'LineWidth', 40);
            frame = getframe(gcf);
            icon = frame2im(frame);
            icon = imresize(icon, [16, 16], 'nearest');
            icon = uint8(icon);
            close(hF);
        end

        % addColorBarScaleControls
        % 
        % This function adds controls for scaling the color bar in a plot. 
        % It is typically used in conjunction with plotting functions to 
        % provide users with the ability to adjust the color bar scale 
        % dynamically. This can be useful for visualizing data with varying 
        % ranges and improving the interpretability of the plot.
        %
        % Usage:
        %   addColorBarScaleControls(hFigure, position, vSetRange, vDataRange)
        %
        % Parameters:
        %   hFigure    - figure to which add the colorbar range controls
        %   position   - either 'right' or 'left'
        %   vSetRange  - 1x2 array defining the custom user range
        %   vDataRange - 1x2 array definint the data range: (min, max)
        %
        % Note:
        %   If the figure must be either an plot with a generic colorbar or a
        %   WTools headplot.
        function addColorBarScaleControls(hFigure, position, vSetRange, vDataRange)
            WTValidations.mustBe(hFigure, ?matlab.ui.Figure)
            if ~isvalid(hFigure)
                return
            end

            hAxes = findobj(hFigure, 'Type', 'axes', 'Tag', '');

            if isempty(hAxes)
                WTException.badArg('cannot find any axes').throw();
            end

            vInitialRange = getappdata(hFigure, 'WTHeadplot_MapLimits');

            if isempty(vInitialRange)
                plotFun = [];
                vInitialRange = clim(hAxes);
                hColorBar = hAxes.Colorbar;

                if isempty(hColorBar)
                    WTException.badArg('cannot find any colorbar').throw();
                end
            else 
                plotFun = getappdata(hFigure, 'WTHeadplot_PlotFun');
                if isempty(plotFun)
                     WTException.badArg('cannot find WTHeadplot_PlotFun').throw();
                end
            end

            WTValidations.mustBe(position, ?char);

            switch position
                case 'right'
                    position = [0.95 hAxes.Position(2) 0.05 hAxes.Position(4)];
                case 'left'
                    position = [0.05 hAxes.Position(2) 0.05 hAxes.Position(4)];
                otherwise
                    WTException.badArg('position must be either ''right'', ''left''').throw();
            end

            if nargin > 4 && ~isempty(vDataRange) 
                WTValidations.mustBeLimitedLinearArray(vDataRange, 2, 2, 0);
                if vDataRange(1) >= vDataRange(2)
                    WTException.badArg('vDataRange(1) >= vDataRange(2)').throw();
                end
                if isempty(vSetRange)
                    vSetRange = vDataRange;
                    vDataRange = [];
                end
            end

            WTValidations.mustBeLimitedLinearArray(vSetRange, 2, 2, 0);
        
            if vSetRange(1) >= vSetRange(2)
                WTException.badArg('vSetRange(1) >= vSetRange(2)').throw();
            end

            % vInitialRange = clim(hAxes);
            vMin = vInitialRange(1);
            vMax = vInitialRange(2);
            
            persistent iconI;
            persistent iconW;
            persistent iconD;

            if isempty(iconI)
                iconI = WTPlotUtils.createLetterIcon('I', [1, 0, 0]);
                iconW = WTPlotUtils.createLetterIcon('W', [0, 0, 1]);
                iconD = WTPlotUtils.createLetterIcon('D', [0, 1, 0]);
            end

            toolbar = uitoolbar(hFigure);

            hToRangeInitialBtn = uipushtool(toolbar, ...
                'CData', iconI, ...
                'TooltipString', 'Set Color Scale range to initial', ...
                'ClickedCallback', @resetColorScaleCb, ...
                'UserData', vInitialRange);

            hToRangeSetBtn = uipushtool(toolbar, ...
                'CData', iconW, ...
                'TooltipString', 'Set Color Scale range to WTools', ...
                'ClickedCallback', @resetColorScaleCb, ...
                'UserData', vSetRange);

            if ~isempty(vDataRange)
                hToRangeDataBtn = uipushtool(toolbar, ...
                    'CData', iconD, ...
                    'TooltipString', 'Set Color Scale range to data', ...
                    'ClickedCallback', @resetColorScaleCb, ...
                    'UserData', vDataRange);
            end

            sliderPanel = uipanel('Parent', hFigure, 'Position', position, 'Title', 'Scale', 'FontSize', 7);
            figSizeChangedFcn = hFigure.SizeChangedFcn;
            hFigure.SizeChangedFcn = @(hFig,hAxs)resizeSliderPanelCb(hFig, hAxs, figSizeChangedFcn);
            sliderStep = getSliderStep(vInitialRange);

            hMinSlider = uicontrol('Style', 'slider', 'Parent', sliderPanel, 'Units', 'normalized', 'Position', [0.05 0 0.8 0.3], ...
                'Min', vMin, 'Max', vMax, 'Value', vMin, 'Callback', @updateColorScaleMinCb, 'HorizontalAlignment', 'center', ...
                'SliderStep', sliderStep);
            
            hMinText = uicontrol('Style', 'text', 'Parent', sliderPanel, 'Units', 'normalized', 'Position', [0.05 0.35 0.95 0.05], ...
                'String', num2str(hMinSlider.Value), 'FontSize', 9, 'HorizontalAlignment', 'center');
            
            hMaxSlider = uicontrol('Style', 'slider', 'Parent', sliderPanel, 'Units', 'normalized', 'Position', [0.05 0.7 0.8 0.3], ...
                'Min', vMin, 'Max', vMax, 'Value', vMax, 'Callback', @updateColorScaleMaxCb, 'HorizontalAlignment', 'center', ...
                'SliderStep', sliderStep);
            
            hMaxText = uicontrol('Style', 'text', 'Parent', sliderPanel, 'Units', 'normalized', 'Position', [0.05 0.6 0.95 0.05], ...
                'String', num2str(hMaxSlider.Value), 'FontSize', 9, 'HorizontalAlignment', 'center');
            
            resetColorScaleCb(hToRangeSetBtn, []);

            function adjustAxis(scaleMin, scaleMax)
                if ~isempty(plotFun)
                    plotFun(hFigure, [scaleMin, scaleMax]);
                else
                    clim(hAxes, [scaleMin scaleMax]);
                    scaleMid = (scaleMax+scaleMin)/2;
                    nYTicks = length(hColorBar.YTick);
                    hColorBar.YTick = linspace(scaleMin, scaleMax, nYTicks);
                    label = hColorBar.XLabel;
                    label.Position = [label.Position(1) scaleMid];
                end
            end

            function step = getSliderStep(rng)
                width = abs(rng(2) - rng(1));
                if width <= 100
                    step = [0.001 0.01];
                elseif width > 100 && width <= 10000
                    step = [0.0001 0.001];
                else 
                    step = [0.00001 0.0001];
                end
             end

            function setSliderValue(slider, field, value)
                saveCallback = slider.Callback; 
                slider.Callback = @WTCodingUtils.nop;
                set(slider, field, value);
                slider.Callback = saveCallback;
            end

            function resizeSliderPanelCb(hFig, hEvt, resizeFigureCb)
                if ~isempty(resizeFigureCb)
                    resizeFigureCb(hFig, hEvt)
                end
                hAxs = findobj(hFigure, 'Type', 'axes', 'Tag', '');
                sliderPanel.Position = [ ...
                    sliderPanel.Position(1), ...
                    hAxs.Position(2), ...
                    sliderPanel.Position(3), ...
                    hAxs.Position(4)];
            end
            
            function resetColorScaleCb(hButton, ~)
                rMin = hButton.UserData(1);
                rMax = hButton.UserData(2);
                
                sliderStep = getSliderStep([rMin rMax]);
                setSliderValue(hMinSlider, 'Min', rMin);
                setSliderValue(hMinSlider, 'Max', rMax);
                setSliderValue(hMinSlider, 'SliderStep', sliderStep);
                setSliderValue(hMaxSlider, 'Min', rMin);
                setSliderValue(hMaxSlider, 'Max', rMax);
                setSliderValue(hMaxSlider, 'SliderStep', sliderStep);

                sMin = hMinSlider.Value;
                sMax = hMaxSlider.Value;

                if sMin < rMin
                    sMin = rMin;
                end
                if sMax > rMax
                    sMax = rMax;
                end
                if sMin >= sMax
                    if sMin ~= rMin
                        sMin = sMax - abs(rMax - rMin)*sliderStep(1);
                    else
                        sMax = sMin + abs(rMax - rMin)*sliderStep(1);
                    end
                end
                setSliderValue(hMinSlider, 'Value', sMin);
                setSliderValue(hMaxSlider, 'Value', sMax);
                hMinText.String = num2str(sMin);
                hMaxText.String = num2str(sMax);
                adjustAxis(hMinSlider.Value, hMaxSlider.Value);
                drawnow;
            end
            
            function updateColorScaleMinCb(~, ~)
                newMin = hMinSlider.Value;
                valMax = hMaxSlider.Value;

                if newMin >= valMax
                    rng = hMinSlider.Max - hMinSlider.Min;
                    newMin = valMax - abs(rng)*sliderStep(1);
                end

                setSliderValue(hMinSlider, 'Value', newMin);
                adjustAxis(newMin, valMax);
                hMinText.String = num2str(newMin);
                drawnow;
            end
            
            function updateColorScaleMaxCb(~, ~)
                valMin = hMinSlider.Value;
                newMax = hMaxSlider.Value;
                
                if newMax <= valMin
                    rng = hMaxSlider.Max - hMaxSlider.Min;
                    newMax = valMin + abs(rng)*sliderStep(1);
                end
                
                setSliderValue(hMaxSlider, 'Value', newMax);
                adjustAxis(valMin, newMax);
                hMaxText.String = num2str(newMax);
                drawnow;
            end
        end

        function [x, y] = getChannelsXY(channelsLocations)
            n = length(channelsLocations);
            x = zeros(1, n);
            y = zeros(1, n);

            for i = 1:n
                chanLoc = channelsLocations(i);
                x(i) = sin(chanLoc.theta / 360 * 2 * pi) * chanLoc.radius;
                y(i) = cos(chanLoc.theta / 360 * 2 * pi) * chanLoc.radius;
            end
        end
        
        function is = isPointInCurrentAxes(point)
            hCurrentAxes = gca;
            pos = hCurrentAxes.Position;
            is = point(1) >= pos(1) && ...
                 point(1) <= pos(1) + pos(3) && ...
                 point(2) >= pos(2) && ...
                 point(2) <= pos(2) + pos(4); 
        end

        function bringObjectsToFront(hFigures)
            for i = 1:length(hFigures)
                if isvalid(hFigures(i))
                    figure(hFigures(i));
                end
            end
        end

        % --- Callbacks -- ON ---

        function keepWindowSizeRatioCb(hObject, event, whRatio) 
            if strcmp(hObject.WindowState, 'fullscreen') || ...
               strcmp(hObject.WindowState, 'maximized')
                return
            end
            pos = hObject.Position;
            scale = (pos(3) + pos(4) * whRatio) / 2;
            width = scale;
            height = scale / whRatio;
            if ~strcmp(hObject.Units, 'normalized') 
                width = floor(width);
                height = floor(height);
            end
            if pos(3) == width && pos(4) == height
                return
            end
            pos(3) = width;
            pos(4) = height;
            hObject.Position = pos;
        end

        % setAxesGridStyleCb() switch the axes grid style each time is called
        function setAxesGridStyleCb(hObject, event)
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

        function bringChildrenObjectsToFrontCb(hObject, event, childrenObjField)
            subFigures = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, childrenObjField);
            bringObjectsToFront(subFigures)
        end

        % Keep track in the parent object of all existing children-objects & close all them
        % whenever the parent is closed. Requires to define:
        % - hParentObject.UserData.<childrenObjField>: 
        %       hChildrenObjects: list to the children of hParentObject
        % hChildrenObjects must be set by the caller.
        % To be used in pair with childObjectCloseRequestCb.
        function parentObjectCloseRequestCb(hObject, event, childrenObjField)
            function closeChild(hChildObj)
                if isvalid(hChildObj)
                    close(hChildObj)
                end
            end
            try
                hChildrenObjects = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, childrenObjField);
                arrayfun(@closeChild, hChildrenObjects); 
                hObject.UserData = WTFieldUtils.mustSetFieldOrProperty(hObject.UserData, '[]', childrenObjField); 
            catch me
                WTLog().except(me);
            end
            delete(hObject);
        end

        % Keep track in the parent object of all existing children-objects by auto updating 
        % their list whenever a children receive a close request. This cb is supposed to be
        % set as childObject.CloseRequestFcn. Requires to define:
        % - hObject.UserData.<parentObjectField>: 
        %       hParentObject: handle to the parent object 
        % - hParentObject.UserData.<childrenObjField>: 
        %       hChildrenObjects: list to the children of hParentObject
        % hParentObject & hChildrenObjects must be set by the caller.
        % To be used in pair with parentObjectCloseRequestCb.
        function childObjectCloseRequestCb(hObject, ~, parentObjectField, childrenObjField)
            try
                hParentObject = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, parentObjectField);
                if isvalid(hParentObject)
                    hChildrenObjects = WTFieldUtils.mustGetFieldOrProperty(hParentObject.UserData, childrenObjField);
                    hChildObjIdx = arrayfun(@(hObj)hObj == hObject, hChildrenObjects);
                    hChildrenObjects(hChildObjIdx) = [];
                    hParentObject.UserData = WTFieldUtils.mustSetFieldOrProperty(hParentObject.UserData, hChildrenObjects, childrenObjField);
                end
            catch me
                WTLog().except(me);
            end
            delete(hObject);
        end

        % This function take a list of graphic objects (all supposed to have a Position
        % property) and resizes them accordingly to the resizeOperation, by increasing or
        % decreasing their width and height of 1/20 of thir original value (which is the 
        % max value they can assume). It requires that each object has defined:
        % - hObject.UserData.<originalPositionField>
        function resizeGraphicObjects(hObjects, originalPositionField, resizeOperation)
            for i = 1 : length(hObjects)
                hObject = hObjects(i);
                position = hObject.Position;
                origPosition = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, originalPositionField);
                origWidth = origPosition(3);
                origHeight = origPosition(4);
                tickWidth = origWidth / 20;
                tickHeight = origHeight / 20;
        
                switch resizeOperation
                    case '+'
                        if position(3) <= origWidth - tickWidth 
                            position(1) = position(1) - tickWidth / 2;
                            position(2) = position(2) - tickHeight / 2;
                            position(3) = position(3) + tickWidth;
                            position(4) = position(4) + tickHeight;
                            hObject.Position = position;
                        end
                    case '-'
                        if position(3) >= 2 * tickWidth 
                            position(1) = position(1) + tickWidth / 2;
                            position(2) = position(2) + tickHeight / 2;
                            position(3) = position(3) - tickWidth;
                            position(4) = position(4) - tickHeight;
                            hObject.Position = position;
                        end
                end
            end
        end
        
        % onKeyPressResizeObjectsCb calls resizeGraphicObjects() on an array of controlled objects, when
        % either '+' or '-' is pressed. Required fields for hObject:
        % - hObject.UserData.<controlledObjectsField>: 
        %       hControlledObjects: array of graphic objects
        % - hControlledObjects(i).UserData.<originalPositionField>
        %       for each object in hControlledObjects
        function onKeyPressResizeObjectsCb(hObject, event, KeyMinus, keyPlus, controlledObjectsField, originalPositionField)
            try
                hControlledObjects = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, controlledObjectsField);
                key = lower(event.Character);
                switch key
                    case keyPlus  
                        WTPlotUtils.resizeGraphicObjects(hControlledObjects, originalPositionField, key)
                    case KeyMinus
                        WTPlotUtils.resizeGraphicObjects(hControlledObjects, originalPositionField, key)
                    otherwise
                        return
                end
            catch me
                WTLog().except(me);
            end
        end
        
        % onKeyPressResetObjectsPositionCb() resets the positions and sizes of all graphic objects in an 
        % array when the key 'r' is pressed. Required fields for hObject:
        % - hObject.UserData.<controlledObjectsField>: 
        %       hControlledObjects: array of graphic objects
        % - hControlledObjects(i).UserData.<originalPositionField>
        %       for each object in hControlledObjects
        function onKeyPressResetObjectsPositionCb(hObject, event, keyReset, controlledObjectsField, originalPositionField)
            try
                switch lower(event.Character)
                    case keyReset % rearrange controlled objects into the original opening position
                        hControlledObjects = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, controlledObjectsField);
                        for i = 1:length(hControlledObjects)
                            hControlledObjects(i).Visible = 'on';
                            hControlledObjects(i).Position = WTFieldUtils.mustGetFieldOrProperty(hControlledObjects(i).UserData, originalPositionField);
                        end
                end
            catch me
                WTLog().except(me);
            end
        end

        function onKeyPressBringSingleObjectToFrontCb(hObject, event, keyFront, targetObjectField)
            try
                switch lower(event.Character)
                    case keyFront 
                        hTargetObject = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, targetObjectField);
                        if isvalid(hTargetObject)
                            hTargetObject.Visible = 'on';
                            figure(hTargetObject);
                        end
                end
            catch me
                WTLog().except(me);
            end
        end

        function onKeyPressBringObjectsToFrontCb(hObject, event, keyFront, targetObjectsField)
            try
                switch lower(event.Character)
                    case keyFront 
                        targetObjects = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, targetObjectsField);
                        for i = 1:length(targetObjects)
                            if isvalid(targetObjects{i})
                                targetObjects{i}.Visible = 'on';
                                figure(targetObjects{i});
                            end
                        end
                end
            catch me
                WTLog().except(me);
            end
        end

        function onKeyPressCloseObjectsCb(hObject, event, keyClose, targetObjectsField)
            try
                switch lower(event.Character)
                    case keyClose 
                        targetObjects = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, targetObjectsField);
                        for i = 1:length(targetObjects)
                            if isvalid(targetObjects{i})
                                close(targetObjects{i});
                            end
                        end
                end
            catch me
                WTLog().except(me);
            end
        end

        % onKeyPressSetObjectAndChildrenVisibilityCb() manage the visibility of a graphic object (show/hide) and
        % its children. If the graphic object is part of a pool, make sure that at least one object in the pool 
        % is visible. 
        % - hObject.UserData.<poolObjectsField>: 
        %       cell array of handles
        % - hObject.UserData.<targetObjectField>: 
        %       cell array of handles
        % - hObject.UserData.<targetChildrenField>: 
        %       array of handles
        % When poolObjectsField is empty, that means that there's no pool. When targetObjectField is empty, then the
        % target object is the one for which the callback has been registered.
        function onKeyPressSetObjectAndChildrenVisibilityCb(hObject, event, keyHide, keyShow, poolObjectsField, targetObjectField, targetChildrenField)
            try
                switch lower(event.Character)
                    case keyHide
                        visible = 'off';
                    case keyShow
                        visible = 'on';
                    otherwise
                        return
                end
                if isempty(targetObjectField)
                    hTargetObject = hObject;
                else
                    hTargetObject = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, targetObjectField);
                end
                if ~isempty(poolObjectsField)
                    hPoolObjects = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, poolObjectsField);
                    visibleObjects = cellfun(@(hObj)isvalid(hObj) && strcmp(hObj.Visible, 'on'), hPoolObjects);
                    hPoolObjects = hPoolObjects(visibleObjects);
                    if (length(hPoolObjects) == 1 && hPoolObjects{1} == hTargetObject && strcmp(visible, 'off'))
                        return
                    end
                end
                if isvalid(hTargetObject)
                    hTargetObject.Visible = visible;
                end
                hChildrenObjects = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, targetChildrenField);
                for i = 1:length(hChildrenObjects)
                    if isvalid(hChildrenObjects(i))
                        hChildrenObjects(i).Visible = visible;
                    end
                end
            catch me
                WTLog().except(me);
            end
        end

        % onMouseScrollResizeObjectsCb() calls resizeGraphicObjects() on an array of controlled objects, when
        % either the mouse scrolls up/down (+/-) . Required fields for hObject:
        % - hObject.UserData.<controlledObjectsField>: 
        %       hControlledObjects: array of graphic objects
        % - hControlledObjects(i).UserData.<originalPositionField>
        %       for each object in hControlledObjects
        function onMouseScrollResizeObjectsCb(hObject, event, controlledObjectsField, originalPositionField) 
            try
                hControlledObjects = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, controlledObjectsField);
                if event.VerticalScrollCount >= 1
                    WTPlotUtils.resizeGraphicObjects(hControlledObjects, originalPositionField, '+')
                elseif event.VerticalScrollCount <= -1
                    WTPlotUtils.resizeGraphicObjects(hControlledObjects, originalPositionField, '-')
                end
            catch me
                WTLog().except(me);
            end
        end

        % getClickedSubObjectIndex() can be CPU intensive if the #sub-objects is big, especially
        % considered that's execute at each new mouse pointer position within hObject
        function [subObjectIdx, clickPosRelToSubObject] = getClickedSubObjectIndex(hObject, points) 
            clickPoint = hObject.CurrentPoint;
            objectPosition = hObject.Position;
            relClickPoint = clickPoint ./ objectPosition(3:4);
            distance = sum((points - repmat(relClickPoint, [size(points,1), 1])) .^ 2, 2);
            [~, minDistanceObjectIdx] = min(distance);
            clickPosRelToSubObject = relClickPoint - points(minDistanceObjectIdx,:);
            subObjectIdx = minDistanceObjectIdx;
        end

        % onMouseOverSubObjectsDoCb() tracks the mouse movements over the graphic object hObject and
        % determines the sub-object of hObject at the minimal distance from the pointer. Then if the
        % pointer falls within the graphical extent of such sub-object, it calls doCb passing in the 
        % sub-object together with other user params or it calls doCb passing in an empty object.
        % Required fields for hObject:
        % - hObject.UserData.<pointsField> list of points associated to the sub-objects, respect to 
        %      which the min distance is calculated (normally the center of the sub-objects)
        % - hObject.UserData.<subObjectsField> list of the sub-objects
        % As graphical objects, hObject and the sub-objects are supposed to have the property Position
        % and CurrentPoint.
        % User callback: doCb(hObject, []|hSubObject, subObjIdx, varargin{:})
        function onMouseOverSubObjectsDoCb(hObject, event, pointsField, subObjectsField, doCb, varargin) 
            try
                points = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, pointsField); 
                [subObjectIdx, clickPosRelToSubObject] = WTPlotUtils.getClickedSubObjectIndex(hObject, points);
                
                hSubObjects = WTFieldUtils.mustGetFieldOrProperty(hObject.UserData, subObjectsField);
                hSubObject = hSubObjects(subObjectIdx);
                subObjectPosition = hSubObject.Position;
                clickPosRelToSubObject = abs(clickPosRelToSubObject);

                if clickPosRelToSubObject(1) > subObjectPosition(3)/2 || ...
                    clickPosRelToSubObject(2) > subObjectPosition(4)/2
                    doCb(hObject, [], 0, varargin{:})
                else
                    doCb(hObject, hSubObject, subObjectIdx, varargin{:});
                end
            catch me
                WTLog().except(me);
            end
        end

        % Compose graphic objects callbacks. Usage:
        % composeGraphicCallbacks({@cbA, a1, a2 ...}, {@cbB, b1, b2 ...}, @cbC, ... )
        % Where:
        %  - function cbA(hObject, event, a1, a2, ...) 
        %  - function cbB(hObject, event, b1, b2, ...)
        %  - function cbC(hObject, event)
        %  - ...
        function cb = composeGraphicCallbacks(varargin)
            nArgsIn = nargin;

            function cb_(hObject, event) 
                for i = 1:nArgsIn
                    try
                        if iscell(varargin{i})
                            cbDef = varargin{i};
                            cbFun = cbDef{1};
                            cbArg = WTCodingUtils.ifThenElse(length(cbDef) > 1, @()cbDef(2:end), {});
                        else
                            cbFun = varargin{i};
                            cbArg = {};
                        end
                        cbFun(hObject, event, cbArg{:})
                    catch me
                        WTLog().except(me);
                    end 
                end
            end
            cb = @cb_;
        end

        % --- Callbacks -- OFF ---
    end
end


