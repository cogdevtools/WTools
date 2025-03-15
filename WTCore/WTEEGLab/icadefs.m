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

function icadefs()
    persistent icadefsFile
    overriders = WTICADefs().get();
    wtLog = WTLog();
    wtLog.pushStatus().HeaderOn = false;

    try
        if isempty(icadefsFile)
            if ~WTEEGLabUtils.eeglabDep()
                WTException.notExistingPath('EEGLab not found!').throw();
            end
            eeglabDir = fileparts(which('eeglab'));
            icadefsPath = fullfile(eeglabDir, '**', 'icadefs.m');
            files = dir(icadefsPath);
            if ~isempty(files)
                icadefsFile = fullfile(files(1).folder, files(1).name);
                wtLog.dbg('Found EEGLAb icadefs.m at: %s', icadefsFile);
            else
                WTException.notExistingPath('EEGLAB ''icadefs.m'' file not found!');
            end
        end
        
        icadefsCmd = sprintf('run(''%s'')', icadefsFile);
        wtLog.dbg('Executing: %s...', icadefsFile);
        evalin('caller', icadefsCmd);

        for i = 1:length(overriders)
            overrider = overriders{i};
            if iscell(overrider) && ischar(overrider{1})
                if length(overrider) == 1
                    overridingCode = overrider{1};
                    wtLog.dbg('Executing icadefs overriding code:\n%s', overridingCode);
                    evalin('caller', overridingCode);
                    continue
                elseif length(overrider) == 2
                    varName = overrider{1};
                    varValue = overrider{2};
                    wtLog.dbg('Overriding icadefs value of variable: %s... ', varName);
                    assignin('caller', varName, varValue);
                    continue
                end
            end
            WTException.badValue('Invalid icadefs overrider @%d', i).throw();
        end
    catch me
        wtLog.popStatus();
        wtLog.except(me, true);
    end
end
