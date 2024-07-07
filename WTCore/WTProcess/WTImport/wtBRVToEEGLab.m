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

function success = wtBRVToEEGLab()
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    
    if ~wtProject.checkIsOpen()
        return
    end
    
    wtLog.pushStatus().contextOn('BRVToEEGLab');

    interactive = wtProject.Interactive;
    system = WTIOProcessor.SystemBRV;

    if interactive  
        [success, sbjFileNames] = wtSelectUpdateSubjects(system);
        if ~success
            wtLog.popStatus();
            return
        end  
        if ~wtSelectUpdateConditions(system, sbjFileNames{1}) || ...
           ~wtSelectUpdateChannels(system) || ... 
           ~setEpochsLimitsAndFreqFilter()
            wtLog.popStatus();
            return
        end
    else
        if ~wtProject.Config.Subjects.validate()
            wtProject.notifyErr([], 'Subjects params are not valid');
            wtLog.popStatus();
            return
        end
        if ~wtProject.Config.BRVToEEGLab.validate()
            wtProject.notifyErr([], 'BRV to EEGLab conversinos params are not valid');
            wtLog.popStatus();
            return
        end
    end

    ioProc = wtProject.Config.IOProc;
    subjectsPrms = wtProject.Config.Subjects;
    subjects = subjectsPrms.ImportedSubjectsList;
    subjectFileNames = subjectsPrms.FilesList;
    nSubjects = length(subjects);
    BRVToEEGLabPrms = wtProject.Config.BRVToEEGLab;
    channelsPrms = wtProject.Config.Channels;
    outFilesPrefix = wtProject.Config.Basic.FilesPrefix;
    epochLimits = BRVToEEGLabPrms.EpochLimits / 1000;
   
    if nSubjects == 0 
        wtLog.warn('No subjects to process');
        wtLog.popStatus();
        return 
    end

    if ~wtSetSampleRate(system, subjectFileNames{1})
         return
    end

    for sbj = 1:nSubjects 
        subject = subjects{sbj};
        subjFileName = subjectFileNames{sbj}; 
        wtLog.info('Processing import file ''%s''', subjFileName);

        [success, ALLEEG, ~, ~] =  WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true);
        if ~success 
            wtProject.notifyErr([], 'Failed to run eeglab');  
            wtLog.popStatus();      
            return
        end

        [success, EEG] = ioProc.loadImport(system, subjFileName);
        if ~success 
            wtProject.notifyErr([], 'Failed to load import: ''%s''', ioProc.getImportFile(subjFileName));
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

        % Apply HighPass and LowPass filters separately. This is a workaround because sometimes MATLAB 
        % does not find a good solution for BandPass filter.
        if ~isnan(BRVToEEGLabPrms.HighPassFilter)
            [success, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_eegfilt', ...
                EEG, BRVToEEGLabPrms.HighPassFilter, [], [], 0);
            if ~success 
                wtProject.notifyErr([], 'Failed to apply high pass filter');
                wtLog.popStatus();
                return   
            end
        end

        if ~isnan(BRVToEEGLabPrms.LowPassFilter)
            [success, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_eegfilt', ...
                EEG, [], BRVToEEGLabPrms.LowPassFilter, [], 0);
            if ~success 
                wtProject.notifyErr([], 'Failed to apply low pass filter');
                wtLog.popStatus();
                return   
            end
        end

        [success, EEG] = wtReReferenceChannels(system, EEG);
        if ~success
            wtProject.notifyErr([], 'Failed to perform channels re-reference for subject ''%s''', subject);
            wtLog.popStatus();
            return
        end

        [success, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_epoch', EEG, {}, epochLimits, 'epochinfo', 'yes');
        if ~success
            wtProject.notifyErr([], 'Failed to to apply epoch limits for subject ''%s''', subject);
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
    wtProject.notifyInf([], 'BRV -> EEGLab import completed!');
    success = true;
end


function success = setEpochsLimitsAndFreqFilter()
    success = false;
    wtProject = WTProject();
    BRVToEEGLabPrms = copy(wtProject.Config.BRVToEEGLab);

    if ~WTConvertGUI.defineEpochLimitsAndFreqFilter(BRVToEEGLabPrms)
        return
    end

    if ~BRVToEEGLabPrms.persist()
        wtProject.notifyErr([], 'Failed to save epocch limits and freqency filter params');
        return
    end

    wtProject.Config.BRVToEEGLab = BRVToEEGLabPrms;
    success = true;
end