classdef WTLog < handle
    
    properties (Constant,Hidden)
        LevelErr = 1
        LevelWrn = 2
        LevelInf = 3
        LevelDbg = 4
    end
   
    properties (Constant,Hidden,Access=private)
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

    properties (Hidden,Access=public)
        HeaderOn(1,1) logical
        ColorizeMessages(1,1) logical
        MuteStdStreams(1,1) logical
        StdLogLevel(1,1) uint8
        UsrLogLevel(1,1) uint8
    end

    properties (Hidden,Dependent)
        LogLevel(1,1) uint8
        StdLogLevelStr char
        UsrLogLevelStr char
        LogLevelStr char
    end 

    methods (Static, Access=private)         
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
                header = sprintf('[%s WTOOLS %s:%s(%d)%s|%s]', time, module, func, line, jctx{1}, level);
            end
            msgout = sprintf(fmt, varargin{:});
            msgout = regexprep(msgout, {'%','\\n','\\'}, {'%%',newline,'\\\\'});
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
        function o = WTLog()
            st = singleton();
            if isempty(st) || ~isvalid(st)
                o.Context = {};
                o.StatusStack = {};
                o.HeaderOn = true;
                o.StdLogLevel = WTLog.LevelInf;
                o.UsrLogLevel = WTLog.LevelInf;
                o.FromCaller = false;
                o.ColorizeMessages = false;
                o.MuteStdStreams = false;
                o.Stream = -1;
                singleton(o);
            else 
                o = st;
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
            if level >= WTLog.LevelErr && level <= WTLog.LevelDbg
                o.UsrLogLevel = level;
            end
        end

        function level = get.UsrLogLevelStr(o)
            level = WTLog.LevelStrs{o.UsrLogLevel};
        end
        
        function o = set.StdLogLevel(o, level)
            if level >= WTLog.LevelErr && level <= WTLog.LevelDbg
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

        function o = except(o, excp, rethrow) 
            msg = strrep(getReport(excp, 'extended'), '%', '%%');
            o.msg(2, WTLog.LevelErr, '%s\n', msg);
            if nargin > 2 && rethrow
                excp.rethrow()
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
            switch level
                case WTLog.LevelErr
                    o.err(fmt, varargin{:});
                case WTLog.LevelWrn
                    o.warn(fmt, varargin{:});
                case WTLog.LevelInf
                    o.info(fmt, varargin{:});
                case WTLog.LevelDbg
                    o.dbg(fmt, varargin{:});
                otherwise
                    o.info(fmt, varargin{:});
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

        function clear()
            o = singleton();
            o.closeStream();
            munlock('singleton');
        end
    end
end

function o = singleton(o)
    mlock;
    persistent uniqueInstance

    if nargin > 0 
        uniqueInstance = o;
    elseif nargout > 0 
        o = uniqueInstance;
    elseif ~isempty(uniqueInstance)
        delete(uniqueInstance)
    end
end