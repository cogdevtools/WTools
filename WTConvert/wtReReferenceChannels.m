% Function for internal use only
function [success, EEG] = wtReReferenceChannels(system, EEG)
    success = true; 
    wtProject = WTProject();
    wtLog = WTLog();
    channelsPrms = wtProject.Config.Channels;

    wtLog.info('Managing channels re-reference...');
    wtLog.pushStatus().contextOn().HeaderOn = false;

    try
        switch channelsPrms.ReReference
            case channelsPrms.ReReferenceWithAverage
                wtLog.info('Re-referencing with average');
                EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_reref', EEG, []);
            case channelsPrms.ReReferenceWithChannels
                wtLog.info('Re-referencing with selected channels');
                channelsPrms.validate(true);
                newRef = [];
                for ch = 1:length(channelsPrms.NewChannelsReference)
                    actualChan = char(channelsPrms.NewChannelsReference(ch));
                    chanLabels = cat(1, {}, EEG.chanlocs(1,:).labels);
                    chanIdx = find(strcmp(chanLabels, actualChan));
                    newRef = cat(1, newRef, chanIdx);         
                end
                
                EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_reref', EEG, newRef ,'keepref','on');
            otherwise
                wtLog.info('No channels re-referencing');
                if system == WTIOProcessor.SystemEGI
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_chanedit', EEG, 'load', ...
                        { channelsPrms.ChannelsLocationFile, 'filetype', channelsPrms.ChannelsLocationFileType }, ...
                        'delete', 1, 'delete', 1, 'delete', 1, 'delete', 129);
                else
                    % Note: to be cheked !!!
                    % - For EEP systems:
                    %   the code below was placed before the "switch" originally
                    % - For BRV systems:
                    %   the code below was commented out originally
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_chanedit', EEG, 'load', ...
                        { channelsPrms.ChannelsLocationFile, 'filetype', channelsPrms.ChannelsLocationFileType });
                end
        end
    catch me
        wtLog.except(me);
        success = false;
    end

    wtLog.popStatus();
end
