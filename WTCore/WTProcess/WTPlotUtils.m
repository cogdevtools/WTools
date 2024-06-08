classdef WTPlotUtils

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
            WTValidations.mustBeGTE(nFigures, 1, false);
            WTValidations.mustBeGT(whRatio, 0);
            WTValidations.mustBeInRange(rWidth, 0, 1, false, true);
            WTValidations.mustBeInRange(rWidthOffs, 0, 1, true, true);
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

        function params = getYLabelParams(logFlag) 
            params = struct();
            params.String = WTCodingUtils.ifThenElse(logFlag, '% change', '\muV');
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
            params.Position = WTCodingUtils.ifThenElse(verLessThan('matlab', '8.4'), 5, 2);
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
            if strcmp(hObject.WindowState, 'fullscreen')
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
            subFigures = WTStructUtils.xGetField(hObject.UserData, childrenObjField);
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
                hChildrenObjects = WTStructUtils.xGetField(hObject.UserData, childrenObjField);
                arrayfun(@closeChild, hChildrenObjects); 
                WTStructUtils.xSetField('hObject.UserData', '[]', childrenObjField); 
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
                hParentObject = WTStructUtils.xGetField(hObject.UserData, parentObjectField);
                if isvalid(hParentObject)
                    hChildrenObjects = WTStructUtils.xGetField(hParentObject.UserData, childrenObjField);
                    hChildObjIdx = arrayfun(@(hObj)hObj == hObject, hChildrenObjects);
                    hChildrenObjects(hChildObjIdx) = [];

                    hParentObject.UserData.(childrenObjField) = hChildrenObjects;
                    WTStructUtils.xSetField('hParentObject.UserData', 'hChildrenObjects', childrenObjField);
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
                origPosition = WTStructUtils.xGetField(hObject.UserData, originalPositionField);
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
                hControlledObjects = WTStructUtils.xGetField(hObject.UserData, controlledObjectsField);
                key = lower(event.Character);
                switch key
                    case keyPlus  
                        WTPlotUtils.resizeGraphicObjects(hControlledObjects, originalPositionField, character)
                    case KeyMinus
                        WTPlotUtils.resizeGraphicObjects(hControlledObjects, originalPositionField, character)
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
                        hControlledObjects = WTStructUtils.xGetField(hObject.UserData, controlledObjectsField);
                        for i = 1:length(hControlledObjects)
                            hControlledObjects(i).Visible = 'on';
                            hControlledObjects(i).Position = WTStructUtils.xGetField(hControlledObjects(i).UserData, originalPositionField);
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
                        hTargetObject = WTStructUtils.xGetField(hObject.UserData, targetObjectField);
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
                        targetObjects = WTStructUtils.xGetField(hObject.UserData, targetObjectsField);
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
                        targetObjects = WTStructUtils.xGetField(hObject.UserData, targetObjectsField);
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
                    hTargetObject = WTStructUtils.xGetField(hObject.UserData, targetObjectField);
                end
                if ~isempty(poolObjectsField)
                    hPoolObjects = WTStructUtils.xGetField(hObject.UserData, poolObjectsField);
                    visibleObjects = cellfun(@(hObj)isvalid(hObj) && strcmp(hObj.Visible, 'on'), hPoolObjects);
                    hPoolObjects = hPoolObjects(visibleObjects);
                    if (length(hPoolObjects) == 1 && hPoolObjects{1} == hTargetObject && strcmp(visible, 'off'))
                        return
                    end
                end
                if isvalid(hTargetObject)
                    hTargetObject.Visible = visible;
                end
                hChildrenObjects = WTStructUtils.xGetField(hObject.UserData, targetChildrenField);
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
                hControlledObjects = WTStructUtils.xGetField(hObject.UserData, controlledObjectsField);
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
                points = WTStructUtils.xGetField(hObject.UserData, pointsField); 
                [subObjectIdx, clickPosRelToSubObject] = WTPlotUtils.getClickedSubObjectIndex(hObject, points);
                
                hSubObjects = WTStructUtils.xGetField(hObject.UserData, subObjectsField);
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
            nArgIn = nargin;

            function cb_(hObject, event) 
                for i = 1:nArgIn
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


