classdef WTNumUtils

    methods(Static)

        function value = str2double(str, allowEmptyStr)
            allowEmptyStr = nargin > 1 && allowEmptyStr;
            if allowEmptyStr
                [valid, value] = WTValidations.strIsEmptyOrNumber(str);
            else
                [valid, value] = WTValidations.strIsNumber(str);
            end
            if ~valid
                WTException.badValue('Not a valid string representation of a number: %s', WTCodingUtils.ifThenElse(ischar(str), str, '<?>')).throw();
            end
        end

        function value = str2int(str, allowEmptyStr)
            allowEmptyStr = nargin > 1 && allowEmptyStr;
            if allowEmptyStr
                [valid, value] = WTValidations.strIsEmptyOrInt(str);
            else 
                [valid, value] = WTValidations.strIsInt(str);
            end
            if ~valid
                WTException.badValue('Not a valid string representation of an integer: %s', WTCodingUtils.ifThenElse(ischar(str), str, '<?>')).throw();
            end
        end

        function array = str2nums(str)
            [valid, array] = WTValidations.strIsNumberArray(str);
            if ~valid 
                WTException.badValue('Not a valid string representation of numbers: %s', WTCodingUtils.ifThenElse(ischar(str), str, '<?>')).throw();
            end
        end

        function array = str2ints(str)
            [valid, array] =  WTValidations.strIsIntArray(str);
            if ~valid 
                WTException.badValue('Not a valid string representation of integers: %s', WTCodingUtils.ifThenElse(ischar(str), str, '<?>')).throw();
            end
        end

        % str2numsRep() makes a numeric array out of a string describing a set of numbers which are expressed 
        % as (possible paced) range one of the forms: '[x]' '[x:y]' '[x:y:z]' '[x y]' '[x y z]', with or without
        % or the square brackets depending on if the parameter 'format': format = '[]' (with), format = ']['
        % (without), format = <anything else> (indifferent). Empty strings are not valid.
        function rng = str2numsRep(inStr, format)
            format = WTCodingUtils.ifThenElse(nargin < 2, '', format);
            rng = [];

            if ~ischar(inStr) || ~ischar(format)
                WTException.badArg('Input parameters must be char arrays', inStr).throw()
            end

            excp = WTException.badValue('Not a valid string representation of numbers: ''%s''', inStr);
            str = strip(inStr);

            if isempty(str)
                excp.throw();
            end

            enclosed = str(1) == '[' && str(end) == ']';
            
            if (strcmp(format,'[]') && ~enclosed) ||  (strcmp(format,'][') && enclosed)
                excp.throw();
            end
            if enclosed
                str = strip(str(2:end-1));
            end
            splitStr = strip(split(str, ':'));
            if length(splitStr) > 3 
                excp.throw();
            end
            if length(splitStr) == 1
                splitStr = strsplit(str);
            end
            rng(1) = WTNumUtils.str2nums(splitStr{1});
            if length(splitStr) > 1
                if isempty(splitStr{2})
                    excp.throw();
                end
                rng(2) = WTNumUtils.str2nums(splitStr{2});
            end
            if length(splitStr) > 2
                if isempty(splitStr{3})
                    excp.throw();
                end
                rng(3) = WTNumUtils.str2nums(splitStr{3});
            end
        end
    end
end