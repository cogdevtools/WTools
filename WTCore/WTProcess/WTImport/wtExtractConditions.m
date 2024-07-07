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

function success = wtExtractConditions(subject)
    wtProject = WTProject();
    wtLog = WTLog();

    ioProc = wtProject.Config.IOProc;
    conditions = wtProject.Config.Conditions.ConditionsList;
    nConditions = length(conditions);
    outFilesPrefix = wtProject.Config.Basic.FilesPrefix;

    [success, EEG, ALLEEG] = ioProc.loadProcessedImport(outFilesPrefix, subject);
    if ~success 
        wtProject.notifyErr([], 'Failed to load processed import for subject ''%s''', subject);
        return
    end
    
    wtLog.info('Processing %d conditions...', nConditions);
    wtLog.pushStatus().contextOn().HeaderOn = false;

    for cnd = 1:nConditions
        condition = conditions{cnd};
        wtLog.info('Condition ''%s''', condition);

        try
            cndSet = ioProc.getConditionSet(outFilesPrefix, subject, condition);
            [cndFileFullPath, ~, ~] = ioProc.getConditionFile(outFilesPrefix, subject, condition);

            EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_selectevent', ...
                EEG,  'type', { condition }, 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');
            [ALLEEG, EEG, ~] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_newset', ...
                ALLEEG, EEG, 1, 'setname', cndSet, 'savenew', cndFileFullPath, 'gui', 'off');
            [ALLEEG, EEG, ~] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_newset', ...
                ALLEEG, EEG, cnd+1, 'retrieve', 1, 'study', 0);
            EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);  
        catch me
            success = false;
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to process/save condition ''%s'' for subject ''%s''', condition, subject);
            break
        end      
    end 

    wtLog.popStatus();
end