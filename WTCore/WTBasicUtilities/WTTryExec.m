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

classdef WTTryExec < handle

    properties(GetAccess = public)
        Succeeded logical
        Recovered logical
        Result
    end

    properties(Dependent, GetAccess = public)
        Unrecovered
        Managed
    end

    properties(Access = private)
        Run
        Log
        Display
        ReThrow
        Recover
    end

    methods(Access = private)
        function f = setFunctionBasic(o, funct, varargin)
            if ~isa(funct, 'function_handle')
                WTException.badValue("not a function handle");
            end
            f = struct();
            f.Function = funct;
            f.Args = varargin;
        end

        function f = setFunction(o, funct, varargin)
            f = o.setFunctionBasic(funct, varargin{:});
            f.Exec = @()f.Function(f.Args{:});
        end

        function f = setFunctionWithExcptArg(o, funct, varargin)
            f = o.setFunctionBasic(funct, varargin{:});
            f.Exec = @(me)f.Function(me, f.Args{:});
        end

        function log = logException(o, level, extendedReport) 
            log = @(me, level, extendedReport) WTLog().except(me, false, level, extendedReport);
        end

        function display = displayException(o, displayFunct) 
            display = @(me, title, fmt, varargin) displayFunct(title, [fmt ': %s'], varargin{:}, getReport(me, 'basic', 'hyperlinks', 'off'));
        end

        function exec(o)
            o.Succeeded = false;
            nArgsOut = nargout(o.Run.Function);
            if nArgsOut > 0
                o.Result = cell(1, nArgsOut); 
                [o.Result{:}] = o.Run.Exec();
            else
                o.Run.Exec();
            end
            o.Succeeded  = true;
        end

        function recover(o)
            o.Recovered = false;
            nArgsOut = nargout(o.Run.Function);
            try
                if nArgsOut > 0
                    o.Result = cell(1, nArgsOut); 
                    [o.Result{:}] = o.Recover.Exec();
                else
                    o.Recover.Exec();
                end
                o.Recovered = true;
            catch me
                WTLog().except(me);
            end
        end
    end

    methods
        function o = WTTryExec(funct, varargin)
            o.Run = o.setFunction(funct, varargin{:});
            o.Succeeded = false;
            o.Recovered = false;
        end

        function v = get.Managed(o)
            v = o.Succeeded || o.Recovered;
        end

        function v = get.Unrecovered(o)
            v = ~(o.Succeeded || o.Recovered);
        end

        function o = logErr(o)
            wtLog = WTLog();
            o.Log = o.setFunctionWithExcptArg(@wtLog.except, false, WTLog.LevelErr, false);
        end

        function o = logErrVerbose(o)
            wtLog = WTLog();
            o.Log = o.setFunctionWithExcptArg(@wtLog.except, false,  WTLog.LevelErr, true);
        end

        function o = logWrn(o)
            wtLog = WTLog();
            o.Log = o.setFunctionWithExcptArg(@wtLog.except, false,  WTLog.LevelWrn, false);
        end

        function o = logWrnVerbose(o)
            wtLog = WTLog();
            o.Log = o.setFunctionWithExcptArg(@wtLog.except, false,  WTLog.LevelWrn, true);
        end

        function o = rethrow(o)
            o.ReThrow = o.setFunctionWithExcptArg(@rethrow);
        end

        function o = displayErr(o, title, fmt, varargin)
            o.Display = o.setFunctionWithExcptArg(o.displayException(@WTDialogUtils.errDlg), title, fmt, varargin{:});
        end

        function o = displayWrn(o, title, fmt, varargin)
            o.Display = o.setFunctionWithExcptArg(o.displayException(@WTDialogUtils.wrnDlg), title, fmt, varargin{:});
        end
        
        % 'function' should take an exception as first argument, varargin contains the remaining arguments
        % In case an execption occurs during 'function' execution, it'll be trapped and o.Recovered will be 
        % set to false.  
        function o = setRecover(o, funct, varargin)
            o.Recover = o.setFunction(funct, varargin{:});
        end

        function o = run(o)
            try
                o.exec();
            catch me
                if ~isempty(o.Log)
                    o.Log.Exec(me);
                end
                if ~isempty(o.Recover)
                    o.recover();
                end
                if ~isempty(o.Display)
                    o.Display.Exec(me);
                end 
                if ~isempty(o.ReThrow)
                    o.ReThrow.Exec(me);
                end
            end
        end
    end
end