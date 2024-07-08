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
    interactive = wtProject.Interactive;
    system = WTIOProcessor.SystemEGI;

    if interactive  
        [success, sbjFileNames] = wtSelectUpdateSubjects(system);
        if ~success
            wtLog.popStatus();
            return
        end  
        if ~wtSelectUpdateConditions(system, sbjFileNames{1}) || ~wtSelectUpdateChannels(system)
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

    ioProc = wtProject.Config.IOProc;
    subjectsPrms = wtProject.Config.Subjects;
    subjects = subjectsPrms.ImportedSubjectsList;
    subjectFileNames = subjectsPrms.FilesList;
    nSubjects = length(subjects);
    channelsPrms = wtProject.Config.Channels;
    outFilesPrefix = wtProject.Config.Basic.FilesPrefix;

    if nSubjects == 0 
        wtLog.warn('No subjects to process');
        wtLog.popStatus();
        return 
    end

    if ~wtSetSampleRate(system, subjectFileNames{1}) || ...
        ~setTriggerLatency() || ... 
        ~setMinMaxTrialId()
         return
    end

    samplingPrms = wtProject.Config.Sampling;
    EGI2EEGLabPrms = wtProject.Config.EGIToEEGLab;

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

        try
            wtLog.warn('Attempt to import data in EEGLab: IGNORE any possible reported error');
            success = false;
            eeg_getversion(); % Introduced in EEGLAB v9.0.0.0b
            fileToImport = ioProc.getImportFile(subjFileName);
            [success, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_importegimat', ...
                fileToImport, samplingPrms.SamplingRate, EGI2EEGLabPrms.TriggerLatency);
        catch
        end

        if ~success
            wtLog.warn('Attempt to import data in EEGLab FAILED. Ignore previous error. Proceeding with data fixing...');

            [success, data] = filterAndRenameDataFields(subjFileName); 
            if ~success 
                wtLog.popStatus();
                return
            end
            
            fileToImport = ioProc.getTemporaryFile('', subjFileName);
            wtLog.info('Creating temporary file to adjust import data: ''%s''', fileToImport);

            if ~WTIOUtils.saveTo([], fileToImport, '-struct', 'data')
                wtProject.notifyErr([], 'Failed to save temporary data file with trial ajustments (%s)', subjFileName);
                wtLog.popStatus();
                return
            end

            [success, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_importegimat', ...
                fileToImport, samplingPrms.SamplingRate, EGI2EEGLabPrms.TriggerLatency);
            
            wtLog.info('Deleting temporary file created to adjust import data: ''%s''', fileToImport);
            delete(fileToImport);
        end

        if ~success 
            wtProject.notifyErr([], 'Failed to import %s data file in eeglab:\n%s', ...
               WTCodingUtils.ifThenElse(deleteFileToImport, 'ADJUSTED ', ''), subjFileName);
            wtLog.popStatus();
            return   
        end

        [success, ALLEEG, EEG, CURRENTSET] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_newset', ...
            ALLEEG, EEG, 0, 'setname', subjects, 'gui', 'off');
        if ~success 
            wtProject.notifyErr([], 'Failed to create new eeglab set');
            wtLog.popStatus();
            return   
        end
        
        if channelsPrms.ReReference ~= channelsPrms.ReReferenceNone
            [success, EEG] = restoreCzChannel(EEG, channelsPrms);
            if ~success 
                wtLog.popStatus();
                return
            end
        end

        if ~isempty(channelsPrms.CutChannels)
            wtLog.info('Cutting channels: %s', char(join(channelsPrms.CutChannels, ',')));
            [success, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_select', EEG, 'nochannel', channelsPrms.CutChannels);
            if ~success 
                wtProject.notifyErr([], 'Failed cut channels');
                wtLog.popStatus();
                return   
            end
            EEG.nbchan = size(EEG.data, 1);
        end

        [success, EEG] = wtReReferenceChannels(system, EEG);
        if ~success
            wtProject.notifyErr([], 'Failed to perform channels re-reference for subject ''%s''', subject);
            wtLog.popStatus();
            return
        end

        try 
            % Not sure that the instruction below is useful as repeated just after writeProcessedImport...
            [ALLEEG, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);
            
            [success, ~, EEG] = ioProc.writeProcessedImport(outFilesPrefix, subject, EEG);
            if ~success
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

function success = setTriggerLatency()
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

% Rename trials in continous way to avoid premature import stop in EEGLAB old versions
function [success, dataOut] = filterAndRenameDataFields(subjFileName)
    wtProject = WTProject();
    wtLog = WTLog();
    ioProc = wtProject.Config.IOProc;
    dataOut = struct();
    wtLog.pushStatus().contextOn('TrialsAdjustment');

    try
        wtLog.info('Import file needs trial adjustment...');
        wtLog.HeaderOn = false;

        [success, data] = ioProc.loadImport(WTIOProcessor.SystemEGI, subjFileName);
        if ~success 
            wtProject.notifyErr([], 'Failed to read subject data from %s', subjFileName);
            wtLog.popStatus();
            return
        end

        selectedConditions = wtProject.Config.Conditions.ConditionsList;
        minMaxTrialIdPrms = wtProject.Config.MinMaxTrialId;
        minMaxTrialIdPrms = minMaxTrialIdPrms.interpret();

        dataOut = struct();
        allTrials = minMaxTrialIdPrms.allTrials();
        minTrial = WTCodingUtils.ifThenElse(isnan(minMaxTrialIdPrms.MinTrialId), 0, minMaxTrialIdPrms.MinTrialId);
        maxTrial = WTCodingUtils.ifThenElse(isnan(minMaxTrialIdPrms.MaxTrialId), inf, minMaxTrialIdPrms.MaxTrialId);
        
        % fields should be normally ordered and we keep the same order
        dataFields = fieldnames(data);
        % find the <condition>_Segment<#> fields
        reResult = regexp(dataFields, ioProc.EGIConditionSegmentFldRe, 'once', 'tokens');
        selected = ~cellfun(@isempty, reResult); 
        selectedIdxs = find(selected);
        % extract conditions name
        matches = reResult(selected);
        cndSeg = cat(1, matches{:});  % {{'cnd'}, {'seg'}}
        conditions = unique(cndSeg(:,1));
        % create a counters for each condition
        counters = cell2struct(repmat({zeros(1)}, 1, length(conditions)), conditions, 2);
        
        for i = 1:length(selectedIdxs)
            fldIdx = selectedIdxs(i);
            cndName = reResult{fldIdx}{1};
            if ~any(strcmp(cndName, selectedConditions)) % ignore unselected conditions
                continue
            end
            segNum = WTNumUtils.str2double(reResult{fldIdx}{2});
            if allTrials && (segNum < minTrial || segNum > maxTrial) % ignore trials out of range
                continue
            end
            newSegNum = counters.(cndName)+1;
            counters.(cndName) = newSegNum;
            newFieldName = [cndName '_Segment' num2str(newSegNum)];
            dataOut.(newFieldName) = data.(dataFields{fldIdx});
            wtLog.dbg('Renamed data field %s => %s', dataFields{fldIdx}, newFieldName);
        end

        invariantFields = dataFields(~selected);
        for i = 1:length(invariantFields)
            dataOut.(invariantFields{i}) = data.(invariantFields{i});
            wtLog.dbg('Preserved data field %s', invariantFields{i});
        end
    catch me
        wtLog.except(me);
        wtProject.notifyErr([], 'Failed to perform trial ajustments (%s)', subjFileName);
        success = false;
    end

    wtLog.popStatus();
end


% Restore reference back (as if EEG was loaded with pop_importegimat.m, it was cut)
function [success, EEG] = restoreCzChannel(EEG, channelsPrms) 
    success = true;
    
    try
        WTLog().info('Restoring Cz channel before re-referencing...');
        ref = zeros(1, size(EEG.data, 2), size(EEG.data, 3)); 
        EEG.data = cat(1, EEG.data, ref);
        EEG.nbchan = size(EEG.data, 1);
        EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
        EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_chanedit', EEG,  'load', ...
            { channelsPrms.ChannelsLocationFile, 'filetype', channelsPrms.ChannelsLocationFileType }, ...
            'delete', 1, 'delete', 1, 'delete', 1);
    catch me
        wtLog.except(me);
        wtProject.notifyErr([], 'Failed to restore Cz channel');
        success = false;
    end
end