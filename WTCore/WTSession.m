classdef WTSession < handle

    properties(Access=private)
        PathsContext
        Workspace
        SessionOpen
    end

    methods(Access=private)
        function savePaths(o)
            o.PathsContext = path();
            addpath(genpath(WTLayout.getToolsDir()));
        end

        function restorePaths(o)
            path(o.PathsContext);
        end
    end

    methods
        function o = WTSession()
            st = singleton();
            if isempty(st) || ~isvalid(st)
                singleton(o);
            else 
                o = st;
            end
        end

        function open(o)
            if o.SessionOpen 
                return
            end
            o.SessionOpen = true;
            o.savePaths();
            o.Workspace = WTWorkspace();
            o.Workspace.pushBase(true);
            wtLog = WTLog();
            wtAppConfig = WTAppConfig();
            wtAppConfig.load();
            wtLog.ColorizeMessages = wtAppConfig.ColorizedLog;
            wtLog.UsrLogLevel = wtAppConfig.ProjectLogLevel;
            wtLog.StdLogLevel = wtAppConfig.DefaultStdLogLevel;
            wtLog.info('Starting WTools session...');
            WTProject();
        end

        function close(o)
            if ~o.SessionOpen 
                return
            end
            o.SessionOpen = false;
            wtAppConfig = WTAppConfig();
            wtProject = WTProject();
            wtLog = WTLog();
            wtAppConfig.persist();
            wtLog.info('Closing WTools session...');
            wtAppConfig.clear()
            wtProject.clear();
            wtLog.clear();
            o.Workspace.popToBase(true);
            o.restorePaths();
        end
    end

    methods(Static)
        function clear()
            o = singleton();
            munlock('singleton');
        end
    end
end

function o = singleton(obj)
    mlock;
    persistent uniqueInstance

    if nargin > 0 
        uniqueInstance = obj;
    elseif nargout > 0 
        o = uniqueInstance;
    elseif ~isempty(uniqueInstance)
        delete(uniqueInstance)
    end
end