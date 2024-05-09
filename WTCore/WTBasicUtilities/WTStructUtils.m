classdef WTStructUtils 

    methods (Static, Access=private)

        function expr = buildFieldDerefExpr(varargin)
            expr = [];
            for i = 1:nargin
                if ischar(varargin{i}) 
                    expr = [ expr '.' varargin{i} ];
                else
                    expr = [ expr WTStructUtils.buildFieldDerefExpr(varargin{i}{:}) ];
                end
            end
        end
    end

    methods(Static)
        % xGetField() extracts a value from a possibly nested structure. The path to
        % the value is described by varargin. The items in varargin must either be
        % char array or cell array of char array. Examples:
        %
        %   s = struct('f1', struct('f11', 1, 'f12', struct('f121', 1)));
        %   xGetField(s, 'f1', 'f11', 'f12');       -> return 1
        %   xGetField(s, { 'f1', 'f11', 'f12' });   -> return 1
        %   xGetField(s, 'f1', {'f11', 'f12' });    -> return 1
        %   xGetField(s, 'f1', {'f11', {'f12'} });  -> return 1
        function value = xGetField(structObj, varargin)
            if nargin - 1 <= 0
                WTException.missingArg('no fields specified').throw();
            end
            if ~isstruct(structObj)
                WTException.badArg('first arg must be a struct').throw();
            end 
            eval(['value = structObj' WTStructUtils.buildFieldDerefExpr(varargin{:}) ';' ]);
        end

        % xSetField() set the value of a possibly nested structure field. The path to
        % the value is described by varargin. The items in varargin must either be
        % char array or cell array of char array. If varargout is empty, then the function
        % requires structObj to be a char array describing the name of the structure in
        % the caller namespace. In such case value must be a char array as well, describing 
        % the variable holding value to set in the caller namespace or an actual value.
        % if varagout is not empty them it must be the structure itself of which the 
        % function will modify the content, if not the structure update will be lost.
        % Examples:
        %   s = struct('f1', struct('f11', 1, 'f12', struct('f121', 1)));
        %   v = 100;
        %   s = xSetField(s, v, 'f1', 'f12', 'f121');     -> s.f1.f12.f121 = 100
        %   s = xSetField(s, v, 'f1', { 'f12', 'f121' }); -> s.f1.f12.f121 = 100
        %   xSetField('s', '999', 'f1', 'f12', 'f121');   -> s.f1.f12.f121 = 999
        %   xSetField('s', 'v', 'f1', 'f12', 'f121');     -> s.f1.f12.f121 = 100
        function structObj = xSetField(structObj, value, varargin) 
            if nargin - 2 <= 0
                WTException.missingArg('no fields specified').throw();
            end
            if nargout == 0
                if ~ischar(structObj) || ~ischar(value)
                    WTException.missingArg('an output argument must be defined').throw(); 
                end
                evalin('caller', [ char(structObj) WTStructUtils.buildFieldDerefExpr(varargin{:}) ' = ' char(value) ';' ]);
            elseif ~isstruct(structObj)
                WTException.badArg('first arg must be a struct').throw();
            else
                eval([ 'structObj' WTStructUtils.buildFieldDerefExpr(varargin{:}) ' = value;' ]); 
            end
        end
    end
end