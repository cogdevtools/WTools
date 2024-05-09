% wtStatistics.m
% Created by Eugenio Parise
% CDC CEU 2010 - 2013
% Function to estract time-frequency points from ERPWAVELABv1.1 compatible data files.
% Baseline correction is assumed to be already done.
% It is set to process the whole final sample of subjectsList of the study.
% Set indFr to 0 to extract a frequency band (e.g. the average between 5 and
% 10 Hz). Set it to 1 to extract individual freqStrs (e.g. at 5, 6, 7, 8,
% 9 and 10 Hz separately).
% Add 'evok' as last argument to retrieve averages of evoked
% oscillations (of course, if they have been previously computed).
% DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
% Interactive user interface needs inputgui.m from EEGLab.
% 
% Usage:
% 
% wtStatistics(ChannelsList,tMin,tMax,FrMin,indFr,FrMax);
% wtStatistics(ChannelsList,tMin,tMax,FrMin,FrMax,indFr,varargin);
% wtStatistics();
% 
% wtStatistics({'E1' 'E57' 'Cz'},600,800,34,41,0);
% wtStatistics({'E1' 'E57' 'Cz'},600,800,34,41,1,'evok');
% wtStatistics();

function wtStatistics(subjectsList, conditionsList, channelsList, evokedOscillations)
    wtProject = WTProject();
    if ~wtProject.checkChopAndBaselineCorrectionDone()
        return
    end

    wtLog = WTLog();
    interactive = wtProject.Interactive;

    if ~interactive
        mustBeGreaterThanOrEqual(nargin, 4);
        WTValidations.mustBeALimitedLinearCellArrayOfString(subjectsList);
        WTValidations.mustBeALimitedLinearCellArrayOfString(conditionsList);
        WTValidations.mustBeALinearCellArrayOfString(channelsList);
        conditionsList = unique(conditionsList);
        channelsList = unique(channelsList);
    end

    if interactive
        if WTEEGLabUtils.eeglabYesNoDlg('Rebuild subjectsList?', 'Have new subjects been added?') && ~wtRebuildSubjects()
           return
        end
        [success, subjectsList, conditionsList] = setStatisticsParams();
        if ~success 
            return
        end
    end

    ioProc = wtProject.Config.IOProc;
    basicPrms = wtProject.Config.Basic;
    statsPrms = wtProject.Config.Statistics;
    conditionsGrandPrms = wtProject.Config.ConditionsGrand;
    subjectsGrandPrms =  wtProject.Config.SubjectsGrand;
    conditions = conditionsGrandPrms.ConditionsList(:)';
    subjects = subjectsGrandPrms.SubjectsList(:)';

    if interactive
        evokedOscillations = statsPrms.EvokedOscillations;
    end

    if isempty(subjectsList)
        subjectsList = subjects;
    elseif ~interactive 
        intersectSubjectsList = sort(intersect(subjectsList, subjects));
        if numel(intersectSubjectsList) ~= numel(subjectsList)
            wtLog.warn('The following subjects are not part of the current analysis and have been pruned: %s', ...
                char(join(setdiff(subjectsList, intersectSubjectsList), ',')));
            subjectsList = intersectSubjectsList;
        end 
    end

    nSubjects = length(subjectsList);
    if nSubjects == 0
        wtProject.notifyWrn([], 'Statistics aborted due to empty subjects selection');
        return
    end

    if isempty(conditionsList)
        conditionsList = conditions;
    elseif ~interactive 
        intersectConditionsList = sort(intersect(conditionsList, conditions));
        if numel(intersectConditionsList) ~= numel(conditionsList)
            wtLog.warn('The following conditions are not part of the current analysis and have been pruned: %s', ...
                char(join(setdiff(conditionsList, intersectConditionsList), ',')));
            conditionsList = conditionsList;
        end
    end

    nConditions = length(conditionsList);
    if nConditions == 0
        wtProject.notifyWrn([], 'Statistics aborted due to empty conditions selection');
        return
    end

    measure = WTCodingUtils.ifThenElse(evokedOscillations, ...
        WTIOProcessor.WaveletsAnalisys_evWT,  WTIOProcessor.WaveletsAnalisys_avWT);

    [success, data] = WTProcessUtils.loadAnalyzedData(false, subjectsList{1}, conditionsList{1}, measure);
    if ~success || ~WTConfigUtils.adjustTimeFreqDomains(wtProject.Config.Statistics, data) 
        return
    end

    allChannelsLabels = {data.chanlocs.labels}';

    if interactive
        initialValue = statsPrms.ChannelsList;
        [channelsList, channelsIdxs] = WTDialogUtils.stringsSelectDlg('Select channels\nfor statistics:', ...
            allChannelsLabels, false, true, 'InitialValue', initialValue);
        if ~isempty(channelsIdxs) 
            statsPrms.ChannelsList = channelsIdxs;
            if ~statsPrms.persist()
                wtProject.notifyErr([], 'Failed to save channel list!');
                return
            end
        end
    elseif isempty(channelsList)
        channelsList = allChannelsLabels;
        channelsIdxs = 1:length(allChannelsLabels);
    else 
        [intersectChannelsList, ~, channelsIdxs] = intersect(channelsList, allChannelsLabels);
        if numel(intersectChannelsList) ~= numel(channelsList)
            wtLog.warn('The following channels are not part of the data and have been pruned: %s', ...
                char(join(setdiff(channelsList, intersectChannelsList), ',')));
            channelsList = intersectChannelsList;
        end
    end 

    nChannels = length(channelsList);
    if nChannels == 0
        wtProject.notifyWrn([], 'Statistics aborted due to empty channels selection');
        return
    end

    % Define sub-functions for data processing
    function numStr = formatNum(x)
        numStr = sprintf('%.6e', x);
    end

    function data = calculateStats(perFreq, WT, timeIdxs, freqIdxs, channelsIdxs) 
        if perFreq 
            nFreqs = length(freqIdxs);
            data = cell(1, nFreqs);  
            for i = 1:nFreqs
                m = WT(channelsIdxs, freqIdxs(i), timeIdxs);
                data{i} = mean(m,3)';
            end
        else
            m = WT(channelsIdxs, freqIdxs, timeIdxs);  
            data = mean(mean(m,2), 3)';
        end
    end

    function cursor = formatStats(perFreq, lines, cursor, subject, header, data, freqStrs)
        if perFreq
            valueStrs = cellfun(@(x)cellfun(@(y)arrayfun(@(z)formatNum(z), y, 'UniformOutput', false), ...
                x, 'UniformOutput',false), data, 'UniformOutput', false);

            for i = 1:length(freqStrs)
                lines.Value{cursor+1} = [ freqStrs{i} ' Hz'];    
                lines.Value{cursor+2} = header;
                formatCnds = cellfun(@(c)char(join(c{i},'\t')), valueStrs, 'UniformOutput', false);
                lines.Value{cursor+3} = strcat('#', subject, '\t', char(join(formatCnds, '\t')));
                lines.Value{cursor+4} = '';
                cursor = cursor+4;
            end
        else
            valueStrs = cellfun(@(x)arrayfun(@(y)formatNum(y), x, 'UniformOutput', false), ... 
                data, 'UniformOutput',false);
            lines.Value{cursor+1} = header;
            formatCnds = cellfun(@(c)char(join(c,'\t')), valueStrs, 'UniformOutput', false);
            lines.Value{cursor+2} = strcat('#', subject, '\t', char(join(formatCnds, '\t')));
            lines.Value{cursor+3} = '';
            cursor = cursor+3;
        end
    end

    logFlag = wtProject.Config.WaveletTransform.LogarithmicTransform || ...
        wtProject.Config.BaselineChop.Log10Enable;

    timeIdxs = find(data.tim == statsPrms.TimeMin):find(data.tim == statsPrms.TimeMax);
    freqIdxs = find(data.Fa == statsPrms.FreqMin):find(data.Fa == statsPrms.FreqMax);
    freqPace = WTCodingUtils.ifThenElse(statsPrms.IndividualFreqs, data.Fa(2) - data.Fa(1), 0);
    freqStrs = arrayfun(@(x)num2str(x), data.Fa(freqIdxs), 'UniformOutput', false);

    [fullStatsFile, ~, statsFile] = ioProc.getStatisticsFile( ...
        basicPrms.FilesPrefix, logFlag, ...
        statsPrms.TimeMin, statsPrms.TimeMax, ...
        statsPrms.FreqMin, statsPrms.FreqMax, ...
        freqPace, measure);

    wtLog.info('Computing statistics: this may take a while...');

    try
        wtLog.pushStatus().contextOn().HeaderOn = false;
        perFreq = statsPrms.IndividualFreqs;
        joinedCondsChans = cellfun(@(c)strcat([c '_'], channelsList), conditionsList, 'UniformOutput', false);
        joinedCondsChans = cat(1, joinedCondsChans{:});
        header = char(join({ 'subj' char(join(joinedCondsChans, '\t')) }, '\t'));
        lines = WTHandle(cell(1, nSubjects * WTCodingUtils.ifThenElse(statsPrms.IndividualFreqs, length(freqIdxs)*4, 3)));
        cursor = 0;

        for sbj = 1:nSubjects
            wtLog.info('Processing subject %s', subjectsList{sbj});
            subject = subjectsList{1};
            statsData = cell(1, nConditions);
            wtLog.contextOn();

            for cnd = 1:nConditions
                wtLog.dbg('condition %s', conditionsList{cnd});
                condition = conditionsList{cnd};

                [success, data] = WTProcessUtils.loadAnalyzedData(false, subject, condition, measure);
                if ~success
                    return
                end
                statsData{cnd} = calculateStats(perFreq, data.WT, timeIdxs, freqIdxs, channelsIdxs);
            end

            wtLog.contextOff();
            cursor = formatStats(perFreq, lines, cursor, subject, header, statsData, freqStrs);
        end

        wtLog.contextOff().HeaderOn = true;
       
        if ~ioProc.statsWrite(statsFile, lines.Value) 
            wtProject.notifyErr([], 'Failed to save file:\n%s', fullStatsFile);
            return
        end
       
    catch me
        wtLog.popStatus();
        wtLog.except(me);
        wtProject.notifyErr([], 'Operation failed due to an unexpected error (check the log)');
        return
    end

    wtProject.notifyInf([], 'Statistics exported successfully into file:\n%s', fullStatsFile);
end

function [success, subjectsList, conditionsList] = setStatisticsParams()
    success = false;
    wtProject = WTProject();
    statsPrms = copy(wtProject.Config.Statistics);
    subjectsGrandPrms =  copy(wtProject.Config.SubjectsGrand);
    conditionsGrandPrms = copy(wtProject.Config.ConditionsGrand);

    [success, subjectsList, conditionsList] = WTStatisticsGUI.defineStatisticsSettings(statsPrms, ...
        subjectsGrandPrms, conditionsGrandPrms);
    if ~success
        return
    end
    
    if ~statsPrms.persist()
        wtProject.notifyErr([], 'Failed to save average plots params');
        return
    end

    wtProject.Config.Statistics = statsPrms;
    success = true;
end
