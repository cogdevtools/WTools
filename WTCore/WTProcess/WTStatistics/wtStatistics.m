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

function success = wtStatistics(subjectsList, conditionsList, channelsList, evokedOscillations)
    success = false;
    wtProject = WTProject();
    if ~wtProject.checkChopAndBaselineCorrectionDone()
        return
    end

    wtLog = WTLog();
    interactive = wtProject.Interactive;

    if ~interactive
        mustBeGreaterThanOrEqual(nargin, 4);
        WTValidations.mustBeLimitedLinearCellArrayOfChar(subjectsList);
        WTValidations.mustBeLimitedLinearCellArrayOfChar(conditionsList);
        WTValidations.mustBeLinearCellArrayOfChar(channelsList);
        conditionsList = unique(conditionsList);
        channelsList = unique(channelsList);
    end

    if interactive
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

    function cursor = formatStats(perFreq, repeatHeader, lines, cursor, subject, header, data, freqStrs)
        cursorStart = cursor;

        if cursorStart >= 1 && repeatHeader 
            lines.Value{cursor+1} = '';
            cursor = cursor+1;
        end
        if cursorStart == 0 || repeatHeader 
            lines.Value{cursor+1} = header;
            cursor = cursor+1;
        end

        if perFreq
            valueStrs = cellfun(@(x)cellfun(@(y)arrayfun(@(z)formatNum(z), y, 'UniformOutput', false), ...
                x, 'UniformOutput',false), data, 'UniformOutput', false);

            for i = 1:length(freqStrs) 
                formatCnds = cellfun(@(c)char(join(c{i},'\t')), valueStrs, 'UniformOutput', false);
                lines.Value{cursor+1} = [ subject, '\t' freqStrs{i} '\t' char(join(formatCnds, '\t')) ];
                cursor = cursor+1;
            end
        else
            valueStrs = cellfun(@(x)arrayfun(@(y)formatNum(y), x, 'UniformOutput', false), ... 
                data, 'UniformOutput',false);
            formatCnds = cellfun(@(c)char(join(c,'\t')), valueStrs, 'UniformOutput', false);
            lines.Value{cursor+1} = [subject '\t' char(join(formatCnds, '\t'))];
            cursor = cursor+1;
        end
    end

    logFlag = wtProject.Config.WaveletTransform.LogarithmicTransform || ...
        wtProject.Config.BaselineChop.LogarithmicTransform;

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
        % repeatHeader is always false for now, as the option is not exposed to the user
        repeatHeader = false; 
        perFreq = statsPrms.IndividualFreqs;
        joinedCondsChans = cellfun(@(c)strcat([c '_'], channelsList), conditionsList, 'UniformOutput', false);
        joinedCondsChans = cat(1, joinedCondsChans{:});
        header = WTCodingUtils.ifThenElse(perFreq, ...
            @()char(join({ 'Subj' 'Freq[Hz]' char(join(joinedCondsChans, '\t')) }, '\t')), ...
            @()char(join({ 'Subj' char(join(joinedCondsChans, '\t')) }, '\t')));
        lines = WTHandle(cell(1, 1 + nSubjects * ...
            (WTCodingUtils.ifThenElse(repeatHeader, 1, 0) + ...
             WTCodingUtils.ifThenElse(statsPrms.IndividualFreqs, length(freqIdxs), 1)) - 1));
        cursor = 0;

        for sbj = 1:nSubjects
            subject = subjectsList{sbj};
            wtLog.info('Processing subject %s', subject);
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
            cursor = formatStats(perFreq, repeatHeader, lines, cursor, subject, header, statsData, freqStrs);
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
    success = true;
end

function [success, subjectsList, conditionsList] = setStatisticsParams()
    wtProject = WTProject();
    statsPrms = copy(wtProject.Config.Statistics);
    subjectsGrandPrms =  copy(wtProject.Config.SubjectsGrand);
    conditionsGrandPrms = copy(wtProject.Config.ConditionsGrand);
    waveletTransformParams = wtProject.Config.WaveletTransform;

    evokFlag = statsPrms.EvokedOscillations;
    if waveletTransformParams.exist()
        evokFlag =  waveletTransformParams.EvokedOscillations;
    end

    [success, subjectsList, conditionsList] = WTStatisticsGUI.defineStatisticsSettings(statsPrms, ...
        subjectsGrandPrms, conditionsGrandPrms, evokFlag);
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
