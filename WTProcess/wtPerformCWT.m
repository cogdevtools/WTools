% wtPerformCWT.m
% Created by Eugenio Parise
% CDC CEU 2010 - 2011
% Function to calculate the individual subject time-frequency transformed
% matrix using complex Morlet wavelts algorithm.
% Wavelets transformation will be calculated for each experimental
% condition.
% This script does not perform the actual wavelet transormation (done by the
% chain average.m and wtCWT.m), but prepares the eeg file enlarging the
% edges to avoid distortion and it calculates the wavelets at each frequency.
% It also runs through subjects and conditions to process the whole study.
% To set this script to process the whole final sample of subjects in a study,
% edit 'subj.m' in the 'cfg' folder and digit wtPerformCWT([],...); ([]=empty).
% Add 'evok' as last argument to compute of evoke oscillations
% (of course, if they have been previously computed).
% 
% Usage:
% 
% wtPerformCWT('01',-300,1200,1,10,90,1,0,[],[],0,7,1);
% wtPerformCWT([],-300,1200,1,10,90,1,2000,[],[],0,7,1);
% wtPerformCWT([],-300,1200,1,10,90,1,2000,[],[],0,7,0,'evok');

function wtPerformCWT(interactive)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkIsOpen()
        return
    end
    if nargin == 0 
        interactive = true;
    end

    prefixData = wtProject.Config.Prefix;
    subjsGrandData = wtProject.Config.SubjectsGrand;
    condsGrandData = wtProject.Config.ConditionsGrand;
    waveletTransformData = wtProject.Config.WaveletTransform;
    subjects = wtProject.Config.Subjects.SubjectsList;
    conditions = wtProject.Config.Conditions.ConditionsList;
    ProjectRootDir = wtProject.Config.getRootDir();

    if logical(interactive)
        if ~selectUpdateSubjects(subjsGrandData, subjects) || ...
            ~selectUpdateConditions(condsGrandData, conditions)
            return
        end

        [timeRange, maxFreq, maxChans] = getTransformDomain(ProjectRootDir, prefixData.FilesPrefix, subjects{1}, conditions{1}); 
        [~, ~, ~, ~, disableLog] = wtCheckEvokLog(); % Check if log was already run after averaging and if so disable the option here

        if ~setUpdateTransformPrms(waveletTransformData, timeRange, maxFreq, maxChans, ~disableLog)
            return
        end
    end

    timeMin = waveletTransformData.TimeMin;
    timeMax = waveletTransformData.TimeMax;
    ChannelsList = waveletTransformData.ChannelsList;

    if isempty(ChannelsList)
        ChannelsList = 1:maxChans;
    end

    subjectsCount = length(subjects);
    conditionsCount = size(conditions,2);
    
    wtLog.info('Performing time/frequency analysis...');
    ioProcessor = wtProject.Config.IOProc;

    for i = 1:subjectsCount
        for j = 1:conditionsCount
            wtLog.info('Processing subject/condition: %d/%d', i, j);
            wtLog.ctxOn('Subj(%d)/Cond(%d)', i, j)

            [success, EEG] = ioProcessor.readSubjectCondition(prefixData.FilesPrefix, subjects{i}, conditions{j});
            if ~success
                wtLog.ctxOff();
                return
            end 

            % Adjust ecpochs list
            nEpochs = size(EEG.data, 3);
            adjEpochsList = waveletTransformData.EpochsList(waveletTransformData.EpochsList <= nEpochs);
    
            % ROUND times to 0 in case they are in floating point format
            EEG.times = round(EEG.times);
                
            if waveletTransformData.EvokedOscillations
                EEG.data = mean(EEG.data,3);
                EEG.trials = 1;
                EEG.epoch = EEG.epoch(1);
                EEG.event = EEG.event(1);
            end
    
            % ENLARGE the edges before starting the wavelet transformation
            if (waveletTransformData.EdgePadding / waveletTransformData.FreqMin) >= 1 % There is edges padding
                timeToAdd = ceil(waveletTransformData.EdgePadding / 1); % This value will be used
                % to enlarge the edges and avoid distortions.
                % It will be added to the left and to the right of the epoch.
                try
                    timeRes = EEG.times(2) - EEG.times(1); % find time resolution
                catch % find time resolution and restore EEG.times when there is only one trial (e.g. for evoked oscillations).
                    EEG.times = (EEG.xmin*1000) : (1000/EEG.srate) : ((EEG.xmax*1000)+(1000/EEG.srate));
                    timeRes = EEG.times(2) - EEG.times(1);
                end
                
                pointsToAdd = timeToAdd/timeRes; % number of points to add to the left and to the right
                
                % check that the number of time points to add is
                % still a multiple of the sampling rate
                if mod(pointsToAdd,timeRes) ~= 0
                    pointsToAdd = pointsToAdd - mod(pointsToAdd,timeRes);
                    timeToAdd = timeRes*pointsToAdd;
                end
                
                leftEdge = EEG.data(:,1:pointsToAdd,:); % we double the edges of the actual signal...
                leftEdge = leftEdge(:,end:-1:1,:);       % ... and revert them
                rightEdge = EEG.data(:,end-pointsToAdd+1:end,:);
                rightEdge = rightEdge(:,end:-1:1,:);
                
                EEGtemp = EEG.data;
                EEGnew = cat(2,leftEdge,EEGtemp); % add to the left
                EEGnew = cat(2,EEGnew,rightEdge);  % add to the right
                EEG.data = EEGnew;
                
                % adjust other EEGlab variables accordingly (for consistency)
                EEG.times = single((min(EEG.times)-timeToAdd)) : timeRes : single((max(EEG.times)+timeToAdd));
                EEG.xmin = min(EEG.times)/1000;
                EEG.xmax = max(EEG.times)/1000;
                EEG.pnts = EEG.pnts + 2*pointsToAdd; % 2 because we add both to left and right of the segment
                
                % Adjust times limits according to the sampling and the new edges
                % and find them as timepoints in EEG.times
                if i == 1 && j == 1 % do it only once
                    extrapoints = mod(timeMin,timeRes);
                    timeMin = timeMin - timeToAdd;
                    if isempty(find(EEG.times == timeMin,1))
                        timeMin = timeMin - extrapoints;
                    end
                    timeMin = find(EEG.times == timeMin);
                    
                    extrapoints = mod(timeMax,timeRes);
                    timeMax = timeMax + timeToAdd;
                    if isempty(find(EEG.times == timeMax,1))
                        timeMin = timeMax + extrapoints;
                    end
                    timeMax = find(EEG.times == timeMax);
                    clear leftEdge rightEdge EEGtemp EEGnew
                end
                
            else % There is no edges padding
                try
                    timeRes = EEG.times(2) - EEG.times(1); % find time resolution
                catch % find time resolution and restore EEG.times when there is only one trial (e.g. for evoked oscillations).
                    EEG.times = (EEG.xmin*1000) : (1000/EEG.srate) : ((EEG.xmax*1000)+(1000/EEG.srate));
                    timeRes = EEG.times(2) - EEG.times(1);
                end
                
                EEG.times = single(min(EEG.times)):timeRes:single(max(EEG.times));
                
                % Adjust times limits according to the sampling and the new edges
                % and find them as timepoints in EEG.times
                if i == 1 && j == 1 % do it only once
                    if ~find(EEG.times == timeMin)
                        timeMin = timeMin - mod(timeMin,timeRes);
                    end
                    timeMin = find(EEG.times == timeMin);
                    
                    if ~find(EEG.times == timeMax)
                        timeMax = timeMax + mod(timeMax,timeRes);
                    end
                    timeMax = find(EEG.times == timeMax); 
                end
            end
    
            % Calculate wavelets at each frequency (once)
            if i == 1 && j == 1
                cwMatrix, Fa = generateMorletWavelets(waveletTransformData, EEG.srate);     
            end
            
            [success, ~] = average(EEG, ioProcessor, waveletTransformData, subjects{i}, conditions{j}, Fa, timeMin, timeMax,'cwt', ...
                ChannelsList, {IOProcessor.WaveletsAnalisys_avWT}, 0, adjEpochsList, cwMatrix);

            if ~success
                wtLog.ctxOff(); 
                return
            end

            WTUtils.eeglabRun('eeg_checkset', EEG);
        end
    end
    % Assign the variable subjects to the caller workspace
    assignin('caller','subjects',subjects);
    wtLog.ctxOff(); 
    wtLog.info('Time/Frequency analysis completed!');
end

function success = selectUpdateSubjects(subjectsGrand, subjectsList) 
    success = false;
    if isempty(subjectsList)
        wtLog.warn('Empty subject list')
        return
    end 
    subjectsList = wtStrCellsSelectGUI(subjectsList, 'Select subjects to transform:');
    if isempty(subjectsList)
        wtLog.warn('No subjects selected')
        return
    end
    subjectsGrand.SubjectsList = subjectsList;
    if ~subjectsGrand.persist()
        wtLog.err('Failed to save subjects grand params')
        return
    end
    success = true;
end

function success = selectUpdateConditions(condsGrand, conditionsList) 
    success = false;
    if isempty(conditionsList)
        WTLog().warn('Empty conditions list')
        return
    end
    conditionsList = wtStrCellsSelectGUI(conditionsList, 'Select conditions to transform:');
    if isempty(conditionsList)
        WTLog().warn('No conditions selected')
        return
    end
    condsGrand.ConditionsList = conditions;
    condsGrand.ConditionsDiff = {};
    if ~condsGrand.persist() 
        WTLog().err('Failed to save conditions grand params')
        return
    end
    success = true;
end

function [timeRange, maxFreq, maxChans] = getTransformDomain(dataFileDir, dataFilePx, subject, condition) 
    fileName = strcat(dataFilePx, subject, '_', condition,'.set');
    inPath = fullfile(dataFileDir, subject);
    EEG = WTUtils.eeglabRun('pop_loadset', 'filename', fileName, 'filepath', inPath);
    timeRange = int64([EEG.xmin*1000 EEG.xmax*1000]);
    maxFreq = EEG.srate/2;
    maxChans = size(EEG.data, 1);
end

function success = setUpdateTransformPrms(waveletTransformData, timeRange, maxFreq, maxChans) 
    success = false;
    if ~wtCWTParamsGUI(waveletTransformData, timeRange, maxFreq, maxChans)
        return
    end
    if ~waveletTransformData.persist() 
        WTLog().err('Failed to save complex Morlet transform params')
        return
    end
    success = true;
end

function [cwMatrix, scales] = generateMorletWavelets(waveletTransformData, samplingRate)
    scales = (waveletTransformData.FreqMin : waveletTransformData.FreqRes : waveletTransformData.FreqMax);
    Fs = samplingRate / waveletTransformData.TimeRes;
    cwMatrix = cell(length(Fa),2);
                
    % Calculate CWT at each frequency.
    wtLog.info('Computing Morlet complex wavelets...');
    wtLog.ctxOn('Complex Wavelets');
    wtLog.setHeaderOn(false);

    for iFreq=1:(length(scales))
        wtLog.dbg('Generating wavelet at frequency = %i Hz', scales(iFreq));
        
        freq = scales(iFreq);
        sigmaT =  waveletTransformData.WaveletsCycles / (2*freq*pi);
        
        % use COMPLEX wavelet (sin and cos components) in a form that gives
        % the RMS strength of the signal at each frequency.
        time = -4/freq : 1/Fs : 4/freq;
        if waveletTransformData.NormalizedWavelets
            % generate wavelets with unit energy
            waveletScale = (1/sqrt(Fs*sigmaT*sqrt(pi))).*exp(((time.^2)/(-2*(sigmaT^2))));
        else
            waveletScale = (1/(Fs*sigmaT*sqrt(pi))).*exp(((time.^2)/(-2*(sigmaT^2))));
        end
        waveletRe = waveletScale.*cos(2*pi*freq*time);
        waveletIm = waveletScale.*sin(2*pi*freq*time);
        cwMatrix{iFreq,1} = waveletRe(1,:);
        cwMatrix{iFreq,2} = waveletIm(1,:);
    end

    wtLog.setHeaderOn(true);
    wtLog.ctxOff();
    wtLog.info('Wavelets saved in cell array matrix');
    
    if waveletTransformData.LogarithmicTransform 
        wtLog.warn('Epochs will be log-transformed after wavelet transformation!');
    end
end