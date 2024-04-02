classdef WTPlotUtils

    methods(Static, Access=private)
        
        function matVer = normalizedMatlabVersion()
            persistent vers

            if ~isempty(vers)
                matVer = vers;
                return
            end
            % same as in eeglab's icadefs.m: can't make sense of the code though...
            vTemp = version();
            pointIdxs = find(vTemp == '.');
            if WTUtils.str2double(vTemp(pointIdxs(1)+1)) > 1 
                vTemp = [ vTemp(1:pointIdxs(1)) '0' vTemp(pointIdxs(1)+1:end) ]; 
                pointIdxs = find(vTemp == '.');
            end
            vers = WTUtils.str2double(vTemp(1:pointIdxs(2)-1));
            matVer = vers;
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
    end

    methods(Static)

        function waitUIs(UIs) 
            for i = 1:length(UIs)
                try
                    uiwait(UIs(i));
                catch
                end
            end
        end

        % getFiguresPositions() given a number of figures (nFigures), their width/height ratio (whRation)
        % their relative width (rWidth: [0,1]) and the relative width offset between each other (rWidthOffs) 
        % returns a cell array sotring their position [x y w h] on screen. The positions are such that the 
        % figures will appear along the screen diagonal, with a certain offset which depends on rWidthOffs
        % (although the function might correct rWidthOffs if the window fall off the screen). The window 
        % size is a constant.
        function positions = getFiguresPositions(nFigures, whRatio, rWidth, rWidthOffs)
            WTValidations.mustBeInt(nFigures);
            WTValidations.mustBeGTE(nFigures, 1, false);
            WTValidations.mustBeGT(whRatio, 0);
            WTValidations.mustBeInRange(rWidth, 0, 1, false, true);
            WTValidations.mustBeInRange(rWidthOffs, 0, 1, true, true);

            absSize = get(groot, 'screensize');
            WHRatio = absSize(3)/absSize(4);
            rHeight = rWidth * WHRatio / whRatio;
            rWOffsMax = (1-rWidth)/nFigures;
            rHOffsMax = (1-rHeight)/nFigures;
            if rHOffsMax < rWOffsMax/WHRatio
                rWOffsMax = rHOffsMax / WHRatio;
            end
            rWOffs = min(rWidthOffs, rWOffsMax);
            rHOffs = rWOffs/WHRatio;
            xC = (1-((nFigures-1)*rWOffs + rWidth))/2;
            yC = 1-((1-((nFigures-1)*rHOffs + rHeight))/2)-rHeight;
            positions = cell(1, nFigures);
            positions = cell(1, nFigures);
            for i = 1:nFigures
                xRel = xC + (i-1)*rWOffs;
                yRel = yC - (i-1)*rHOffs;
                positions{i} = [ ...
                    min(max(xRel * absSize(3), 1), absSize(3)) ... 
                    min(max(yRel * absSize(4), 1), absSize(4)) ...
                    rWidth * absSize(3) ...
                    rHeight * absSize(4)];
            end
        end

        function params = getYLabelParams(logFlag) 
            params = struct();
            params.String = WTUtils.ifThenElse(logFlag, '% change', '\muV');
        end

        function params = getXLabelParams(logFlag) 
            params = struct();
            if logFlag
                params.String = '% change';
                params.Rotation = 90;
            else
                params.String = '\muV';
                params.Rotation = 0;
            end
            vers = WTPlotUtils.normalizedMatlabVersion();
            params.Position = WTUtils.ifThenElse(vers < 8.04, 5, 2);
        end

        function plotsColorMap = getPlotsColorMap()
            persistent colorMap

            if ~isempty(colorMap)
                plotsColorMap = colorMap;
                return
            end

            wtAppConfig = WTAppConfig();

            if ~isempty(wtAppConfig.PlotsColorMap)
                colorMap = wtAppConfig.PlotsColorMap;
            else
                colorMap = 'parula'; 
                try
                    % call eeglab icadefs to set the same colormap if defined there...
                    icadefs;
                    if exist('DEFAULT_COLORMAP', 'var')
                        colorMap = DEFAULT_COLORMAP;
                    end
                catch
                end
            end

            plotsColorMap = colorMap;
        end
        
        % subject empty => load grand average
        function [success, data] = loadDataToPlot(perSubject, subject, condition, measure) 
            wtProject = WTProject();
            ioProc = wtProject.Config.IOProc;
            grandAverage = isempty(subject);
        
            if grandAverage
                [success, data] = ioProc.loadGrandAverage(condition, measure, perSubject);
            else
                [success, data] = ioProc.loadBaselineCorrection(subject, condition, measure);
            end
            if ~success 
                wtProject.notifyErr([], 'Failed to load data for condition ''%s''', condition);
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

        function [success] = adjustPlotTimeFreqRanges(srcPlotParams, data)
            WTValidations.mustBeA(srcPlotParams, ?WTCommonPlotsCfg);
            success = false;
            wtProject = WTProject();
            wtLog = WTLog();
            
            paramsType = class(srcPlotParams);
            plotParams = copy(srcPlotParams);
            tMin = data.tim(1);
            tMax = data.tim(end);
        
            plotTimeMin = WTPlotUtils.adjustEdge(plotParams.TimeMin, data.tim);
            if plotParams.TimeMin > tMax 
                wtLog.warn('Average plots param %s.TimeMin auto-corrected to minimum sample time %d ms (was %d ms > maximum sample time)', ...
                    paramsType, plotTimeMin, plotParams.TimeMin);
            elseif plotTimeMin ~=  plotParams.TimeMin
                wtLog.warn('Average plots param %s.TimeMin adjusted to closest sample time %d ms (was %d ms)', ... 
                    paramsType, plotTimeMin, plotParams.TimeMin);
            end
        
            plotTimeMax = WTPlotUtils.adjustEdge(plotParams.TimeMax, data.tim);
            if plotParams.TimeMax < tMin 
                wtLog.warn('Average plots param %s.TimeMax auto-corrected to maximum sample time %d ms (was %d ms < minimum sample time)', ...
                    paramsType, plotTimeMax, plotParams.TimeMax);
            elseif plotTimeMin ~=  plotParams.TimeMin
                wtLog.warn('Average plots param %s.TimeMax adjusted to closest sample time %d ms (was %d ms)', ...
                    paramsType, plotTimeMax, plotParams.TimeMax);
            end
        
            if plotTimeMin > plotTimeMax 
                wtProject.notifyErr([], 'Bad average plots range %s.[TimeMin,TimeMax] = [%d,%d] after adjustments...', ...
                    paramsType, plotTimeMin, plotTimeMax);
                return
            end
        
            fMin = data.Fa(1);
            fMax = data.Fa(end);
        
            plotFreqMin = WTPlotUtils.adjustEdge(plotParams.FreqMin, data.Fa);
            if plotParams.FreqMin > fMax 
                wtLog.warn('Average plots param %s.FreqMin auto-corrected to minimum frequency %d Hz (was %d Hz > maximum frequency)', ...
                    paramsType, plotFreqMin, plotParams.FreqMin);
            elseif plotFreqMin ~=  plotParams.FreqMin
                wtLog.warn('Average plots param %s.FreqMin adjusted to closest frequency %d Hz (was %d Hz)', ...
                    paramsType, plotFreqMin, plotParams.FreqMin);
            end
        
            plotFreqMax = WTPlotUtils.adjustEdge(plotParams.FreqMax, data.Fa);
            if plotParams.FreqMax < fMin 
                wtLog.warn('Average plots param %s.FreqMax auto-corrected to maximum frequency %d Hz (was %d Hz < minimum frequency)', ...
                    paramsType, plotFreqMax, plotParams.FreqMax);
            elseif plotTimeMin ~=  plotParams.TimeMin
                wtLog.warn('Average plots param %s.FreqMax adjusted to closest frequency %d Hz (was %d Hz)', ...
                    paramsType, plotFreqMax, plotParams.FreqMax);
            end
        
            if plotFreqMin > plotFreqMax 
                wtProject.notifyErr([], 'Bad average plots range %s.[FreqMin,FreqMax] = [%d,%d] after adjustments...', ...
                    paramsType, plotFreqMin, plotFreqMax);
                return
            end
            
            function setParams(params)
                params.TimeMin = plotTimeMin;
                params.TimeMax = plotTimeMax;
                params.FreqMin = plotFreqMin;
                params.FreqMax = plotFreqMax;
            end

            setParams(plotParams);
            
            if ~plotParams.persist() 
                wtProject.notifyErr([], 'Failed to save average plots params (%s)', paramsType);
                return
            end
        
            setParams(srcPlotParams);
            success = true;
        end

        % --- Callbacks -- ON ---

        function keepWindowSizeRatioCb(hObject, event, whRatio) 
            pos = hObject.Position;
            scale = (pos(3) + pos(4) * whRatio) / 2;
            pos(3) = scale;
            pos(4) = scale / whRatio;
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

        % Keep track in the parent object of all existing children-objects & close all them
        % whenever the parent is closed. Requires to define:
        % - hParentObject.UserData.<childrenObjField>: 
        %       hChildrenObjects: list to the children of hParentObject
        % hChildrenObjects must be set by the caller.
        % To be used in pair with childObjectCloseRequestCb.
        function parentObjectCloseRequestCb(hObject, event, childrenObjField)
            try
                hChildrenObjects = WTUtils.xGetField(hObject.UserData, childrenObjField);
                arrayfun(@(hChildObj)close(hChildObj), hChildrenObjects); 
                WTUtils.xSetField('hObject.UserData', '[]', childrenObjField); 
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
                hParentObject = WTUtils.xGetField(hObject.UserData, parentObjectField);
                if isvalid(hParentObject)
                    hChildrenObjects = WTUtils.xGetField(hParentObject.UserData, childrenObjField);
                    hChildObjIdx = arrayfun(@(hObj)hObj == hObject, hChildrenObjects);
                    hChildrenObjects(hChildObjIdx) = [];

                    hParentObject.UserData.(childrenObjField) = hChildrenObjects;
                    WTUtils.xSetField('hParentObject.UserData', 'hChildrenObjects', childrenObjField);
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
                origPosition = WTUtils.xGetField(hObject.UserData, originalPositionField);
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
        function onKeyPressResizeObjectsCb(hObject, event, controlledObjectsField, originalPositionField)
            try
                hControlledObjects = WTUtils.xGetField(hObject.UserData, controlledObjectsField);
                switch event.Character
                    case '+'  
                        WTPlotUtils.resizeGraphicObjects(hControlledObjects, originalPositionField, event.Character)
                    case '-'
                        WTPlotUtils.resizeGraphicObjects(hControlledObjects, originalPositionField, event.Character)
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
        function onKeyPressResetObjectsPositionCb(hObject, event, controlledObjectsField, originalPositionField)
            try
                switch event.Character
                    case 'r' % rearrange controlled objects into the original opening position
                        hControlledObjects = WTUtils.xGetField(hObject.UserData, controlledObjectsField);
                        for i = 1:length(hControlledObjects)
                            hControlledObjects(i).Position = WTUtils.xGetField(hControlledObjects(i).UserData, originalPositionField);
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
                hControlledObjects = WTUtils.xGetField(hObject.UserData, controlledObjectsField);
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
                points = WTUtils.xGetField(hObject.UserData, pointsField); 
                [subObjectIdx, clickPosRelToSubObject] = WTPlotUtils.getClickedSubObjectIndex(hObject, points);
                
                hSubObjects = WTUtils.xGetField(hObject.UserData, subObjectsField);
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
            function cb_(hObject, event) 
                for i = 1:nargin
                    try
                        if iscell(varargin{i})
                            cbDef = varargin{i};
                            cbFun = cbDef{1};
                            cbArg = WTUtils.ifThenElse(length(cbDef) > 1, @()cbDef(2:end), {});
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

