% wtEEPToEEGLab.m
% Created by Eugenio Parise
% CDC CEU 2011
% Function to import ANT EEProbe files in EEGLAB. After importing the
% original one EEGLAB file, the script will segmented such file
% into multiple EEGLAB datasets: one for each experimental condition.
% To set this script to process the whole final sample of subjects in a study,
% edit 'subj.m' in the 'cfg' folder and digit wtEEPToEEGLab([],...) (empty value) at
% the console prompt.
% 
% Usage:
% 
% wtEEPToEEGLab(subjects,epochlimits,hpf,lpf)
% wtEEPToEEGLab('02',[-200 1000],0.3,65)
% wtEEPToEEGLab([],[-200 1000],0.3,65)

function wtEEPToEEGLab()
    wtProject = WTProject();
    wtLog = WTLog();
   
    if ~wtProject.checkIsOpen()
        return
    end
    
    wtLog.pushStatus().contextOn('EEPToEEGLab');
    interactive = wtProject.Interactive;
    system = WTIOProcessor.SystemEEP;

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
        if ~wtProject.Config.EEPToEEGLab.validate()
            wtProject.notifyErr([], 'EEP to EEGLab conversions params are not valid');
            wtLog.popStatus();
            return
        end
    end

    ioProc = wtProject.Config.IOProc;
    subjectsPrms = wtProject.Config.Subjects;
    subjects = subjectsPrms.ImportedSubjectsList;
    subjectFileNames = subjectsPrms.FilesList;
    nSubjects = length(subjects);
    conditionsPrms = wtProject.Config.Conditions;
    EEPToEEGLabPrms = wtProject.Config.EEPToEEGLab;
    conditions = conditionsPrms.ConditionsList;
    nConditions = length(conditions);
    channelsPrms = wtProject.Config.Channels;
    outFilesPrefix = wtProject.Config.Basic.FilesPrefix;
    epochLimits = EEPToEEGLabPrms.EpochLimits / 1000;
    
    if nSubjects == 0 
        wtLog.warn('No subjects to process');
        wtLog.popStatus();
        return 
    end

    if ~wtSetSampleRate(system, subjectFileNames{1})
        wtLog.popStatus();
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
        if ~isnan(EEPToEEGLabPrms.HighPassFilter)
            [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_eegfilt', ...
                EEG, EEPToEEGLabPrms.HighPassFilter, [], [], 0);
            if ~success 
                wtProject.notifyErr([], 'Failed to apply high pass filter');
                wtLog.popStatus();
                return   
            end
        end

        if ~isnan(EEPToEEGLabPrms.LowPassFilter)
            [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_eegfilt', ...
                EEG, [], EEPToEEGLabPrms.LowPassFilter, [], 0);
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

        % Apply original rejection performed in EEProbe
        try 
            rejectionFile = WTIOProcessor.getEEPRejectionFile(ioProc.getImportFile(subjFileName));
            rejection = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'read_eep_rej', rejectionFile);
            rejection = rejection./(1000/EEG.srate);
            if rejection(1,1) == 0
                rejection(1,1) = 1;
            end
            EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_eegrej', EEP, rejection);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to apply original rejection performed in EEProbe for subject ''%s''', subject);
            wtLog.popStatus();
            return
        end

        [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_epoch', EEG, {}, epochLimits, 'epochinfo', 'yes');
        if ~success
            wtProject.notifyErr([], 'Failed to apply epoch limits for subject ''%s''', subject);
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
    wtProject.notifyInf([], 'EEP -> EEGLab import completed!');
end

function success = setEpochsLimitsAndFreqFilter()
    success = false;
    wtProject = WTProject();
    EEPToEEGLabPrms = copy(wtProject.Config.EEPToEEGLab);

    if ~WTConvertGUI.defineEpochLimitsAndFreqFilter(EEPToEEGLabPrms)
        return
    end

    if ~EEPToEEGLabPrms.persist()
        wtProject.notifyErr([], 'Failed to save epocch limits and freqency filter params');
        return
    end

    wtProject.Config.EEPToEEGLab = EEPToEEGLabPrms;
    success = true;
end
