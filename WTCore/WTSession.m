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