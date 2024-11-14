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

function success = wtSelectUpdateChannels(system, anySubjectFileName, importParams)
    success = false;
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;
    channelsPrms = copy(wtProject.Config.Channels);

    [ok, EEG] = ioProc.loadImport(system, anySubjectFileName, importParams);
    if ~ok 
        wtProject.notifyErr([], 'Failed to load import to get channels info: ''%s''', ioProc.getImportFile(anySubjectFileName));
        return   
    end

    selectChanLocations = true;
    channelsLabels = {};

    if isfield(EEG, 'chaninfo') && isfield(EEG.chaninfo, 'filename') && ~isempty(EEG.chaninfo.filename)
        wtProject.notifyWrn([], ['A channels locations file has been AUTOMATICALLY assigned by EEGLab to the data set.\n'...
            'It''s your responsibility to make sure that the channels locations correspond to the data.']);

        WTEEGLabUtils.eeglabMsgDlg('Info', 'The current channels layout will be displayed: close the figure once inspected.');

        if ~WTConvertGUI.displayChannelsLayoutFromData(WTIOUtils.getPathTail(EEG.chaninfo.filename), EEG.chanlocs, EEG.chaninfo)
            wtProject.notifyErr([], 'Failed to display current %s data channels layout, subject ''%s''', system, anySubjectFileName);
            return
        end
    
        selectChanLocations = WTEEGLabUtils.eeglabYesNoDlg('Change channel locations', ...
            'Would you like to select a different channel locations layout?');
    end
    
    if selectChanLocations
        [ok, chanLocsFile, localChansLocs] = selectChannelLocationsFile(system, EEG);
        if ~ok 
            return
        end
        channelsPrms.ChannelsLocationFile = chanLocsFile;
        channelsPrms.ChannelsLocationFileType = 'autodetect';
        channelsPrms.ChannelsLocationLocal = WTCodingUtils.ifThenElse(localChansLocs, 1, 0);
    else 
        channelsPrms.ChannelsLocationFile = '';
        channelsPrms.ChannelsLocationFileType = '';
        channelsPrms.ChannelsLocationLocal = 0;
        channelsLabels = cat(1, {}, EEG.chanlocs(1,:).labels);
    end

    if ~WTEEGLabUtils.eeglabYesNoDlg('Cutting channels', 'Would you like to cut some channels?')
        channelsPrms.CutChannels = {};
    else
        if isempty(channelsLabels)
            [ok, channelsLabels] = getChannelsLabels(channelsPrms.ChannelsLocationFile, channelsPrms.ChannelsLocationLocal);
            if ~ok 
                return
            end
        end

        cutChannels = {};
        while isempty(cutChannels)
            [cutChannels, selected] = WTDialogUtils.stringsSelectDlg('Select channels to cut:', channelsLabels, false, true);
            if isempty(cutChannels)
                if WTEEGLabUtils.eeglabYesNoDlg('Confirm', 'No channels to cut selected: proceed?')
                    break;
                end
            elseif length(channelsLabels) == length(cutChannels)
                wtProject.notifyWrn([], 'You can''t cut all the channels!');
                cutChannels = {};
            else
                channelsPrms.CutChannels = cutChannels;
                channelsLabels = channelsLabels(setdiff(1:end,selected));
            end
        end
    end

    if ~WTEEGLabUtils.eeglabYesNoDlg('Re-referencing channels', 'Would you like to re-reference?')
        channelsPrms.ReReference = channelsPrms.ReReferenceNone;
    else
        choices = { 'Average reference', 'New reference electrodes' };
        doneWithSelection = false;

        while ~doneWithSelection
            [~, selected] = WTDialogUtils.stringsSelectDlg('Select re-reference', choices, true, true, 'ListSize', [220, 100]);
            if isempty(selected)
                if WTEEGLabUtils.eeglabYesNoDlg('Confirm', 'No re-referencing selected: proceed?')
                    channelsPrms.ReReference = channelsPrms.ReReferenceNone;
                    doneWithSelection = true;
                end
            elseif selected == 1
                channelsPrms.ReReference = channelsPrms.ReReferenceWithAverage;
                channelsPrms.NewChannelsReference = {};
                doneWithSelection = true;
            else
                if isempty(channelsLabels)
                    [ok, channelsLabels] = getChannelsLabels(channelsPrms.ChannelsLocationFile, channelsPrms.ChannelsLocationLocal);
                    if ~ok 
                        return
                    end
                end 
                while ~doneWithSelection
                    [refChannels, ~] = WTDialogUtils.stringsSelectDlg('Select reference channels\n(cut channels are excluded):', channelsLabels, false, true);
                    if isempty(refChannels)
                        if WTEEGLabUtils.eeglabYesNoDlg('Confirm', 'No channels for re-referencing selected: proceed?')
                            channelsPrms.ReReference = channelsPrms.ReReferenceNone;
                            doneWithSelection = true;
                        end
                    else
                        channelsPrms.ReReference = channelsPrms.ReReferenceWithChannels;
                        channelsPrms.NewChannelsReference = refChannels;
                        doneWithSelection = true;
                    end
                end
            end
        end
    end 

    if ~channelsPrms.validate()
        wtProject.notifyErr([], 'Failed to validate channels parameters!');
        return
    end

    if ~channelsPrms.persist()
        wtProject.notifyErr([], 'Failed to save channels parameters!');
        return
    end

    wtProject.Config.Channels = channelsPrms;
    success = true;
end

function [success, chanLabels] = getChannelsLabels(chanLocFile, local)
    success = false;
    chanLabels = {};
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;

    [ok, chanLocs] = ioProc.readChannelsLocations(chanLocFile, local); 
    if ~ok 
        wtProject.notifyErr([], 'Failed to read channels location from ''%s''', chanLocFile); 
        return
    elseif isempty(chanLocs)
        wtProject.notifyErr([], 'No channel locations found in: ''%s''', chanLocFile); 
        return
    end
    chanLabels = cat(1, {}, chanLocs(1,:).labels);
    success = true;
end

% Channels location files should store all data channels and non data channels
function [success, chanLocsFile, local] = selectChannelLocationsFile(system, EEG)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    ioProc = wtProject.Config.IOProc;

    numberOfChans = EEG.nbchan;

    if numberOfChans == 0 
        wtLog.error('Cannot determine number of data channels!');
        return
    end 

    numberOfChansLocs = WTCodingUtils.ifThenElse(isfield(EEG, 'chanlocs'), @()length(EEG.chanlocs), 0);
    canOnlyPruneManually = true;

    if numberOfChansLocs == 0 
        wtLog.info('No channel locations have been found in the data');
    elseif numberOfChans ~= numberOfChansLocs 
        wtLog.warn('Data with #channel-locations != #actual-channels (%d != %d): locations will be ignored', ...
            numberOfChansLocs, numberOfChans);
    else
        canOnlyPruneManually = false;
    end

    fileExtentions = WTIOProcessor.getSystemChansLocationFileExtension(system);
    selectionFlt = cellfun(@(e)['*' e], fileExtentions, 'UniformOutput', false);
    selectionFlt = {char(join(selectionFlt, ';')) selectionFlt{:}}';

    while ~success
        chanLocsFile = [];
        local = false;

        [layoutFile, ~, ~] = WTDialogUtils.uiGetFiles(selectionFlt, -1, -1, 'Select channels location file', ...
            'MultiSelect', 'off', 'restrictToDirs', ['^' regexptranslate('escape', WTLayout.getChannelsLayoutsDir()) ], ...
            WTLayout.getChannelsLayoutsDir());

        if isempty(layoutFile) 
            wtLog.warn('No channel location file selected');
            return
        end

        layoutFile = layoutFile{1};

        [ok, chanLocs] = ioProc.readChannelsLocations(layoutFile, false); 
        if ~ok 
            wtProject.notifyErr([], 'Failed to read channel locations file:\n%s', layoutFile);
            return
        end

        if length(chanLocs) < numberOfChans
            wtProject.notifyWrn('Channels layout', 'Number of channels %d <  expected %d.\nSelect another layout...', ...
                length(chanLocs), numberOfChans);
            continue
        elseif length(chanLocs) == numberOfChans
            WTEEGLabUtils.eeglabMsgDlg('Info', 'The channels layout will be displayed for confirmation.\nClose the figure once inspected.');

            if ~WTConvertGUI.displayChannelsLayoutFromFile(layoutFile)
                wtProject.notifyErr([], 'Failed to display channel locations file: %s', layoutFile);
                return
            end

            if ~WTEEGLabUtils.eeglabYesNoDlg('Confirm layout', 'Do you accept the selected channel locations layout?')
                continue
            end

            chanLocsFile = layoutFile;
        elseif length(chanLocs) > numberOfChans
            wtProject.notifyWrn('Channels layout', 'Number of channels %d > expected %d.', length(chanLocs), numberOfChans);

            if ~WTEEGLabUtils.eeglabYesNoDlg('Choice', 'Adjust current layout? Or select another...')
                continue
            end

            pruneManually = true;

            if canOnlyPruneManually 
                if ~WTEEGLabUtils.eeglabYesNoDlg('Choice', ...
                    ['As no previous valid channel locations have been found in the data, you\n' ...
                     'can only prune manually the selected layout. Do you want to prune it?']);
                    continue
                end
            elseif WTEEGLabUtils.eeglabYesNoDlg('Choice', ...
                    ['Check the new layout coverage of the current layout and, if feasible,\n'...
                     'apply it by automatic sub-setting? Or prune extra channels manually...']);

                wtLog.info('User chose to adjust layout automatically by sub-setting');
                [chanLocsDiff, chanLocsPruned] = diffChannelLocations(chanLocs, EEG.chanlocs);
                pruneManually = false;

                if ~isempty(chanLocsDiff)
                    wtProject.notifyWrn('Channels layout', ...
                        'The selected layout covers only %d of %d channels\nand cannot be applied. Select another layout...', ...
                        length(chanLocsPruned), numberOfChans);
                    continue
                end
            end

            if pruneManually
                wtLog.info('User chose to prune the layou manually');
                chanLocsPruned = pruneChannelsLocations(chanLocs, numberOfChans);
                if isempty(chanLocsPruned)
                    wtLog.warn('User skipped channels locations pruning');
                    continue
                end
            end

            WTEEGLabUtils.eeglabMsgDlg('Info', ...
                'The adjusted channels layout will be displayed for confirmation.\nClose the figure once inspected.');
            [localLayoutFullPath, localLayoutFile] = ioProc.getChannelsLocationsFile(layoutFile, true);

            if ~WTConvertGUI.displayChannelsLayoutFromData(localLayoutFile, chanLocsPruned, [])
                wtProject.notifyErr([], 'Failed to display adjusted channels location from file:\n%s', layoutFile);
                return
            elseif ~WTEEGLabUtils.eeglabYesNoDlg('Confirm layout', 'Do you accept the adjusted channel locations layout?')
                continue
            end

            wtLog.info('User accepted the adjusted channels location from file: %s', layoutFile);

            if ~ioProc.writeChannelsLocations(chanLocsPruned, layoutFile)
                wtProject.notifyErr([], 'Failed to save adjusted channels locations into file:\n%s', localLayoutFullPath);
                return
            end

            wtLog.info('Adjusted channels location saved into local file: %s', localLayoutFullPath);
            chanLocsFile = layoutFile;
            local = true;
        end

        success = true;
    end
end

function [chanLocsDiff, chanLocsNewPruned] = diffChannelLocations(chanLocsNew, chanLocsCrnt)
    chanLocsDiff = {};
    chanLocsNewPruned = {};
    m = containers.Map();

    labels = WTCodingUtils.ifThenElse(isempty(chanLocsNew), @(){}, @()cat(1, {}, chanLocsNew(1,:).labels));

    for i = 1:length(labels)
        m(labels{i}) = i;
    end
    
    labels = WTCodingUtils.ifThenElse(isempty(chanLocsCrnt), @(){}, @()cat(1, {}, chanLocsCrnt(1,:).labels));

    for i = 1:length(labels)
        if ~m.isKey(labels{i})
            chanLocsDiff{end+1} = chanLocsCrnt(i);
        else
            chanLocsNewPruned{end+1} = chanLocsNew(m(labels{i}));
        end
    end

    chanLocsDiff = cell2mat(chanLocsDiff);
    chanLocsNewPruned = cell2mat(chanLocsNewPruned);
end

function chanLocs = pruneChannelsLocations(chanLocs, nChannels)
    wtProject = WTProject();
    wtLog = WTLog();
    nToPrune = length(chanLocs) - nChannels;
    
    % Out of precaution...
    if nToPrune <= 0
        chanLocs = [];
        return
    end

    wtProject.notifyWrn([], ['You are going to prune manually some channels locations: depending on the data source\n'...
        'system, you MUST be aware of the channels to prune which are not included in the EEGLab\n'...
        'data set as it appears after the import.']);

    labels = cat(1, {}, chanLocs(1,:).labels);
    msg = sprintf('Select %d channels\nto prune:', nToPrune);

    [toPrune, toPruneIdxs] = WTDialogUtils.stringsSelectLimitedDlg(msg, labels, nToPrune, nToPrune, true);
    if isempty(toPrune)
        chanLocs = [];
        return
    end

    wtLog.warn('User selected to prune the following channels: %s', char(join(toPrune,',')));
    chanLocs(toPruneIdxs) = [];
end