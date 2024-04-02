classdef WTEval

    methods(Static)
        function [success, varargout] = evalinLog(cmd, inBase) 
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
                WTLog().except(me);
            end
        end

        function varargout = evalcLog(level, ctx, cmd)
            varargout = cell(nargout,1);
            evalcCmd = sprintf('evalc(''%s'')', strrep(cmd, '''', ''''''));
            wtLog = WTLog();

            try
                [log, varargout{:}] = evalin('caller', evalcCmd);
            catch me
                wtLog.except(me, false);
                WTException.evalinErr('Failed to exec ''%s''', evalcCmd).throw();
            end

            log = strip(log, 'right', newline);
        
            if ~isempty(log)
                wtLog.pushStatus();
                if ~isempty(ctx)
                    wtLog.contextOn(ctx);
                end
                wtLog.log(level, 'Follows log report of cmd: ''%s'' ...', cmd);
                wtLog.contextOn().HeaderOn = false;
                wtLog.log(level, log);
                wtLog.popStatus();
            end
        end
    end
end