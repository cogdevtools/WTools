classdef WTSession < handle

    properties(Access=private)
        PathsContext
        Workspace
        ToolsDir
        SessionOpen
    end

    methods(Access=private)
        function prepareContext(o)
            o.Workspace.pushBase(true);
            o.PathsContext = path();
            addpath(genpath(o.ToolsDir));
        end

        function restoreContext(o)
            o.Workspace.popToBase(true);
            path(o.PathsContext);
        end
    end

    methods
        function o = WTSession()
            st = singleton();
            if isempty(st) || ~isvalid(st)
                o.ToolsDir = WTLayout.getToolsDir();
                o.Workspace = WTWorkspace();
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
            o.prepareContext();
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
            o.restoreContext();
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