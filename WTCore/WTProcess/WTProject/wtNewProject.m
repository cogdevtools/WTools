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

function success = wtNewProject
    success = false;
    wtProject = WTProject();
    prjName = '';

    while true 
        prms = { { 'style' 'text' 'string' 'New project name:' } ...
                 { 'style' 'edit' 'string' prjName } };
        answer = WTEEGLabUtils.eeglabInputMask( 'geometry', { [1 2] }, 'uilist', prms, 'title', 'Set project name');

        if isempty(answer)
            return 
        end

        prjName = strip(answer{1});
        if wtProject.checkIsValidName(prjName, true)
            break;
        end
    end

    prjParentDir = WTDialogUtils.uiGetDir('.', 'Select the project parent directory...', ... 
        'excludeDirs', ['^' regexptranslate('escape', WTLayout.getToolsDir())]);
    
        if ~ischar(prjParentDir)
        return
    end

    prjPath = fullfile(prjParentDir, prjName);
    if  WTIOUtils.dirExist(prjPath)
        if ~WTEEGLabUtils.eeglabYesNoDlg('Warning', ['Project directory already exists!\n' ...
            'Directory: %s\n' ...
            'Do you want to overwrite it?'], prjPath)
            return;
        end            
    end

    if ~wtProject.new(prjPath)
        return
    end

    wtAppConfig = WTAppConfig();

    if wtAppConfig.ProjectLog
        ioProc = wtProject.Config.IOProc;
        wtLog = WTLog();
        [~, opened] = wtLog.openStream(ioProc.getLogFile(prjName));
        wtLog.MuteStdStreams = WTCodingUtils.ifThenElse(opened, wtAppConfig.MuteStdLog, false);
    end

    wtImport(true);
    success = true;
end