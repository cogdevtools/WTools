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

function [success, EEGRef] = wtCrossCheckData(EEG, EEGRef, subjFileName, channelLocationsReset)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
   
    if isempty(EEGRef)
        wtLog.info('Set reference for cross data check to...');
        printInfo(EEG, subjFileName);
        EEGRef = EEG;
        success = true;
        return
    end

    wtLog.info('Cross checking data...');
    printInfo(EEG, subjFileName);
    msgs = {};

    if EEG.nbchan ~= EEGRef.nbchan 
        msgs(end+1) = { sprintf('- Incompatible number of channels: found %d, expected %d', ...
            EEG.nbchan,  EEGRef.nbchan) };
    end

    if EEG.srate ~= EEGRef.srate 
        msgs(end+1) = { sprintf('- Incompatible sampling rate: found %d Hz, expected %d Hz', ...
            EEG.srate,  EEGRef.srate) };
    end

    if size(EEG.data, 1) ~=  EEGRef.nbchan  
        msgs(end+1) = { sprintf('- Incompatible data size: found %d channels, expected %d', ...
            size(EEG.data, 1),  EEGRef.nbchan) };
    end 

    if ~channelLocationsReset
        if ~isfield(EEG, 'chanlocs') || isempty(EEG.chanlocs)
            msgs(end+1) = { '- Missing channels locations' };
        elseif ~isfield(EEG, 'chaninfo') || isempty(EEG.chaninfo)
            msgs(end+1) = { '- Missing channels info' };
        elseif length(EEG.chanlocs) ~= EEGRef.nbchan
            msgs(end+1) = { sprintf('- Incompatible chanlocs length: found %d channels, expected %d', ...
               length(EEG.chanlocs),  EEGRef.nbchan) };
        end
    end

    success = isempty(msgs);

    if ~success 
        msgs = [ { sprintf('Data file: %s', subjFileName) } msgs ];
        wtProject.notifyErr([], char(join(msgs, "\n")));
    end
end

function printInfo(EEG, subjFileName) 
    wtLog = WTLog();
    msgs = {};
    msgs(end+1) = { sprintf('Data file: %s', subjFileName) };
    msgs(end+1) = { sprintf('  * Set name: %s', EEG.setname) };
    msgs(end+1) = { sprintf('  * Trials: %d', EEG.trials) };
    msgs(end+1) = { sprintf('  * Channels: %d', EEG.nbchan) };
    msgs(end+1) = { sprintf('  * Samples: %d', EEG.pnts) };
    msgs(end+1) = { sprintf('  * Sampling rate: %d Hz', EEG.srate) };
    wtLog().info(char(join(msgs, '\n')));
end