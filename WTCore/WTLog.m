classdef WTLog < handle
    
    properties (Constant,Hidden)
        LevelErr = 1
        LevelWrn = 2
        LevelInf = 3
        LevelDbg = 4
    end
   
    properties (Constant,Hidden,Access=private)
        LoglevelStrs = {'ERROR','WARNING','INFO','DEBUG'}
    end

    properties (Access=private)
        LogLevel uint8
        Context cell 
        HeaderOn logical
        StatusStack cell
        FromCaller logical
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
            msgout = regexprep(msgout, {'%','\\n','\\'}, {'%%',newline,'\\\\'});
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
                stackLevel = WTUtils.ifThenElse(o.FromCaller, 5, 4);
                [module, func, line] = WTLog.stackInfo(stackLevel);
                o.FromCaller = false;
                time = char(datetime('now','TimeZone','local','Format','d-MM-y HH:mm:ss.SSS'));
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
                o.FromCaller = false;
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

        function o = fromCaller(o)
            o.FromCaller = true;
        end 

        function o = ctxReset(o) 
            o.Context = {};
        end

        function o = reset(o)
            o.ctxReset();
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