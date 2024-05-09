classdef WTCodingUtils

    methods(Static)
        % argsName() returns the names of argument passed on as a cell array of strings.
        function cells = argsName(varargin) 
            cells = cellfun(@inputname, num2cell(1:nargin), 'UniformOutput', false);
        end

        % popOptionFromArgs() find the option with name 'option' in a varargin ('args') cell array and pop it 
        % from the cell array together with its value.
        function args = popOptionFromArgs(args, option)
            for i = 1:2:length(args)
                if ischar(args{i}) && strcmp(args{i}, option)
                    args = [args(1:i-1) args(i+2:end)];
                    return
                end
            end
        end

        % ifThenElse() implements a one line test: thenSet & elseSet can be function handles or cell arrays. When
        % - function handle => ifThenElse returns thenSet() or  elseSet()
        % - cell arrays => ifThenElse returns thenSet{:} or  elseSet{:}
        % If thenSet & elseSet are function handles or cell arrays and  have to be returned as such, then wrap them 
        % into a function. For example, here below thenSet is a function and elseSet is a cell arrays:
        % - ifThenElse(condition, @()thenSet, @()elseSet)
        function varargout = ifThenElse(condition, thenSet, elseSet) 
            varargout = cell(1, nargout);
            if condition
                if isa(thenSet,'function_handle')
                    [varargout{:}] = thenSet();
                elseif iscell(thenSet)
                    [varargout{:}] = thenSet{:};
                else
                    [varargout{:}] = thenSet;
                end
            else
                if isa(elseSet,'function_handle')
                    [varargout{:}] = elseSet();
                elseif iscell(elseSet)
                    [varargout{:}] = elseSet{:};
                else
                    [varargout{:}] = elseSet;
                end
            end
        end

        % execFunctions() executes multiple functions and collects their results. The n-th (n >= 0) function handle is expected 
        % to be the argument of index 2*n+1 of varargin, whereas its paramters are expected to be the cell array argument of
        % index 2*(n+1). The result of each function is returned as a cell array in position 2*n+1 of varargout.
        function varargout = execFunctions(varargin) 
            varargout = cell(nargin/2, 1);
            for i = 1:2:nargin
                func = varargin{i};
                args = varargin{i+1};
                nOutArgs = nargout(func);
                if nOutArgs > 0
                    result = cell(1, nOutArgs);
                    [result{:}] = func(args{:});
                    varargout{ceil(i/2)} = result;
                else
                    func(args{:});
                    varargout{ceil(i/2)} = {}; 
                end
            end
        end

        % returnValues() filters a function output.
        %  - func: must be a function reference
        %  - params: a cell array containing the func() input arguments
        %  - nOutput: the number of expected func() returned values
        %  - varargin: a cell array of indexes that select which values returned by func() should be returned by 
        % returnValues
        function varargout = returnValues(func, params, nOutput, varargin)
            output = cell(1, nOutput);
            [output{:}] = func(params{:});
            varargout = cell(1, nargin-3);
            [varargout{:}] = output{varargin{:}};
        end
        
        % throwOrLog() log the exception 'excpt' if 'log' is true or throws it otherwise.
        function throwOrLog(excpt, log)
            if log 
                WTLog().fromCaller().err('Exception(%s): %s', excpt.identifier, getReport(excpt, 'extended'));
            else
                excpt.throwAsCaller();
            end
        end
    end
end