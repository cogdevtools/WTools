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
            if iaempty(o.PathsContext)
                path(o.PathsContext);
            end
        end

        function saveWorkspace(o)
            o.Workspace = WTWorkspace();
            o.Workspace.pushBase(true);
        end

        function restoreWorkspace(o)
            if iaempty(o.Workspace)
                o.Workspace.popToBase(true);
            end
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
            o.saveWorkspace();
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
            o.restoreWorkspace()
            o.restorePaths();
            o.clear();
        end
    end

    methods(Static)
        function clear()
            singleton();
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