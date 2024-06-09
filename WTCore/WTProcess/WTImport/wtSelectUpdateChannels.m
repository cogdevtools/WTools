function success = wtSelectUpdateChannels(system)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    ioProc = wtProject.Config.IOProc;
    channelsPrms = copy(wtProject.Config.Channels);

    fileExt = ['*.' WTIOProcessor.getSystemChansLocationFileExtension(system)];
    selectionFlt = fullfile(ioProc.ImportDir, fileExt);
    [chanLocFile, ~, ~] = WTDialogUtils.uiGetFiles(selectionFlt, -1, -1, 'Select channels location file', ...
        'MultiSelect', 'off', 'restrictToDirs',  ['^' regexptranslate('escape', WTLayout.getDevicesDir()) ], ...
        WTLayout.getDevicesDir());
    if isempty(chanLocFile) 
        wtLog.warn('No channel location file selected');
        return
    end

    selectionFlt = fullfile(ioProc.ImportDir, ioProc.SplineFileTypeFlt);
    [splineFile, ~, ~] = WTDialogUtils.uiGetFiles(selectionFlt, -1, -1, 'Select spline file', ...
        'MultiSelect', 'off', 'restrictToDirs',  ['^' regexptranslate('escape', WTLayout.getDevicesDir()) ], ...
        WTLayout.getDevicesDir());
    if isempty(splineFile) 
        wtLog.warn('No spline file selected');
        return
    end

    channelsPrms.ChannelsLocationFile = chanLocFile{1};
    channelsPrms.ChannelsLocationFileType = 'autodetect';
    channelsPrms.SplineFile = splineFile{1};
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
    % The following applies to GSN-HydroCel-129.sfp but should not affect the other systems, so it's safe to filter...
    % In the future fix this code so the filter applies only to the specific set of channels.
    chansLabels = chansLabels(~cellfun(@isempty, regexp(chansLabels, '^(?!Fid).+$', 'match')));
end 