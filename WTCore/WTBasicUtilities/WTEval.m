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

classdef WTEval

    methods(Static)
        function [success, varargout] = evalin(cmd, inBase) 
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