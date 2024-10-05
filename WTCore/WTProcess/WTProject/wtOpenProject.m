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

function success = wtOpenProject
    success = false;

    prjPath = WTDialogUtils.uiGetDir('.', 'Select the project directory...', ...
        'excludeDirs', ['^' regexptranslate('escape', WTLayout.getToolsDir())]);

    if ~ischar(prjPath)
        return
    end

    wtProject = WTProject();
    
    if ~wtProject.open(prjPath) 
        return
    end

    wtAppConfig = WTAppConfig();

    if wtAppConfig.ProjectLog
        ioProc = wtProject.Config.IOProc;
        wtLog = WTLog();
        [~, opened] = wtLog.openStream(ioProc.getLogFile(wtProject.Config.getName()));
        wtLog.MuteStdStreams = WTCodingUtils.ifThenElse(opened, wtAppConfig.MuteStdLog, false);
    end

    success = true;
end