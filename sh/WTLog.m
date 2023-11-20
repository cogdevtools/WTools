classdef WTLog < handle
    
    properties (Constant)
        LevelErr = 1
        LevelWrn = 2
        LevelInf = 3
        LevelDbg = 4
    end
   
    properties (Constant,Access=private)
        loglevelStrs = {'ERROR','WARNING','INFO','DEBUG'}
    end

    properties (Access=private)
        logLevel
        context
        headerOn
    end

    methods (Access=private)
        function obj = WTLog()
            obj.context = {};
            obj.headerOn = true;
            obj.logLevel = WTLog.LevelInf;
         end
    end

    methods (Static,Access=private)         
        function [mdl,func,line] = stackInfo(level) 
            stack = dbstack('-completenames');
            if level > size(stack,1)
                level = size(stack,1);
            end
            caller = stack(level);
            [~,mdl,ext] = fileparts(caller.file);
            mdl = strcat(mdl,ext);
            func = caller.name;
            line = caller.line;
        end
        
        function msgout = format(time, mdl, func, line, level, headerOn, ctx, fmt, varargin) 
            header = '';
            if headerOn
                jctx = {''};
                if size(ctx, 1) > 0
                    jctx = strcat('|', join(ctx,' >> '));
                end
                header = sprintf('[%s WTOOLS %s:%s(%d)%s|%s]', time, mdl, func, line, jctx{1}, level);
            end
            msgout = sprintf(fmt, varargin{:});
            msgout = strrep(msgout, '%', '%%');
            msgout = strrep(msgout, '\n', newline);
            toks = splitlines(msgout);
            toks = [{header}, toks'];
            indent = (size(ctx, 1)+1)*2;
            filler = strcat('\n', {repelem(' ', indent)});
            if ~headerOn
                toks(1:1) = [];
            end
            msgout = join(toks, filler);
            msgout = strcat(msgout, '\n');
            msgout = msgout{1};
        end
        
        function msg(stream, level, fmt, varargin)
            if level <= WTLog.getLogLevel() 
                [mdl, func, line] = WTLog.stackInfo(4);
                ctx = WTLog.getCtx();
                time = datestr(now, 'HH:MM:SS.FFF');
                headerOn = WTLog.isHeaderOn();
                lvlStr = WTLog.loglevelStrs{level};
                str = WTLog.format(time, mdl, func, line, lvlStr, headerOn, ctx, fmt, varargin{:});
                fprintf(stream, str);
            end
        end
    end
    
    methods (Static)
        function ctx = getCtx() 
            obj = instance();
            ctx = obj.context;
        end

        function ctxOn(ctx) 
            obj = instance();
            obj.context = [obj.context;{strtrim(ctx)}];
        end

        function ctxOff(n)
            obj = instance();
            if nargin == 0 
                n = 1;
            end
            for k=1:n 
                if size(obj.context, 2) == 0
                    break
                end
                obj.context(end) = [];
            end
        end

        function ctxReset() 
            obj = instance();
            obj.context = {};
        end

        function headerOn = isHeaderOn()
            obj = instance();
            headerOn = obj.headerOn;
        end

        function headerOn = setHeaderOn(on)
            obj = instance();
            headerOn = logical(on);
            obj.headerOn = headerOn;
        end
        
        function logLevel = getLogLevel()
            obj = instance();
            logLevel = obj.logLevel;
        end

        function logLevel = getLogLevelStr()
            obj = instance();
            logLevel = obj.logLevelStrs{obj.logLevel};
        end

        function logLevel = setLogLevel(lvl)
            obj = instance();
            logLevel = obj.logLevel;
            if lvl >= WTLog.LevelErr && lvl <= WTLog.LevelDbg
                logLevel = lvl;
                obj.logLevel = logLevel;
            end
        end
        
        function excpt(type, fmt, varargin) 
            WTLog.err(fmt, varargin{:})
            id = sprintf('WTOOLS:%s', type);
            throw(MException(id, 'Unrecoverable error: check the log'));
        end
        
        function mexcpt(MExcept, rethrow) 
            msg = strrep(getReport(MExcept, 'extended'), '%', '%%');
            WTLog.err('%s\n', msg);
            if nargin > 1 && rethrow
                throw(MExcept);
            end
        end

        function err(fmt, varargin)
            WTLog.msg(2, WTLog.LevelErr, fmt, varargin{:});
        end
        
        function warn(fmt, varargin) 
            WTLog.msg(1, WTLog.LevelWrn, fmt, varargin{:});
        end
        
        function info(fmt, varargin) 
            WTLog.msg(1, WTLog.LevelInf, fmt, varargin{:});
        end
        
        function dbg(fmt, varargin) 
            WTLog.msg(1, WTLog.LevelDbg, fmt, varargin{:});
        end

        function log(level, fmt, varargin) 
            switch level
                case WTLog.LevelErr
                    WTLog.err(fmt, varargin{:})
                case WTLog.LevelWrn
                    WTLog.wrn(fmt, varargin{:})
                case WTLog.LevelInf
                    WTLog.info(fmt, varargin{:})
                case WTLog.LevelDbg
                    WTLog.dbg(fmt, varargin{:})
                otherwise
                    WTLog.inf(fmt, varargin{:})
            end
        end

        function varargout = evalcLog(level, ctx, cmd)
            varargout = cell(nargout,1);
            evalcCmd = sprintf('evalc(''%s'')', strrep(cmd,'''', ''''''));
            try
                [log, varargout{1:nargout}] = evalin('caller', evalcCmd);
            catch
                WTLog.excpt('evalin', 'Failed to exec ''%s''', evalcCmd);
            end
            log = strip(log,'right', newline);
            if ~isempty(log)
                if ~isempty(ctx)
                    WTLog.ctxOn(ctx);
                end
                WTLog.log(level, 'Follows log report of cmd: ''%s'' ...', cmd);
                headerOn = WTLog.isHeaderOn();
                WTLog.setHeaderOn(false);
                WTLog.ctxOn('');
                WTLog.log(level, log);
                WTLog.ctxOff();
                WTLog.setHeaderOn(headerOn);
                if ~isempty(ctx)
                    WTLog.ctxOff();
                end
            end
        end

        function close()
            instance();
            munlock('instance');
        end  
    end
end

function obj = instance()
    mlock;
    persistent uniqueInstance
    if nargout == 0 
        uniqueInstance = {};
        return
    end
    if isempty(uniqueInstance)
        obj = WTLog();
        uniqueInstance = obj;
    else
        obj = uniqueInstance;
    end
end