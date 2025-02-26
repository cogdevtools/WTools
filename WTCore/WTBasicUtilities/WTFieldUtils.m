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

classdef WTFieldUtils 

    methods(Static)

        % hasFieldOrProperty() checks if a field or property exists in a structure or object.
        % The first argument must be either a structure or an object. The second argument
        % must be a char array describing the field or property name. The function returns
        % true if the field or property exists, false otherwise. If the second argument is
        % not a char array, the function throws an exception.
        function success = hasFieldOrProperty(data, field)
            success = false;
            if ~ischar(field)
                WTException.badValue('expected a valid field/property name').throw();
            end
            if isstruct(data)
                success = isfield(data, field);
            elseif isobject(data)
                for p = metaclass(data).Properties(:)';
                    if strcmp(p{1}.Name, field)
                        success = true;
                        break
                    end
                end
            else
                WTException.badValue('data must be either a structure or an object.').throw();
            end
        end

        % setFieldOrProperty() sets a field or property in a structure or object. The first
        % argument must be either a structure or an object. The second argument must be the
        % value to set. The argument that follows are cell arrays of char arrays describing
        % the path to the field or property to set. The function returns true if the field or
        % property has been set, false otherwise. If the field or property does not exist, the
        % function does nothing. 
        % Examples:
        %   s = struct('f1', struct('f11', 1, 'f12', struct('f121', 1)));
        %   [s, success] = setFieldOrProperty(s, 100, 'f1', 'f12', 'f121'); 
        %       -> s.f1.f12.f121 = 100
        %   [s, success] = setFieldOrProperty(s, 100, 'f1', {'f12', 'f121' }); 
        %       -> s.f1.f12.f121 = 100
        %   [s, success] = setFieldOrProperty(s, 100, 'f1', {'f12', {'f121'} }); 
        %       -> s.f1.f12.f121 = 100
        function [data, success] = setFieldOrProperty(data, value, varargin)
            success = false;
            if nargin == 0
                return
            end
            field = varargin{1};
            if iscell(field)
                [data, success] = WTFieldUtils.setFieldOrProperty(data, value, field{:}, varargin{2:end});
            elseif ischar(field) && ismember('.', field)
                field = strsplit(field, '.');
                [data, success] = WTFieldUtils.setFieldOrProperty(data, value, field{:}, varargin{2:end});
            elseif ~WTFieldUtils.hasFieldOrProperty(data, field)
                return
            elseif length(varargin) > 1
                [data.(field), success] = WTFieldUtils.setFieldOrProperty(data.(field), value, varargin{2:end});
            else
                data.(field) = value;
                success = true;
            end
        end

        % mustSetFieldOrProperty() sets a field or property in a structure or object. It calls 
        % setFieldOrProperty() and throws an exception if the field or property could not be set.
        function data = mustSetFieldOrProperty(data, value, varargin)
            [data, success] = WTFieldUtils.setFieldOrProperty(data, value, varargin{:});
            if ~success
                WTException.badArg('could not set field or property: check the arguments').throw();
            end
        end

        % getFieldOrProperty() gets a field or property from a structure or object. The first
        % argument must be either a structure or an object. The argument that follows are cell
        % arrays of char arrays describing the path to the field or property to get. The function
        % returns the value of the field or property if it exists, false otherwise. If the field or
        % property does not exist, the function returns false.
        % Examples:
        %   s = struct('f1', struct('f11', 1, 'f12', struct('f121', 1)));
        %   [value, success] = getFieldOrProperty(s, 'f1', 'f12', 'f121');
        %       -> return 1
        %   [value, success] = getFieldOrProperty(s, 'f1', {'f12', 'f121' });
        %       -> return 1
        %   [value, success] = getFieldOrProperty(s, 'f1', {'f12', {'f121'} });
        %       -> return 1
        function [value, success] = getFieldOrProperty(data, varargin)
            success = false;
            if nargin == 0
                return
            end
            field = varargin{1};
            if iscell(field)
                [value, success] = WTFieldUtils.getFieldOrProperty(data, field{:}, varargin{2:end});
            elseif ischar(field) && ismember('.', field)
                field = strsplit(field, '.');
                [value, success] = WTFieldUtils.getFieldOrProperty(data, field{:}, varargin{2:end});
            elseif ~WTFieldUtils.hasFieldOrProperty(data, field)
                return
            elseif length(varargin) > 1
                [value, success] = WTFieldUtils.getFieldOrProperty(data.(field), varargin{2:end});
            else
                value = data.(field);
                success = true;
            end
        end

        % mustGetFieldOrProperty() gets a field or property from a structure or object. It calls
        % getFieldOrProperty() and throws an exception if the field or property could not be retrieved.
        function value = mustGetFieldOrProperty(data, varargin)
            [value, success] = WTFieldUtils.getFieldOrProperty(data, varargin{:});
            if ~success
                WTException.badArg('could not get field or property: check the arguments').throw();
            end
        end

        % setFieldOrPropertyFrom() sets a field or property in a destination structure or object
        % from a source structure or object. The first argument must be either a structure or an
        % object. The second argument must be a char array describing the field or property name
        % in the source structure or object. The third argument must be the destination structure
        % or object. The fourth argument must be a char array describing the field or property name
        % in the destination structure or object. The function returns true if the field or property
        % has been set, false otherwise. If the field or property does not exist, the function does 
        % nothing. 
        % Examples:
        %   s1 = struct('f1', struct('f11', 1, 'f12', struct('f121', 1)));
        %   s2 = struct('f1', struct('f11', 2, 'f12', struct('f121', 2)));
        %   [s2, success] = setFieldOrPropertyFrom(s2, 'f1', s1, 'f1');
        %       -> s2.f1 = s1.f1
        %   [s2, success] = setFieldOrPropertyFrom(s1, {'f1','f11'}, s2, {'f1', f12', 'f121'});
        %       -> s2.f1.f11 = s2.f1.f12.f121
        function [dst, success] = setFieldOrPropertyFrom(dst, dstFld, src, srcFld)
            [value, success] = WTFieldUtils.getFieldOrProperty(src, srcFld);
            if success 
                [dst, success] = WTFieldUtils.setFieldOrProperty(dst, value, dstFld);
            end
        end

        % mustSetFieldOrPropertyFrom() sets a field or property in a destination structure or object
        % from a source structure or object. It calls setFieldOrPropertyFrom() and throws an exception
        % if the field or property could not be set.
        function dst = mustSetFieldOrPropertyFrom(dst, dstFld, src, srcFld)
            [value, success] = WTFieldUtils.setFieldOrPropertyFrom(dst, dstFld, src, srcFld);
            if ~success
                WTException.badArg('could not set/get field or property: check the arguments').throw();
            end
        end

        % setSameFieldOrPropertyFrom() sets the same field or property in a destination structure or object
        % from multiple source structures or objects. It calls setFieldOrPropertyFrom().
        function [dst, success] = setSameFieldOrPropertyFrom(dst, src, varargin)
            success = true;
            for i = 1:length(varargin)
                [dst, ok] =  WTFieldUtils.setFieldOrPropertyFrom(dst, varargin{i}, src, varargin{i});
                success = success && ok;
            end
        end

        % mustSetSameFieldOrPropertyFrom() sets the same field or property in a destination structure or object
        % from a source structure or object. It calls setSameFieldOrPropertyFrom() and throws an exception
        % if the field or property could not be set.
        function dst = mustSetSameFieldOrPropertyFrom(dst, src, varargin)
            [value, success] = WTFieldUtils.setSameFieldOrPropertyFrom(dst, src, varargin{:});
            if ~success
                WTException.badArg('could not set/get same field or property: check the arguments').throw();
            end
        end
    end
end