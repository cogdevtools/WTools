classdef WTPlotUtils

    methods(Static, Access=private)
        
        function matVer = normalizedMatlabVersion()
            persistent vers

            if ~isempty(vers)
                matVer = vers;
                return
            end
            % same as in eeglab's icadefs.m
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

        % adjustRange() adjust a plot field range, based on a domain defined by series of values.
        % It receives and update a structure with the following fields:
        % following fied
        % - Domain: equally spaced values domain (a non empty array of equally distant values)
        % - RangeMin: min value of the range [optional, mandatory with Resolution
        % - RangeMax: max value of the range  [optional, mandatory with Resolution]
        % - Resolution: resolution of the range (i.e. delta between one value and the following) [optional]
        % - Dimension: dimension of the field, for messaging (ex: ms, Hz...)
        % - NameMin: name of the min range value, for messaging [optional, mandatory with RangeMin]
        % - NameMax: name of the max range value, for messaging [optional, mandatory with RangeMax]
        function [success, params] = adjustRange(params)
            success = false;
            wtProject = WTProject();
            wtLog = WTLog();
            
            hasRangeMin = isfield(params, 'RangeMin');
            hasRangeMax = isfield(params, 'RangeMax');
            hasResolution = isfield(params, 'Resolution');
            hasNameMin = isfield(params, 'NameMin');
            hasNameMax = isfield(params, 'NameMax');
            hasNameResolution =  isfield(params, 'NameResolution');

            if ~isfield(params, 'Domain') || ~isfield(params, 'Dimension')
                WTException.badArg('Data struct misses fields Domain and/or Dimension').throw();
            elseif ~hasRangeMin && ~hasRangeMax
                WTException.badArg('Data struct misses both fields RangeMax & RangeMin').throw();
            elseif hasResolution && ~(hasRangeMin && hasRangeMax) 
                WTException.badArg('Data struct field Resolution requires both fields RangeMax & RangeMin').throw();
            elseif hasRangeMin && ~hasNameMin 
                WTException.badArg('Data struct field RangeMin requires field NameMin').throw();
            elseif hasRangeMax && ~hasNameMax 
                WTException.badArg('Data struct field RangeMax requires field NameMax').throw();
            elseif hasResolution && ~hasNameResolution
                WTException.badArg('Data struct field Resolution requires field NameResolution').throw();
            end

            try
                WTValidations.mustBeALimitedLinearArray(params.Domain, 2, -1, 0);

                if isempty(params.Domain) 
                    wtProject.notifyErr([],'Empty domain for range %s, %s', ...
                        WTUtils.ifThenElse(hasNameMin, ['[' params.NameMin], '(-inf'), ...
                        WTUtils.ifThenElse(hasNameMax, [params.NameMax ']'], '+inf)'));
                    return
                end

                vMin = params.Domain(1);
                vMax = params.Domain(end);

                if hasRangeMin
                    vMinAdj = WTPlotUtils.adjustEdge(params.RangeMin, params.Domain);
                    if params.RangeMin > vMax 
                        wtLog.warn('Plot param %s corrected to minimum value %s %s (was %s > maximum value)', ...
                            params.NameMin, num2str(vMinAdj), params.Dimension, num2str(params.RangeMin));
                    elseif vMinAdj ~=  params.RangeMin
                        wtLog.warn('Plot param %s adjusted to closest value %s %s (was %s)', ... 
                            params.NameMin, num2str(vMinAdj), params.Dimension, num2str(params.RangeMin));
                    end
                    params.RangeMin = vMinAdj;
                end

                if hasRangeMax
                    vMaxAdj = WTPlotUtils.adjustEdge(params.RangeMax, params.Domain);
                    if params.RangeMax < vMin 
                        wtLog.warn('Plot param %s corrected to maximum value %s %s (was %s < minimum value)', ...
                            params.NameMax, num2str(vMaxAdj), params.Dimension, num2str(params.RangeMax));
                    elseif vMaxAdj ~=  params.RangeMax
                        wtLog.warn('Plot param %s adjusted to closest value %s %s (was %s)', ... 
                            params.NameMax, num2str(vMaxAdj), params.Dimension, num2str(params.RangeMax));
                    end
                    params.RangeMax = vMaxAdj;
                end

                if hasRangeMin && hasRangeMax && vMinAdj > vMaxAdj 
                    wtProject.notifyErr([],'Bad plot range [%s,%s] = [%s,%s] after adjustments', ...
                        params.NameMin, params.NameMax, num2str(vMinAdj), num2str(vMaxAdj));
                    return
                end

                if hasResolution 
                    minResolution = params.Domain(2) - vMin;
                    adjResolution = floor(params.Resolution / minResolution) * minResolution;

                    if params.Resolution < minResolution
                        wtLog.warn('Plot param %s corrected to minimum value %s %s (was %s < minimum value)', ... 
                            params.NameResolution, num2str(minResolution), params.Dimension, num2str(params.Resolution));
                        params.Resolution = minResolution;
                    elseif params.Resolution ~= adjResolution
                        wtLog.warn('Plot param %s adjusted to closest value %s %s (was %s)', ... 
                            params.NameResolution, num2str(adjResolution), params.Dimension, num2str(params.Resolution));
                        params.Resolution = adjResolution;
                    end
                end
            catch me
                wtLog.except(me)
                wtProject.notifyErr([], 'Failed to adjust plot range params due to unexpected error');
                return
            end
            success = true;
        end
    end

    methods(Static)

        % checkDiffAndGrandAvg() checks whether the data are up to date and ready for the grand average  
        function [diffConsistency, grandAvgConsistency] = checkDiffAndGrandAvg(conditions, chkGrandAvg)
            chkGrandAvg = nargin < 2 || chkGrandAvg;
            diffConsistency = 1;
            grandAvgConsistency = 1;
            
            wtProject = WTProject();
            conditionsGrandPrms = wtProject.Config.ConditionsGrand;
            logFlag = wtProject.Config.WaveletTransform.LogarithmicTransform || ...
                wtProject.Config.BaselineChop.Log10Enable;
           
            if any(ismember(conditions, conditionsGrandPrms.ConditionsDiff))
                differencePrms = wtProject.Config.Difference;
                if logical(differencePrms.LogDiff) ~= logFlag
                    wtProject.notifyWrn([], ['The [Difference] paramaters are not up to date.\n' ...
                        'Run [Difference] again before plotting.'])
                    diffConsistency = 0;
                end        
            end
        
            if chkGrandAvg
                grandAveragePrms = wtProject.Config.GrandAverage;
                if logical(grandAveragePrms.Log10Enable) ~= logFlag
                    wtProject.notifyWrn([], ['The [Grand Average] paramaters are not up to date.\n' ...
                        'Run [Grand Average] again before plotting.'])
                    grandAvgConsistency = 0;
                end
            end
        end

        % waitUIs() wait for all UI objects to terminate
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
        % returns a cell array sorting their position [x y w h] on screen. The positions are such that the 
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
            srcPlotParams.validate(true);
            objType = class(srcPlotParams);

            paramsTime = struct( ...
                'Domain', data.tim, ... 
                'Dimension', 'ms', ...
                'RangeMin', srcPlotParams.TimeMin, ...
                'RangeMax', srcPlotParams.TimeMax, ...
                'NameMin', [objType, '.TimeMin'], ...
                'NameMax', [objType, '.TimeMax']);

            [success, paramsTime] = WTPlotUtils.adjustRange(paramsTime);
            if ~success 
                return
            end

            paramsFreq = struct( ...
                'Domain', data.Fa, ... 
                'Dimension', 'Hz', ...
                'RangeMin', srcPlotParams.FreqMin, ...
                'RangeMax', srcPlotParams.FreqMax, ...
                'NameMin', [objType, '.FreqMin'], ...
                'NameMax', [objType, '.FreqMax']);

            [success, paramsFreq] = WTPlotUtils.adjustRange(paramsFreq);
            if ~success 
                return
            end

            function setParams(params)
                params.TimeMin = paramsTime.RangeMin;
                params.TimeMax = paramsTime.RangeMax;
                params.FreqMin = paramsFreq.RangeMin;
                params.FreqMax = paramsFreq.RangeMax;
            end

            plotParams = copy(srcPlotParams);
            setParams(plotParams);
            success = plotParams.validate() && plotParams.persist(); 

            if ~success
                WTProject().notifyErr([], 'Failed to validate & save plot params (%s)', objType);
                return
            end
        
            setParams(srcPlotParams);
            success = true;
        end

        function [success] = adjustScalpMapPlotTimeFreqRanges(srcPlotParams, data)
            WTValidations.mustBeA(srcPlotParams, ?WTCommonScalpMapPlotsCfg);
            srcPlotParams.validate(true);
            objType = class(srcPlotParams);
           
            paramsTime = struct( ...
                'Domain', data.tim, ... 
                'Dimension', 'ms', ...
                'RangeMin', srcPlotParams.TimeMin, ...
                'NameMin', [objType, '.Time(1)']);

            if ~isempty(srcPlotParams.TimeMax)
                paramsTime.RangeMax = srcPlotParams.TimeMax;
                paramsTime.NameMax = [objType, '.Time(end)'];
            end
            if ~isempty(srcPlotParams.TimeResolution) 
                paramsTime.Resolution = srcPlotParams.TimeResolution;
                paramsTime.NameResolution = [objType, '.Time(2)'];
            end

            [success, paramsTime] = WTPlotUtils.adjustRange(paramsTime);
            if ~success 
                return
            end

            paramsFreq = struct( ...
                'Domain', data.Fa, ... 
                'Dimension', 'Hz', ...
                'RangeMin', srcPlotParams.FreqMin, ...
                'NameMin', [objType, '.Freq(1)']);

            if ~isempty(srcPlotParams.FreqMax)
                paramsFreq.RangeMax = srcPlotParams.FreqMax;
                paramsFreq.NameMax = [objType, '.Freq(end)'];
            end
            if ~isempty(srcPlotParams.FreqResolution) 
                paramsFreq.Resolution = srcPlotParams.FreqResolution;
                paramsFreq.NameResolution = [objType, '.Freq(2)'];
            end

            [success, paramsFreq] = WTPlotUtils.adjustRange(paramsFreq);
            if ~success 
                return
            end

            function setParams(params)
                params.setTimeMin(paramsTime.RangeMin);
                if ~isempty(srcPlotParams.TimeMax)
                    params.setTimeMax(paramsTime.RangeMax);
                end    
                if ~isempty(srcPlotParams.TimeResolution) 
                    params.setTimeResolution(paramsTime.Resolution);
                end
                params.setFreqMin(paramsFreq.RangeMin);
                if ~isempty(srcPlotParams.FreqMax)
                    params.setFreqMax(paramsFreq.RangeMax);
                end 
                if ~isempty(srcPlotParams.FreqResolution) 
                    params.setFreqResolution(paramsFreq.Resolution);
                end
            end

            plotParams = copy(srcPlotParams);
            setParams(plotParams);
            success = plotParams.validate() && plotParams.persist(); 

            if ~success
                WTProject().notifyErr([], 'Failed to validate & save scalp map plot params (%s)', objType);
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


