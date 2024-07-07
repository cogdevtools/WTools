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

function success = wtSelectUpdateConditions(system, anImportedFile) 
    wtProject = WTProject();
    wtLog = WTLog();
    ioProc = wtProject.Config.IOProc;

    [success, conditions, ~] = ioProc.getConditionsFromImport(system, anImportedFile);
    if ~success
        wtLog.err('Failed to get conditions from imported file ''%s''', anImportedFile);
        return
    end

    success = false;
    conditions = WTDialogUtils.stringsSelectDlg('Select conditions', conditions, false, true);
    if isempty(conditions) 
        wtLog.warn('No conditions selected');
        return
    end

    conditionsPrms = copy(wtProject.Config.Conditions);
    conditionsPrms.ConditionsList = conditions;
    conditionsPrms.ConditionsDiff = {};

    if ~conditionsPrms.persist() 
        wtProject.notifyErr([], 'Failed to save import conditions params');
        return
    end

    wtProject.Config.Conditions = conditionsPrms;
    success = true;
end