classdef WTValidations

    methods(Static)
        function is = isa(obj, metaClass)
            if ~isa(metaClass, 'meta.class')
                WTException.badArgType('Not a meta class').throw();
            end
            is = isa(obj, metaClass.Name);
        end

        function is = isAnyOf(obj, varargin)
            is = false;
            for i = 1:nargin 
                if WTValidations.isa(obj, varargin{i}) 
                    is = true;
                    return
                end
            end
        end

        function [valid, value] = strIsNumber(str)
            str = strtrim(str);
            value = str2double(str);
            valid = ~isnan(value);
        end

        function [valid, value] = strIsEmptyOrNumber(str)
            str = strtrim(str);
            value = str2double(str);
            valid = ~isnan(value) || isempty(str);
        end

        function [valid, array] = strIsNumberArray(str)
            str = strtrim(str);
            array = str2num(str);
            valid = ~isempty(array) || isempty(str) || ~isempty(regexp(str, '^\[\s*\]$', 'once'));
        end
    
        function [valid, value] = strIsInt(str) 
            [valid, value] = WTValidations.strIsNumber(str);
            valid = valid && WTValidation.isInt(value);
        end

        function [valid, value] = strIsEmptyOrInt(str) 
            [valid, value] = WTValidations.strIsEmptyOrNumber(str);
            valid = valid && (isnan(value) || WTValidation.isInt(value));
        end

        function [valid, array] = strIsIntArray(str)
            [valid, array_] = WTValidations.strIsNumberArray(str);
            if ~valid 
                return
            end
            array = WTUtils.ifThenElse(nargout > 1, zero(size(array_)), []);
            for i = 1:numel(array_)
                if ~WTValidations.isInt(array(i))
                    valid = false;
                    break
                elseif nargout > 1
                    array(i) = value;
                end
            end
        end

        function [valid, values] = strIsNumberCellArray(strCellArray, allowEmptyStr)
            isChkr = WTUtils.ifThenElse(nargin > 1 && allowEmptyStr, ...
                @WTValidations.strIsNumber,  @WTValidations.strIsEmptyOrNumber);
            values = WTUtils.ifThenElse(nargout > 1, cell(size(strCellArray)), {});
            valid = true;

            for i = 1:numel(strCellArray)
                [valid, value] = isChkr(strCellArray{i});
                if ~valid
                    break
                elseif nargout > 1
                    values{i} = value;
                end
            end
        end

        function [valid, values] = strIsIntCellArray(strCellArray, allowEmptyStr) 
            isChkr = WTUtils.ifThenElse(nargin > 1 && allowEmptyStr, ...
                @WTValidations.strIsInt,  @WTValidations.strIsEmptyOrInt);
                values = WTUtils.ifThenElse(nargout > 1, cell(size(strCellArray)), {});
            valid = true;

            for i = 1:numel(strCellArray)
                [valid, value] = isChkr(strCellArray{i});
                if ~valid
                    break
                elseif nargout > 1
                    values{i} = value;
                end
            end
        end

        function is = isScalarInt(v)
            is = isscalar(v) && WTValidations.isInt(v);
        end 

        function is = isScalarIntGT(v, lb)
            is = isscalar(v) && WTValidations.isInt(v) && v > lb;
        end 

        function is = isScalarIntGTE(v, lb)
            is = isscalar(v) && WTValidations.isInt(v) && v >= lb;
        end

        function is = isScalarIntLT(v, ub)
            is = isscalar(v) && WTValidations.isInt(v) && v < ub;
        end 

        function is = isScalarIntLTE(v, ub)
            is = isscalar(v) && WTValidations.isInt(v) && v <= ub;
        end 

        function is = isScalarIntBetween(v, lb, ub)
            is = isscalar(v) && WTValidations.isInt(v) && v >= lb && v <= ub;
        end 

        function is = isInt(v)
            is = all(~isinf(v) & floor(v) == v);
        end 

        function is = isValidProperRange(range)
            is = WTValidations.isValidFiniteRange(range) && range(1) < range(2);
        end

        function is = isValidFiniteRange(range)
            is = WTValidations.isValidRange(range) && ~any(isinf(range));
        end

        function is = isValidRange(range)
            is = isvector(range) && isnumeric(range) && length(range) == 2 && range(1) <= range(2);
        end

        function is = isInRange(v, vMin, vMax, includeMin, includeMax)
            is = isnumeric(v) && ...
                (v > vMin || (v == vMin && includeMin)) && ...
                (v < vMax || (v == vMax && includeMax));
        end

        function is = isZeroOrOne(v)
            is = isnumeric(v) && (v == 0 || v == 1);
        end

        function is = isStrOrChar(v)
            is = isa(v, 'string') || isa(v, 'char');
        end

        function is = isEmptyStrOrChar(v)
            is = (isa(v,'char') && isempty(v)) || ...
                (isa(v, 'string') && v == "");
        end

        % minLen and/or maxLen can be < 0 => ignore them
        function is = isLinearArray(v, minLen, maxLen, allowEmpty)
            is = ismatrix(v); 
            if ~is 
                return
            end
            is = nargin > 3 && allowEmpty && isempty(v);
            if is 
                return
            end
            is = isvector(v);
            if ~is || nargin < 2
                return 
            end
            ne = numel(v);
            is = ne >= minLen;
            if ~is || nargin < 3
                return
            end
            is = maxLen < 0 || ne <= maxLen;
        end

        % minLen and/or maxLen can be < 0 => ignore them
        function is = isLinearCellArray(v, minLen, maxLen, allowEmpty)
            is = iscell(v); 
            if ~is
                return
            end
            is = nargin > 3 && allowEmpty && isempty(v);
            if is 
                return
            end
            sz = size(v);
            is = length(sz) == 2 && (sz(1) == 1 || sz(2) == 1);
            if ~is || nargin < 2
                return 
            end
            ne = numel(v);
            is = ne >= minLen;
            if ~is || nargin < 3
                return
            end
            is = maxLen < 0 || ne <= maxLen;
        end

        function is = isALimitedLinearCellArrayOfString(v, minLen, maxLen, allowEmpty)
            is = WTValidations.isLinearCellArray(v, minLen, maxLen, allowEmpty) && ...
                all(cellfun(@WTValidations.isStrOrChar, v));
        end

        function is = isALinearCellArrayOfString(v)
            is = WTValidations.isLinearCellArray(v, 0, -1, 1) && ...
                all(cellfun(@WTValidations.isStrOrChar, v));
        end 

        function is = isALimitedLinearCellArrayOfNonEmptyString(v, minLen, maxLen, allowEmpty)
            is = WTValidations.isLinearCellArray(v, minLen, maxLen, allowEmpty) && ...
                ~any(cellfun(@WTValidations.isEmptyStrOrChar, v));
        end

        function is = isALinearCellArrayOfNonEmptyString(v)
            is = WTValidations.isLinearCellArray(v, 0, -1, 1) && ...
               ~any(cellfun(@WTValidations.isEmptyStrOrChar, v));
        end

        function mustBeA(obj, metaClass)
            if ~WTValidations.isa(obj, metaClass)
                WTException.badType('Expected ''%s'', got ''%s''', ...
                    metaClass.Name, class(obj)).throw();
            end
        end

        function mustBeAnyOf(obj, varargin)
            if ~WTValidations.isAnyOf(obj, varargin{:})
                WTException.badType('Expected any of ''%s'', got ''%s''', ...
                    char(join(cellfun(@(x)x.Name, varargin))), class(obj)).throw();
            end
        end

        function mustBeInRange(v, vMin, vMax, includeMin, includeMax)
            if ~WTValidations.isInRange(v, vMin, vMax, includeMin, includeMax)
                if includeMin brkMin = '['; else brkMin = '('; end
                if includeMax brkMax = ']'; else brkMax = ')'; end
                WTException.badValue(['Value must be numeric and in the range' brkMin num2str(vMin) ',' num2str(vMax) brkMax]).throw();
            end
        end

        function mustBeLT(v, vMax, allowNaN)
            if nargin > 2 && allowNaN && isscalar(v) && isnan(v)
                return
            end
            if ~isnumeric(v) || any(v >= vMax)
                WTException.badValue(['Value must be numeric and < ' num2str(vMax)]).throw();
            end
        end

        function mustBeLTE(v, vMax, allowNaN)
            if nargin > 2 && allowNaN && isscalar(v) && isnan(v)
                return
            end
            if ~isnumeric(v) || any(v > vMax)
                WTException.badValue(['Value must be numeric and <= ' num2str(vMax)]).throw();
            end
        end

        function mustBeGT(v, vMin, allowNaN)
            if nargin > 2 && allowNaN && isscalar(v) && isnan(v)
                return
            end
            if ~isnumeric(v) || any(v <= vMin)
                WTException.badValue(['Value must be numeric and > ' num2str(vMin)]).throw();
            end
        end

        function mustBeGTE(v, vMin, allowNaN)
            if nargin > 2 && allowNaN && isscalar(v) && isnan(v)
                return
            end
            if ~isnumeric(v) || any(v < vMin)
                WTException.badValue(['Value must be numeric and >= ' num2str(vMin)]).throw();
            end
        end

        function mustBeZeroOrOne(v)
            if ~WTValidations.isZeroOrOne(v)
                WTException.badValue('Value must be 0 or 1').throw();
            end
        end

        function mustBeInt(x)
            if ~WTValidations.isInt(x)
                WTException.badValue('Value must be an integer').throw();
            end
        end

        function mustBeAStringOrChar(x)
            if ~WTValidations.isStrOrChar(x)
                WTException.badValue('Value must be a string or char array').throw();
            end
        end

        function mustBeALimitedLinearArray(v, minLen, maxLen, allowEmpty)
            if ~WTValidations.isLinearArray(v, minLen, maxLen, allowEmpty)
                WTException.badValue('Value must be a linear array of the expected length').throw();
            end 
        end

        function mustBeALimitedLinearCellArrayOfString(v, minLen, maxLen, allowEmpty)
            if ~WTValidations.isALimitedLinearCellArrayOfString(v, minLen, maxLen, allowEmpty) 
                WTException.badValue('Value must be a linear cell array of string or char and of the expected length').throw();
            end 
        end 

        function mustBeALinearCellArrayOfString(v)
            if ~WTValidations.isALinearCellArrayOfString(v)
                WTException.badValue('Value must be a linear cell array of string or char').throw();
            end 
        end 

        function mustBeALimitedLinearCellArrayOfNonEmptyString(v, minLen, maxLen, allowEmpty)
            if ~WTValidations.isALimitedLinearCellArrayOfNonEmptyString(v, minLen, maxLen, allowEmpty)
                WTException.badValue('Value must be a linear cell array of non empty string or char and of the expected length').throw();
            end
        end

        function mustBeALinearCellArrayOfNonEmptyString(v)
            if ~WTValidations.isALinearCellArrayOfNonEmptyString(v)
                WTException.badValue('Value must be a linear cell array of non empty string or char').throw();
            end
        end
    end
end