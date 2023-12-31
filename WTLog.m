classdef WTLog < handle
    
    properties (Constant)
        LevelErr = 1
        LevelWrn = 2
        LevelInf = 3
        LevelDbg = 4
    end
   
    properties (Constant,Access=private)
        LoglevelStrs = {'ERROR','WARNING','INFO','DEBUG'}
    end

    properties (Access=private)
        LogLevel uint8
        Context cell 
        HeaderOn logical
        StatusStack cell
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
    end

    methods (Access=private)   
        function msgout = format(o, time, module, func, line, lvl, fmt, varargin) 
            level = WTLog.LoglevelStrs{lvl};
            headerOn = o.isHeaderOn();
            header = '';
            if headerOn
                ctx = o.Context(~cellfun(@isempty, o.Context));
                jctx = {''};
                if ~isempty(ctx)
                    jctx = strcat('|', join(ctx,' >> '));
                end
                header = sprintf('[%s WTOOLS %s:%s(%d)%s|%s]', time, module, func, line, jctx{1}, level);
            end
            msgout = sprintf(fmt, varargin{:});
            msgout = strrep(msgout, '%', '%%');
            msgout = strrep(msgout, '\n', newline);
            toks = splitlines(msgout)';
            indent = (length(o.Context)+1)*2;
            padding = repelem(' ', indent);
            separator = ['\n', padding];
            if headerOn
                toks = [{header}, toks];
            else
                toks{1} = [padding, toks{1}];
            end
            msgout = join(toks, separator);
            msgout = strcat(msgout, '\n');
            msgout = msgout{1};
        end
        
        function msg(o, stream, level, fmt, varargin)
            if level <= o.getLogLevel() 
                [module, func, line] = WTLog.stackInfo(4);
                time = datestr(now, 'HH:MM:SS.FFF');
                str = o.format(time, module, func, line, level, fmt, varargin{:});
                fprintf(stream, str);
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
                o.LogLevel = WTLog.LevelInf;
                singleton(o);
            else 
                o = st;
            end
         end

        function ctx = getCtx(o) 
            ctx = o.Context;
        end

        function o = ctxOn(o, ctx, varargin) 
            if nargin == 1
                ctx = '';
            elseif nargin >= 2
                ctx = sprintf(ctx, varargin{:});
            end
            o.Context = [o.Context;{strtrim(ctx)}];
        end

        function o = ctxOff(o, n)
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

        function o = ctxReset(o) 
            o.Context = {};
        end

        function o = reset(o)
            o.ctxReset();
            o.StatusStack = {};
            o.HeaderOn = true;
        end

        function o = pushStatus(o) 
            o.StatusStack = [o.StatusStack {{o.Context, o.HeaderOn}}];
        end

        function o = popStatus(o)
            if isempty(o.StatusStack)
                return
            end
            [o.Context,  o.HeaderOn] = o.StatusStack{end}{:};
            o.StatusStack(end) = [];
        end

        function headerOn = isHeaderOn(o)
            headerOn = o.HeaderOn;
        end

        function headerOn = setHeaderOn(o, on)
            headerOn = o.HeaderOn;
            o.HeaderOn = any(logical(on));
        end
        
        function logLevel = getLogLevel(o)
            logLevel = o.LogLevel;
        end

        function logLevel = getLogLevelStr(o)
            logLevel = WTLog.logLevelStrs{o.LogLevel};
        end

        function logLevel = setLogLevel(o, lvl)
            logLevel = o.LogLevel;
            if lvl >= WTLog.LevelErr && lvl <= WTLog.LevelDbg
                logLevel = lvl;
                o.LogLevel = logLevel;
            end
        end
        
        function excpt(o, type, fmt, varargin) 
            o.err(fmt, varargin{:});
            id = sprintf('WTOOLS:%s', type);
            throw(MException(id, 'Unrecoverable error: check the log above...'));
        end
        
        function o = mexcpt(o, MExcept, rethrow) 
            msg = strrep(getReport(MExcept, 'extended'), '%', '%%');
            o.err('%s\n', msg);
            if nargin > 2 && rethrow
                throw(MExcept);
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
                    o.wrn(fmt, varargin{:});
                case WTLog.LevelInf
                    o.info(fmt, varargin{:});
                case WTLog.LevelDbg
                    o.dbg(fmt, varargin{:});
                otherwise
                    o.inf(fmt, varargin{:});
            end
        end

        function [success, varargout] = evalinLog(o, cmd, inBase) 
            success = false;
            varargout = cell(1, nargout-1);
            workspace = 'caller';
            if nargin > 2 && inBase
                workspace = 'base';
            end
            try
                [varargout{:}] = evalin(workspace, cmd); 
                success = true;
            catch me
                o.mexcpt(me);
            end
        end

        function varargout = evalcLog(o, level, ctx, cmd)
            varargout = cell(nargout,1);
            evalcCmd = sprintf('evalc(''%s'')', strrep(cmd, '''', ''''''));
            try
                [log, varargout{:}] = evalin('caller', evalcCmd);
            catch me
                o.mexcpt(me, false);
                o.excpt('evalin', 'Failed to exec ''%s''', evalcCmd);
            end
            log = strip(log,'right', newline);
            if ~isempty(log)
                o.pushStatus();
                if ~isempty(ctx)
                    o.ctxOn(ctx);
                end
                o.log(level, 'Follows log report of cmd: ''%s'' ...', cmd);
                o.ctxOn().setHeaderOn(false);
                o.log(level, log);
                o.popStatus();
            end
        end
    end

    methods(Static)
        function clear()
            singleton();
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