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

function success = wtEGIToEEGLab()
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
   
    if ~wtProject.checkIsOpen()
        return
    end
    
    wtLog.pushStatus().contextOn('EGIToEEGLab');
    ioProc = wtProject.Config.IOProc;
    interactive = wtProject.Interactive;
    system = WTIOProcessor.SystemEGI;
    analysisStarted = ~isempty(ioProc.getImportedSubjects());

    if interactive  
        [ok, sbjFileNames] = wtSelectUpdateSubjects(system);
        if ~ok 
            wtLog.popStatus();
            return
        end
        % We cannot change parameters once some data has already been imported & converted
        if analysisStarted
            if ~WTConvertGUI.displayImportSettings(system)
                wtLog.popStatus();
                return
            end
        elseif ~wtSelectUpdateConditions(system, sbjFileNames{1})
            wtLog.popStatus();
            return
        end
    else 
        if ~wtProject.Config.Subjects.validate()
            wtProject.notifyErr([], 'Subjects params are not valid');
            wtLog.popStatus();
            return
        end
    end

    subjectsPrms = wtProject.Config.Subjects;
    subjects = subjectsPrms.ImportedSubjectsList;
    subjectFileNames = subjectsPrms.FilesList;
    nSubjects = length(subjects);
    outFilesPrefix = wtProject.Config.Basic.FilesPrefix;

    if nSubjects == 0 
        wtLog.warn('No subjects to process');
        wtLog.popStatus();
        return 
    end

    % We cannot change parameters once some data has already been imported & converted
    if ~analysisStarted
        % For EGI system we need to set first the SampleRate & the TriggerLatency prior to import
        % the data (not in raw mode), operation which is performed first in wtSelectUpdateChannels()
        if ~wtSetSampleRate(system, subjectFileNames{1}) || ...
            ~setTriggerLatency(subjectFileNames{1}) || ... 
            ~setMinMaxTrialId()
            wtLog.popStatus();
            return
        end
    end

    minMaxTrialIdPrms = wtProject.Config.MinMaxTrialId;
    importParams = struct();
    importParams.SampleRate = wtProject.Config.Sampling.SamplingRate;
    importParams.TriggerLatency = wtProject.Config.EGIToEEGLab.TriggerLatency;
    importParams.Conditions = wtProject.Config.Conditions.ConditionsList; 
    importParams.Trials = struct('Min', minMaxTrialIdPrms.MinTrialId, 'Max', minMaxTrialIdPrms.MaxTrialId);
    importParams = struct(system, importParams);

    % We cannot change parameters once some data has already been imported & converted
    if ~analysisStarted
        if interactive && ~wtSelectUpdateChannels(system, subjectFileNames{1}, importParams)
            wtLog.popStatus();
            return
        end
    end

    channelsPrms = wtProject.Config.Channels;

    for sbj = 1:nSubjects 
        subject = subjects{sbj};
        subjFileName = subjectFileNames{sbj}; 
        wtLog.info('Processing import file ''%s''', subjFileName);

        [success, ALLEEG, EEG, ~] =  WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true);
        if ~success 
            wtProject.notifyErr([], 'Failed to run eeglab');  
            wtLog.popStatus();      
            return
        end

        [ok, EEG] = ioProc.loadImport(system, subjFileName, importParams);
        if ~ok 
            wtProject.notifyErr([], 'Failed to import data file in eeglab:\n%s', subjFileName);
            wtLog.popStatus();
            return   
        end

        [ok, ALLEEG, EEG, CURRENTSET] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_newset', ...
            ALLEEG, EEG, 0, 'setname', subject, 'gui', 'off');
        if ~ok 
            wtProject.notifyErr([], 'Failed to create new eeglab set');
            wtLog.popStatus();
            return   
        end

        if isempty(channelsPrms.ChannelsLocationFile)
            wtLog.info('User did not reset channels locations and accepted EEGLab guess at import');
        else
            wtLog.info('Performing channels locations reset');
            chansLocFile = ioProc.getChannelsLocationsFile(channelsPrms.ChannelsLocationFile, channelsPrms.ChannelsLocationLocal);

            [ok, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelInf, true, 'pop_chanedit', EEG, 'load', ...
                { chansLocFile, 'filetype', channelsPrms.ChannelsLocationFileType });
            if ~ok 
                wtProject.notifyErr([], 'Failed to edit channels');
                wtLog.popStatus();
                return   
            end
        end

        if ~isempty(channelsPrms.CutChannels)
            wtLog.info('Cutting channels: %s', char(join(channelsPrms.CutChannels, ',')));
            [ok, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelInf, true, 'pop_select', EEG, 'nochannel', channelsPrms.CutChannels);
            if ~ok 
                wtProject.notifyErr([], 'Failed cut channels');
                wtLog.popStatus();
                return   
            end
        end

        [ok, EEG] = wtReReferenceChannels(system, EEG);
        if ~ok
            wtProject.notifyErr([], 'Failed to perform channels re-reference for subject ''%s''', subject);
            wtLog.popStatus();
            return
        end

        try 
            % Not sure that the instruction below is useful as repeated just after writeProcessedImport...
            [ALLEEG, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);
            
            [ok, ~, EEG] = ioProc.writeProcessedImport(outFilesPrefix, subject, EEG);
            if ~ok
                wtProject.notifyErr([], 'Failed to save processed import for subject ''%s''', subject);
                wtLog.popStatus();
                return
            end

            [ALLEEG, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to store EEGLAB data set for ''%s''', subject);
            wtLog.popStatus();
            return
        end

        if ~wtExtractConditions(subject)
            wtLog.popStatus();
            return
        end
    end

    wtLog.popStatus();
    wtProject.notifyInf([], 'EGI -> EEGLab import completed!');
    success = true;
end

function success = setTriggerLatency(subjFileName)
    success = false;
    wtProject = WTProject();
    EGI2EEGLabPrms = copy(wtProject.Config.EGIToEEGLab);

    if ~WTConvertGUI.defineTriggerLatency(EGI2EEGLabPrms)
        return
    end
    
    if ~EGI2EEGLabPrms.persist()
        wtProject.notifyErr([], 'Failed to save trigger latency params');
        return
    end

    wtProject.Config.EGIToEEGLab = EGI2EEGLabPrms;
    success = true;
end

function success = setMinMaxTrialId()
    success = false;
    wtProject = WTProject();
    minMaxTrialIdPrms = copy(wtProject.Config.MinMaxTrialId);

    if ~WTConvertGUI.defineTrialsRangeId(minMaxTrialIdPrms)
        return
    end
    
    if ~minMaxTrialIdPrms.persist()
        wtProject.notifyErr([], 'Failed to save min/max trial id params');
        return
    end

    wtProject.Config.MinMaxTrialId = minMaxTrialIdPrms;
    success = true;
end

