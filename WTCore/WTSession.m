classdef WTSession < WTClass

    properties(Constant)
        ClassUUID = '96e4e33f-11fb-4d07-9f1f-5b9d2a5029dd'
    end

    properties(Access=private)
        Workspace = [];
    end

    properties(GetAccess=public, SetAccess=private)
        IsOpen = false;
        Name char
    end

    methods(Access=private)
        function setWorkspace(o)
            o.Workspace = WTWorkspace();
            o.Workspace.pushBase(true);
        end

        function restoreWorkspace(o)
            if ~isempty(o.Workspace)
                o.Workspace.popToBase(true);
            end
        end
    end

    methods
        function o = WTSession(name)
            o = o@WTClass(true, true);
            if nargin > 0
                o.Name = strip(name);
            end
        end

        function delete(o)
            o.close();
        end

        function open(o)
            if o.IsOpen 
                return
            end
            o.IsOpen = true;
            o.setWorkspace();
            wtLog = WTLog();
            wtLog.LogName = o.Name;
            wtAppConfig = WTAppConfig().load();
            wtLog.ColorizeMessages = wtAppConfig.ColorizedLog;
            wtLog.UsrLogLevel = wtAppConfig.ProjectLogLevel;
            wtLog.StdLogLevel = wtAppConfig.DefaultStdLogLevel;
            WTLog().info('Opening WTools session...');
            WTProject();
        end

        function close(o)
            if ~o.IsOpen 
                return
            end
            o.IsOpen = false;
            WTLog().info('Closing WTools session...');
            o.restoreWorkspace()
        end
    end
end