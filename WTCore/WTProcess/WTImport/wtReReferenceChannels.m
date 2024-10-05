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

function [success, EEG] = wtReReferenceChannels(system, EEG)
    success = true; 
    wtProject = WTProject();
    wtLog = WTLog();
    channelsPrms = wtProject.Config.Channels;

    wtLog.info('Managing channels re-reference...');
    wtLog.pushStatus().contextOn().HeaderOn = false;

    try
        switch channelsPrms.ReReference
            case channelsPrms.ReReferenceNone
                wtLog.info('No channels re-referencing selected');

            case channelsPrms.ReReferenceWithAverage
                wtLog.info('Re-referencing with average');
                EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelInf, false, 'pop_reref', EEG, []);

            case channelsPrms.ReReferenceWithChannels
                wtLog.info('Re-referencing with selected channels');
                channelsPrms.validate(true);
                newRef = [];
                for ch = 1:length(channelsPrms.NewChannelsReference)
                    actualChan = char(channelsPrms.NewChannelsReference(ch));
                    chanLabels = cat(1, {}, EEG.chanlocs(1,:).labels);
                    chanIdx = find(strcmp(chanLabels, actualChan));
                    if ~isempty(chanIdx)
                        newRef = cat(1, newRef, chanIdx);  
                    else 
                        wtLog.err('Cannot find channel ''%s'' for re-reference', actualChan);
                        success = false;
                        break
                    end
                end
                if success
                    EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelInf, false, 'pop_reref', EEG, newRef, 'keepref', 'on');
                end

            otherwise
                wtLog.err('Unexpected re-reference type: %d', channelsPrms.ReReference);
                success = false;
        end
    catch me
        wtLog.except(me);
        success = false;
    end

    wtLog.popStatus();
end
