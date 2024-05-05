% wtBRVToEEGLab.m
% Created by Eugenio Parise
% CDC CEU 2013
% Function to import .mat BrainVision files in EEGLAB. After importing the
% script will segment the imported file into multiple EEGLAB datasets:
% one for each experimental condition.
% To set this script to process the whole final sample of subjects in a study,
% edit 'subj.m' in the 'cfg' folder and digit wtEEPToEEGLab([],...) (empty value) at
% the console prompt.
%
% Usage:
%
% wtBRVToEEGLab(subjects,epochlimits,hpf,lpf)
% wtBRVToEEGLab('02',[-200 1000],0.3,65)
% wtBRVToEEGLab([],[-200 1000],0.3,65)
%
% Enter no argument To run from GUI:
% wtBRVToEEGLab()

function wtBRVToEEGLab()
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
    subjects = subjectsPrms.SubjectsList;
    subjectFileNames = subjectsPrms.FilesList;
    nSubjects = length(subjects);
    conditionsPrms = wtProject.Config.Conditions;
    BRVToEEGLabPrms = wtProject.Config.BRVToEEGLab;
    conditions = conditionsPrms.ConditionsList;
    nConditions = length(conditions);
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

        [success, ALLEEG, ~, ~] =  WTUtils.eeglabRun(WTLog.LevelDbg, true);
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

        [success, ALLEEG, EEG, CURRENTSET] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_newset', ...
            ALLEEG, EEG, 0, 'setname', subjects, 'gui', 'off');
        if ~success 
            wtProject.notifyErr([], 'Failed to create new eeglab set');
            wtLog.popStatus();
            return   
        end

        if ~isempty(channelsPrms.CutChannels)
            wtLog.info('Cutting channels: %s', char(join(channelsPrms.CutChannels, ',')));
            [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_select', EEG, 'nochannel', channelsPrms.CutChannels);
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
            [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_eegfilt', ...
                EEG, BRVToEEGLabPrms.HighPassFilter, [], [], 0);
            if ~success 
                wtProject.notifyErr([], 'Failed to apply high pass filter');
                wtLog.popStatus();
                return   
            end
        end

        if ~isnan(BRVToEEGLabPrms.LowPassFilter)
            [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_eegfilt', ...
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

        [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_epoch', EEG, {}, epochLimits, 'epochinfo', 'yes');
        if ~success
            wtProject.notifyErr([], 'Failed to to apply epoch limits for subject ''%s''', subject);
            wtLog.popStatus();
            return
        end

        try 
            % Not sure that the instruction below is useful as repeated just after writeProcessedImport...
            [ALLEEG, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);

            [success, ~, EEG] = ioProc.writeProcessedImport(outFilesPrefix, subject, EEG);
            if ~success
                wtProject.notifyErr([], 'Failed to save processed import for subject ''%s''', subject);
                wtLog.popStatus();
                return
            end

            [ALLEEG, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);
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