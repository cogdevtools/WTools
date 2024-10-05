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

classdef WTConfigUtils

    methods(Static, Access=private)

        % Adjust 'edge' to the closest value in the ORDERED vector 'values'.
        function adjEdge = adjustEdge(edge, values)
            edgeL = WTNumUtils.cast(values(find(values <= edge, 1, 'last')), 'like', edge);
            edgeR = WTNumUtils.cast(values(find(values >= edge, 1, 'first')), 'like', edge);
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

        % adjustRange() adjust a field range, based on a domain defined by series of values.
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
                WTValidations.mustBeLimitedLinearArray(params.Domain, 2, -1, 0);

                if isempty(params.Domain) 
                    wtProject.notifyErr([],'Empty domain for range %s, %s', ...
                        WTCodingUtils.ifThenElse(hasNameMin, ['[' params.NameMin], '(-inf'), ...
                        WTCodingUtils.ifThenElse(hasNameMax, [params.NameMax ']'], '+inf)'));
                    return
                end

                vMin = params.Domain(1);
                vMax = params.Domain(end);

                if hasRangeMin
                    vMinAdj = WTConfigUtils.adjustEdge(params.RangeMin, params.Domain);
                    if params.RangeMin > vMax 
                        wtLog.warn('Param %s corrected to minimum value %s %s (was %s > maximum value)', ...
                            params.NameMin, num2str(vMinAdj), params.Dimension, num2str(params.RangeMin));
                    elseif vMinAdj ~=  params.RangeMin
                        wtLog.warn('Param %s adjusted to closest value %s %s (was %s)', ... 
                            params.NameMin, num2str(vMinAdj), params.Dimension, num2str(params.RangeMin));
                    end
                    params.RangeMin = vMinAdj;
                end

                if hasRangeMax
                    vMaxAdj = WTConfigUtils.adjustEdge(params.RangeMax, params.Domain);
                    if params.RangeMax < vMin 
                        wtLog.warn('Param %s corrected to maximum value %s %s (was %s < minimum value)', ...
                            params.NameMax, num2str(vMaxAdj), params.Dimension, num2str(params.RangeMax));
                    elseif vMaxAdj ~=  params.RangeMax
                        wtLog.warn('Param %s adjusted to closest value %s %s (was %s)', ... 
                            params.NameMax, num2str(vMaxAdj), params.Dimension, num2str(params.RangeMax));
                    end
                    params.RangeMax = vMaxAdj;
                end

                if hasRangeMin && hasRangeMax && vMinAdj > vMaxAdj 
                    wtProject.notifyErr([],'Bad range [%s,%s] = [%s,%s] after adjustments', ...
                        params.NameMin, params.NameMax, num2str(vMinAdj), num2str(vMaxAdj));
                    return
                end

                if hasResolution 
                    minResolution = WTNumUtils.cast(params.Domain(2), 'like', vMin) - vMin;
                    adjResolution = floor(params.Resolution / minResolution) * minResolution;

                    if params.Resolution < minResolution
                        wtLog.warn('Param %s corrected to minimum value %s %s (was %s < minimum value)', ... 
                            params.NameResolution, num2str(minResolution), params.Dimension, num2str(params.Resolution));
                        params.Resolution = WTNumUtils.cast(minResolution, 'like', params.Resolution);
                    elseif params.Resolution ~= adjResolution
                        wtLog.warn('Param %s adjusted to closest value %s %s (was %s)', ... 
                            params.NameResolution, num2str(adjResolution), params.Dimension, num2str(params.Resolution));
                        params.Resolution = WTNumUtils.cast(adjResolution, 'like', params.Resolution);
                    end
                end
            catch me
                wtLog.except(me);
                wtProject.notifyErr([], 'Failed to adjust range params due to unexpected error');
                return
            end
            success = true;
        end
    end

    methods(Static)

        function [success] = adjustTimeFreqDomains(params, data)
            WTValidations.mustBe(params, ?WTTimeFreqCfg);
            params.validate(true);
            objType = class(params);

            paramsTime = struct( ...
                'Domain', data.tim, ... 
                'Dimension', 'ms', ...
                'RangeMin', params.TimeMin, ...
                'RangeMax', params.TimeMax, ...
                'NameMin', [objType, '.TimeMin'], ...
                'NameMax', [objType, '.TimeMax']);

            [success, paramsTime] = WTConfigUtils.adjustRange(paramsTime);
            if ~success 
                return
            end

            paramsFreq = struct( ...
                'Domain', data.Fa, ... 
                'Dimension', 'Hz', ...
                'RangeMin', params.FreqMin, ...
                'RangeMax', params.FreqMax, ...
                'NameMin', [objType, '.FreqMin'], ...
                'NameMax', [objType, '.FreqMax']);

            [success, paramsFreq] = WTConfigUtils.adjustRange(paramsFreq);
            if ~success 
                return
            end

            function setParams(params)
                params.TimeMin = paramsTime.RangeMin;
                params.TimeMax = paramsTime.RangeMax;
                params.FreqMin = paramsFreq.RangeMin;
                params.FreqMax = paramsFreq.RangeMax;
            end

            newParams = copy(params);
            setParams(newParams);
            success = newParams.validate() && newParams.persist(); 

            if ~success
                WTProject().notifyErr([], 'Failed to validate & save params (%s)', objType);
                return
            end
        
            setParams(params);
            success = true;
        end

        function [success] = adjustPacedTimeFreqDomains(params, data)
            WTValidations.mustBe(params, ?WTPacedTimeFreqCfg);
            params.validate(true);
            objType = class(params);
           
            paramsTime = struct( ...
                'Domain', data.tim, ... 
                'Dimension', 'ms', ...
                'RangeMin', params.TimeMin, ...
                'NameMin', [objType, '.Time(1)']);

            if ~isempty(params.TimeMax)
                paramsTime.RangeMax = params.TimeMax;
                paramsTime.NameMax = [objType, '.Time(end)'];
            end
            if ~isempty(params.TimeResolution) 
                paramsTime.Resolution = params.TimeResolution;
                paramsTime.NameResolution = [objType, '.Time(2)'];
            end

            [success, paramsTime] = WTConfigUtils.adjustRange(paramsTime);
            if ~success 
                return
            end

            paramsFreq = struct( ...
                'Domain', data.Fa, ... 
                'Dimension', 'Hz', ...
                'RangeMin', params.FreqMin, ...
                'NameMin', [objType, '.Frequency(1)']);

            if ~isempty(params.FreqMax)
                paramsFreq.RangeMax = params.FreqMax;
                paramsFreq.NameMax = [objType, '.Frequency(end)'];
            end
            if ~isempty(params.FreqResolution) 
                paramsFreq.Resolution = params.FreqResolution;
                paramsFreq.NameResolution = [objType, '.Frequency(2)'];
            end

            [success, paramsFreq] = WTConfigUtils.adjustRange(paramsFreq);
            if ~success 
                return
            end

            function setParams(params)
                params.setTimeMin(paramsTime.RangeMin);
                if ~isempty(params.TimeMax)
                    params.setTimeMax(paramsTime.RangeMax);
                end    
                if ~isempty(params.TimeResolution) 
                    params.setTimeResolution(paramsTime.Resolution);
                end
                params.setFreqMin(paramsFreq.RangeMin);
                if ~isempty(params.FreqMax)
                    params.setFreqMax(paramsFreq.RangeMax);
                end 
                if ~isempty(params.FreqResolution) 
                    params.setFreqResolution(paramsFreq.Resolution);
                end
            end

            newParams = copy(params);
            setParams(newParams);
            success = newParams.validate() && newParams.persist(); 

            if ~success
                WTProject().notifyErr([], 'Failed to validate & save params (%s)', objType);
                return
            end
        
            setParams(params);
            success = true;
        end
    end
end
