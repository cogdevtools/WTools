classdef WTValidations

    methods(Static)
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

        function is = isInClosedRange(v, vMin, vMax)
            is = isnumeric(v) && v >= vMin || v <= vMax;
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

        function is = isLinearCellArray(v, minLen, maxLen)
            sz = size(v);
            is = iscell(v) && (isempty(v) || ...
                (length(sz) == 2 && (sz(1) == 1 || sz(2) == 1))) || ...
                (nargin > 1 && length(v) >= minLen) || ...
                (nargin > 2 && length(v) <= maxLen);
        end

        function is = isALimitedLinearCellArrayOfString(v, minLen, maxLen)
            is = WTValidations.isLinearCellArray(v, minLen, maxLen) && ...
                all(cellfun(@WTValidations.isStrOrChar, v));
        end

        function is = isALinearCellArrayOfString(v)
            is = WTValidations.isLinearCellArray(v) && ...
                all(cellfun(@WTValidations.isStrOrChar, v));
        end 

        function is = isALimitedLinearCellArrayOfNonEmptyString(v, minLen, maxLen)
            is = WTValidations.isLinearCellArray(v, minLen, maxLen) && ...
                ~any(cellfun(@WTValidations.isEmptyStrOrChar, v));
        end

        function is = isALinearCellArrayOfNonEmptyString(v)
            is = WTValidations.isLinearCellArray(v) && ...
               ~any(cellfun(@WTValidations.isEmptyStrOrChar, v));
        end

        function mustBeInClosedRange(v, vMin, vMax)
            if ~WTValidations.isInClosedRange(v, vMin, vMax)
                error(['Value must be numeric and in the range [' num2str(vMin) ',' num2str(vMax) ']'])
            end
        end

        function mustBeGT(v, vMin, allowNaN, allowMinNaN)
            if nargin > 2 && any(logical(allowNaN)) && ~isfinite(v)
                return
            end
            if ~isnumeric(v) && v <= vMin
                error(['Value must be numeric and < ' num2str(vMin)])
            end
        end

        function mustBeGTE(v, vMin, allowNaN)
            if nargin > 2 && any(logical(allowNaN)) && ~isfinite(v)
                return
            end
            if ~isnumeric(v) && v < vMin
                error(['Value must be numeric and < ' num2str(vMin)])
            end
        end

        function mustBeZeroOrOne(v)
            if ~WTValidations.isZeroOrOne(v)
                error('Value must be 0 or 1')
            end
        end

        function mustBeAStringOrChar(x)
            if ~WTValidations.isStrOrChar(x)
                error('Value must be a string or char array')
            end
        end

        function mustBeALimitedLinearCellArrayOfString(v, minLen, maxLen)
            if ~WTValidations.isALimitedLinearCellArrayOfString(v, minLen, maxLen)
                error('Value must be a linear cell array of string or char and of the expected length')
            end 
        end 

        function mustBeALinearCellArrayOfString(v)
            if ~WTValidations.isALinearCellArrayOfString(v)
                error('Value must be a linear cell array of string or char')
            end 
        end 

        function mustBeALimitedLinearCellArrayOfNonEmptyString(v, minLen, maxLen)
            if ~WTValidations.isALimitedLinearCellArrayOfNonEmptyString(v, minLen, maxLen)
                error('Value must be a linear cell array of non empty string or char and of the expected length')
            end
        end

        function mustBeALinearCellArrayOfNonEmptyString(v)
            if ~WTValidations.isALinearCellArrayOfNonEmptyString(v)
                error('Value must be a linear cell array of non empty string or char')
            end
        end
    end
end