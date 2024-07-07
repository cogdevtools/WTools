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

classdef WTLog < WTClass

    properties(Constant)
        ClassUUID = '1bbf9e0c-6b80-4166-b94e-50b6c523ed56'
    end

    properties (Constant,Hidden)
        LevelErr = 1
        LevelWrn = 2
        LevelInf = 3
        LevelDbg = 4
    end
   
    properties (Constant)
        % string index must correspond to the relative level code value
        LevelStrs = {'ERROR','WARNING','INFO','DEBUG'}
    end

    properties (Hidden,SetAccess=private,GetAccess=public)
        FileName char
    end

    properties (Access=private)
        Context cell 
        StatusStack cell
        FromCaller(1,1) logical
        Stream(1,1) double
    end

    properties (Access=public)
        LogName char
        HeaderOn(1,1) logical
        ColorizeMessages(1,1) logical
        MuteStdStreams(1,1) logical
        StdLogLevel(1,1) uint8
        UsrLogLevel(1,1) uint8
    end

    properties (Dependent)
        LogLevel(1,1) uint8
        StdLogLevelStr char
        UsrLogLevelStr char
        LogLevelStr char
    end 

    methods (Static, Access=private)
        function is = isLogLevel(level)
            is = isscalar(level) && isnumeric(level) && floor(level) == level && ...
                 level >= WTLog.LevelErr && level <= WTLog.LevelDbg;
        end

        function [module,func,line] = stackInfo(level) 
            stack = dbstack('-completenames');
            if level > length(stack)
                level = length(stack);
            end
            caller = stack(level);
            [~,module,ext] = fileparts(caller.file);
            module = strcat(module,ext);
            func = caller.name;
            line = caller.line;
        end

        function print(stream, msg)
            try
                fprintf(stream, msg);
            catch
            end
        end
    end

    methods (Access=private)   
        function msgout = format(o, time, module, func, line, level, fmt, varargin) 
            level = WTLog.LevelStrs{level};
            header = '';
            if o.HeaderOn
                ctx = o.Context(~cellfun(@isempty, o.Context));
                jctx = {''};
                if ~isempty(ctx)
                    jctx = strcat('|', join(ctx,' >> '));
                end
                logName = 'WTOOLS';
                if ~isempty(o.LogName)
                    logName = [logName '.' o.LogName];
                end
                header = sprintf('[%s %s %s:%s(%d)%s|%s]', time, logName, module, func, line, jctx{1}, level);
            end
            if ~isempty(varargin)
                msgout = sprintf(fmt, varargin{:});
            else
                msgout = fmt;
            end
            msgout = regexprep(msgout, {'%','\\n','\\'}, {'%%', newline, '\\\\'});
            toks = splitlines(msgout)';
            indent = (length(o.Context)+1)*2;
            padding = repelem(' ', indent);
            separator = ['\n', padding];
            if o.HeaderOn
                toks = [{header}, toks];
            else
                toks{1} = [padding, toks{1}];
            end
            msgout = join(toks, separator);
            msgout = strcat(msgout, '\n');
            msgout = msgout{1};
        end
        
        function msg(o, stdStream, level, fmt, varargin)
            logToUsrStream = level <= o.UsrLogLevel && o.Stream > 2;
            logToStdStream = level <= o.StdLogLevel && ~o.MuteStdStreams;
            if ~(logToUsrStream || logToStdStream)
                return
            end
            stackLevel = 4;
            if o.FromCaller
                stackLevel = 5;
            end
            [module, func, line] = WTLog.stackInfo(stackLevel);
            o.FromCaller = false;
            time = char(datetime('now','TimeZone','local','Format','d-MM-y HH:mm:ss.SSS'));
            str = o.format(time, module, func, line, level, fmt, varargin{:});
            if logToUsrStream
                WTLog.print(o.Stream, str);
            end
            if ~logToStdStream
                return
            end
            if ~o.ColorizeMessages
                WTLog.print(stdStream, str);
                return
            end
            if stdStream == 2
                WTLog.print(stdStream, str);
                return
            end
            switch level
                case WTLog.LevelErr
                    cprintf('*red', str);
                case WTLog.LevelInf
                    cprintf('text', str);
                case WTLog.LevelWrn
                    cprintf([1,0.5,0], str);
                case WTLog.LevelDbg
                    cprintf('blue', str);
                otherwise
                    cprintf('text', str);
            end
        end
    end

    methods
        function o = WTLog(singleton, logName)
            singleton = nargin < 1 || singleton;
            o = o@WTClass(singleton, true);
            if ~o.InstanceInitialised
                o.LogName = '';
                if nargin > 1
                    o.LogName = strip(logName);
                end
                o.Context = {};
                o.StatusStack = {};
                o.HeaderOn = true;
                o.StdLogLevel = WTLog.LevelInf;
                o.UsrLogLevel = WTLog.LevelInf;
                o.FromCaller = false;
                o.ColorizeMessages = false;
                o.MuteStdStreams = false;
                o.Stream = -1;
            end
         end

        function delete(o)
            if isvalid(o)
                o.closeStream();
            end
        end

        function o = contextOn(o, ctx, varargin) 
            if nargin == 1
                ctx = '';
            elseif nargin >= 2
                ctx = sprintf(ctx, varargin{:});
            end
            o.Context = [o.Context;{strtrim(ctx)}];
        end

        function o = contextOff(o, n)
            if nargin == 1 
                n = 1;
            end
            for k=1:n 
                if isempty(o.Context)
                    break
                end
                o.Context(end) = [];
            end
        end

        function o = fromCaller(o)
            o.FromCaller = true;
        end 

        function o = contextReset(o) 
            o.Context = {};
        end

        function o = reset(o)
            o.contextReset();
            o.StatusStack = {};
            o.HeaderOn = true;
            o.FromCaller = false;
        end

        function o = pushStatus(o) 
            o.StatusStack = [o.StatusStack {{o.Context, o.HeaderOn, o.FromCaller}}];
        end

        function o = popStatus(o, n)
            if nargin < 2
                n = 1;
            end
            nStack = length(o.StatusStack);
            n = min(n, nStack);
            if n > 0
                [o.Context,  o.HeaderOn, o.FromCaller] = o.StatusStack{end-n+1}{:};
                o.StatusStack(end-n+1:end) = [];
            end
        end

        function o = set.UsrLogLevel(o, level)
            if WTLog.isLogLevel(level)
                o.UsrLogLevel = level;
            end
        end

        function level = get.UsrLogLevelStr(o)
            level = WTLog.LevelStrs{o.UsrLogLevel};
        end
        
        function o = set.StdLogLevel(o, level)
            if WTLog.isLogLevel(level)
                o.StdLogLevel = level;
            end
        end

        function level = get.StdLogLevelStr(o)
            level = WTLog.LevelStrs{o.StdLogLevel};
        end


        function level = get.LogLevel(o)
            level = min(o.StdLogLevel, o.UsrLogLevel);
        end

        function level = get.LogLevelStr(o)
            level = WTLog.LevelStrs{o.LogLevel};
        end

        function o = except(o, excp, rethrow, level, extendedReport) 
            rethrow = nargin > 2 && islogical(rethrow) && any(rethrow);
            stdStream = 1;
            if nargin < 4 || ~WTLog.isLogLevel(level)
                level = WTLog.LevelErr;
                stdStream = 2;
            end
            reportType = 'extended';
            if nargin > 4 && islogical(extendedReport) && ~any(extendedReport)
                reportType = 'basic';
            end
            msg = strrep(getReport(excp, reportType), '%', '%%');
            o.msg(stdStream, level, '%s', msg);
            if nargin > 2 && rethrow
                excp.rethrow();
            end
        end

        function o = err(o, fmt, varargin)
            o.msg(2, WTLog.LevelErr, fmt, varargin{:});
        end
        
        function o = warn(o, fmt, varargin) 
            o.msg(1, WTLog.LevelWrn, fmt, varargin{:});
        end
        
        function o = info(o, fmt, varargin) 
            o.msg(1, WTLog.LevelInf, fmt, varargin{:});
        end
        
        function o = dbg(o, fmt, varargin) 
            o.msg(1, WTLog.LevelDbg, fmt, varargin{:});
        end

        function o = log(o, level, fmt, varargin) 
            if ~WTLog.isLogLevel(level)
                level = WTLog.LevelInf
            end
            switch level
                case WTLog.LevelErr
                    o.err(fmt, varargin{:});
                case WTLog.LevelWrn
                    o.warn(fmt, varargin{:});
                case WTLog.LevelInf
                    o.info(fmt, varargin{:});
                case WTLog.LevelDbg
                    o.dbg(fmt, varargin{:});
            end
        end

        function o = closeStream(o)
            try
                if o.Stream > 2 
                    fclose( o.Stream);
                end
            catch
            end
            o.FileName = '';
            o.Stream = -1;
        end

        function [o, success] = openStream(o, logFile)
            success = false;
            o.closeStream();
            dirPath = fileparts(logFile);
            [ok, ~] = mkdir(dirPath);
            if ok
                o.Stream = fopen(logFile, 'a+', 'n', 'UTF-8');
                o.FileName = logFile;
                success = true;
            end
        end
    end

    methods(Static)
        function level = logLevelCode(lvlStr)
            level = find(cellfun(@(x)strcmp(x, lvlStr), WTLog.LevelStrs));
        end

        function levelStr = logLevelStr(lvlCode)
            levelStr = '';
            if lvlCode >= WTLog.LevelErr && lvlCode <= WTLog.LevelDbg
                levelStr = WTLog.LevelStrs{lvlCode};
            end
        end
    end
end
