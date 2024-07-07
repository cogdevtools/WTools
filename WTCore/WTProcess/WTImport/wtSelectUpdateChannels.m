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

function success = wtSelectUpdateChannels(system)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    ioProc = wtProject.Config.IOProc;
    channelsPrms = copy(wtProject.Config.Channels);

    fileExtentions = WTIOProcessor.getSystemChansLocationFileExtension(system);
    selectionFlt = cellfun(@(e)['*' e], fileExtentions, 'UniformOutput', false);
    selectionFlt = {char(join(selectionFlt, ';')) selectionFlt{:}}';
    
    [chanLocFile, ~, ~] = WTDialogUtils.uiGetFiles(selectionFlt, -1, -1, 'Select channels location file', ...
        'MultiSelect', 'off', 'restrictToDirs', ['^' regexptranslate('escape', WTLayout.getDevicesDir()) ], ...
        WTLayout.getDevicesDir());
    if isempty(chanLocFile) 
        wtLog.warn('No channel location file selected');
        return
    end

    channelsPrms.ChannelsLocationFile = chanLocFile{1};
    channelsPrms.ChannelsLocationFileType = 'autodetect';
    channelsLabels = {};
    
    if ~WTEEGLabUtils.eeglabYesNoDlg('Cutting channels', 'Would you like to cut some channels?')
        channelsPrms.CutChannels = {};
    else
        channelsLabels = getChannelsLabels(system, channelsPrms.ChannelsLocationFile);
        if isempty(channelsLabels)
            wtProject.notifyErr([], 'No channels found in ''%s''', channelsPrms.ChannelsLocationFile);
            return
        end
        cutChannels = {};
        while isempty(cutChannels)
            [cutChannels, selected] = WTDialogUtils.stringsSelectDlg('Select channels\nto cut:', channelsLabels, false, true);
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
                    channelsLabels = getChannelsLabels(system, channelsPrms.ChannelsLocationFile);
                    if isempty(channelsLabels)
                        wtProject.notifyErr([], 'No channels found in ''%s''', channelsPrms.ChannelsLocationFile);
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

function chansLabels = getChannelsLabels(system, chanLocFile)
    chansLabels = {};

    [success, channelsLoc] = WTIOProcessor.readChannelsLocations(system, chanLocFile);
    if ~success 
        WTProject().notifyErr([], 'Failed to read channels location from ''%s''', chanLocFile); 
        return
    end

    chansLabels = cellfun(@(x)(x.Label), channelsLoc, 'UniformOutput', false);
end 