% 2024 Eugenio Parise, Luca Filippin
% ---------------------------------------------------------------------------
% Credits: in this file 
%
%  - wtAverage is a modified version of the tfanalisys.m from (ERPWAVELAB)
%
% Source code: https://www.erpwavelab.org/index_files/Page361.htm
% Copyright (C) Morten Mørup and Technical University of Denmark, 
% September 2006
%                                          
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
% ---------------------------------------------------------------------------

function [success, files] = wtAverage(EEG, cwtParams, subject, condition, Fa, timeMin, timeMax, ... 
        chansToAnalyse, selection, normalization, epochsList, cwtMatrix, skipFlatEpochs)

    success = false;
    files = {};

    wtProject = WTProject();
    wtLog = WTLog();
   
    WTValidations.mustBe(cwtParams, ?WTWaveletTransformCfg);
    if ~WTValidations.isLinearCellArrayOfChar(selection)
        WTException.badArgType('expected cell array of strings, got %s', class(selection)).throw();
    end 

    % The other params should be checked here: there are too many of them BTW...
    % ...

    ioProc = wtProject.Config.IOProc;
    extraEdges = single(cwtParams.EdgePadding);

    waveType = sprintf('Morlet-%d-cycles', cwtParams.WaveletsCycles);
    timeRes = double(cwtParams.TimeRes);
    Fs = EEG.srate/timeRes;
    minFa = single(min(Fa));
    X = double(EEG.data);
    chanlocs = EEG.chanlocs;
    ITPC = 0;
    ITLC = 0;
    ITLCN = 0;
    ERSP = 0;
    avWT = 0;
    evWT = 0;
    WTav = 0;
    avWTi = 0;
    WTavi = 0;
    WTRe = 0;
    WTIm = 0;
    t = 0;
    timeIdxs = timeMin:timeRes:timeMax;
    N = length(timeIdxs);
    nFlatEpochs = 0;

    if isempty(epochsList)
        nEpochs = size(X,3);
        epochsToTransform = 1:nEpochs;
    else
        nEpochs = size(epochsList,2);
        epochsToTransform = epochsList;
    end

    if nEpochs == 0 
        wtLog.err('No epochs found');
        return
    end

    wtLog.info('Transforming & averaging. This may take a while, hold on...', subject, condition);
    wtLog.pushStatus().contextOn('Transform & Average').HeaderOn = false;
    
    selected = @(value)(any(cellfun(@(y)(strcmp(y,value)), selection)));
    ReImSelected = selected(WTIOProcessor.WaveletsAnalisys_ReIm);
    ITPCSelected = selected(WTIOProcessor.WaveletsAnalisys_ITPC);
    ITLCSelected = selected(WTIOProcessor.WaveletsAnalisys_ITLC);
    ERSPSelected = selected(WTIOProcessor.WaveletsAnalisys_ERSP);
    avWTSelected = selected(WTIOProcessor.WaveletsAnalisys_avWT);
    evWTSelected = selected(WTIOProcessor.WaveletsAnalisys_evWT);
    WTavSelected = selected(WTIOProcessor.WaveletsAnalisys_WTav);
    InducedSelected = selected(WTIOProcessor.WaveletsAnalisys_Induced);

    emptySelection = ~any([
        ITPCSelected, ...
        ITLCSelected, ...
        ERSPSelected, ...
        WTavSelected, ...
        avWTSelected, ...
        evWTSelected, ...
        InducedSelected]);
    
    if ~isempty(selection) && emptySelection && ~ReImSelected
        wtLog.err('Not a valid selection: %s', string(join(selection, ',')));
        return
    end

    if avWTSelected && evWTSelected 
        wtLog.err('Not a valid selection: %s, %s are both selected', ...
            WTIOProcessor.WaveletsAnalisys_avWT, WTIOProcessor.WaveletsAnalisys_evWT);
        return
    end 

    wtLog.info('Processing selection: %s', string(join(selection, ',')));

    if emptySelection
        WT = zeros([length(chansToAnalyse), length(Fa), N, nEpochs]);

        if ReImSelected
            WTRe = zeros([length(chansToAnalyse), length(Fa), N, nEpochs]);
            WTIm = zeros([length(chansToAnalyse), length(Fa), N, nEpochs]);
        end
    end

    for i = 1:nEpochs
        actualEpoch = epochsToTransform(i);

        if i == 1
            wtLog.dbg('Operating on epoch %d/%d', i, nEpochs);
        else
            wtLog.dbg('Operating on epoch %d/%d, estimated time remaining %.2f minutes', i, nEpochs, (nEpochs-i)*(cputime-t)/60);
        end

        t = cputime;
        
        [WTMod, WTReal, WTImag] = wtCWT(squeeze(X(chansToAnalyse,:,actualEpoch))', Fa, timeIdxs, cwtMatrix);

        % Permute (freq, time, channel) as (channel, freq, time)
        WTMod = permute(WTMod, [3, 1, 2]);
        WTReal = permute(WTReal, [3, 1, 2]);
        WTImag = permute(WTImag, [3, 1, 2]);

        if emptySelection
            % Just collect the transformed data for each epoch, preserving all of them
            WT(:,:,:,i) = WTMod;
            
            if ReImSelected
                WTRe(:,:,:,i) = WTReal;
                WTIm(:,:,:,i) = WTImag;
            end
            continue
        end

        WT = WTMod;
        flatEpoch = sum(sum(sum(WT))) == 0;

        if flatEpoch && skipFlatEpochs
            % Prevent flat epochs to affect the final outcome
            nFlatEpochs = nFlatEpochs + 1;
            continue
        end

        if length(normalization) == 2
            WT = WT./repmat(mean(abs(WT(:,:,normalization(1):normalization(2))),3),[1 1 nEpochs]);
        end
        if ReImSelected
            WTRe = WTRe + WTReal;
            WTIm = WTIm + WTImag;
        end
        if ITPCSelected
            ITPC = ITPC+WT./abs(WT);
        end
        if ITLCSelected
            ITLC = ITLC+WT;
            ITLCN = ITLCN+abs(WT).^2;
        end
        if ERSPSelected
            ERSP = ERSP+abs(WT).^2;
        end
        if avWTSelected
            avWT = avWT+WT;
        end
        if evWTSelected
            evWT = evWT+WT;
        end
        if WTavSelected
            WTav = WTav+abs(WT);
        end
        if InducedSelected
            avWTi = avWTi+WT;
            WTavi = WTavi+abs(WT);
        end
    end

    tim = EEG.times(timeIdxs);
    chanlocs = chanlocs(chansToAnalyse);
    nEpochs = nEpochs - nFlatEpochs;
    
    if nFlatEpochs > 0 && ~emptySelection
        wtLog.warn('%i flat ephoch(s) detected (the average and final result won''t be affected).', nFlatEpochs);
    end

    saveData = @(WT, WTRe, WTIm, pType)saveAnalysis(ioProc, subject, condition, pType, ...
        WT, WTRe, WTIm, chanlocs, Fs, Fa, waveType, tim, nEpochs, nFlatEpochs);

    if emptySelection
        WT  = chopExtraTime(WT, [], [], minFa, tim, extraEdges);
        [success, files{end+1}] = saveData(WT, [], [], WTIOProcessor.WaveletsAnalisys);
        if ~success
            wtLog.popStatus(); 
            return
        end
    end

    if emptySelection && ReImSelected
        [~, WTRe, WTIm, ~] = chopExtraTime([], WTRe, WTIm, minFa, tim, extraEdges);
        [success, files{end+1}] = saveData([], WTRe, WTIm, WTIOProcessor.WaveletsAnalisys_ReIm);
        if ~success
            wtLog.popStatus(); 
            return
        end
    end

    if ~emptySelection && ReImSelected 
        WTIm = WTIm/nEpochs;
        WTRe = WTRe/nEpochs;
        [~, WTRe, WTIm, ~] = chopExtraTime([], WTRe, WTIm, minFa, tim, extraEdges);
        [success, files{end+1}] = saveData([], WTRe, WTIm, WTIOProcessor.WaveletsAnalisys_ReIm);
        if ~success
            wtLog.popStatus(); 
            return
        end
    end

    if ITPCSelected
        WT = ITPC/nEpochs;
        WT = chopExtraTime(WT, [], [], minFa, tim, extraEdges);
        [success, files{end+1}] = saveData(WT, [], [], WTIOProcessor.WaveletsAnalisys_ITPC);
        if ~success
            wtLog.popStatus();
            return
        end
    end

    if ITLCSelected
        WT = 1/sqrt(nEpochs)*ITLC./sqrt(ITLCN);
        WT = chopExtraTime(WT, [], [], minFa, tim, extraEdges);
        [success, files{end+1}] = saveData(WT, [], [], WTIOProcessor.WaveletsAnalisys_ITLC);
        if ~success
            wtLog.popStatus(); 
            return
        end
    end

    if ERSPSelected
        WT = ERSP/nEpochs;
        WT = chopExtraTime(WT, [], [], minFa, tim, extraEdges);
        [success, files{end+1}] = saveData(WT, [], [], WTIOProcessor.WaveletsAnalisys_ERSP);
        if ~success
            wtLog.popStatus(); 
            return
        end
    end
    
    if avWTSelected
        WT = avWT/nEpochs;
        WT = chopExtraTime(WT, [], [], minFa, tim, extraEdges);
        [success, files{end+1}] = saveData(WT, [], [], WTIOProcessor.WaveletsAnalisys_avWT);
        if ~success
            wtLog.popStatus();
            return
        end
    end
    
    if evWTSelected 
        % The processing is the same as for avWTSelected, but the input is supposed to be different
        WT = evWT/nEpochs;
        WT = chopExtraTime(WT, [], [], minFa, tim, extraEdges);
        [success, files{end+1}] = saveData(WT, [], [], WTIOProcessor.WaveletsAnalisys_evWT);
        if ~success
            wtLog.popStatus();
            return
        end
    end

    if WTavSelected
        WT = WTav/nEpochs;
        WT = chopExtraTime(WT, [], [], minFa, tim, extraEdges);
        [success, files{end+1}] = saveData(WT, [], [], WTIOProcessor.WaveletsAnalisys_WTav);
        if ~success
            wtLog.popStatus();
            return
        end
    end

    if InducedSelected
        WT = (WTavi-abs(avWTi))/nEpochs;
        WT = chopExtraTime(WT, [], [], minFa, tim, extraEdges);
        [success, files{end+1}] = saveData(WT, [], [], WTIOProcessor.WaveletsAnalisys_Induced);
        if ~success
            wtLog.popStatus();
            return
        end
    end

    wtLog.popStatus();
end

% chopExtraTime accept matrixes WT, WTRe, WTIm shaped either as (chan, freq, time) or (chan, freq, time, epoch)
% and returns the same matrixes with the time dimension reduced as by the extraTime parameter. 
function [WT, WTRe, WTIm, tim] = chopExtraTime(WT, WTRe, WTIm, freqMin, tim, extraTime) 
    if extraTime/freqMin < 1
        return
    end

    chop = @(m, rng)WTCodingUtils.ifThenElse(length(size(m)) == 3, @()m(:,:,rng), @()m(:,:,rng,:));
    deltaTime = tim(2) - tim(1);
    extraPoints = floor(extraTime / deltaTime);
    e1 = 1 + extraPoints;
    e2 = length(tim) - extraPoints;
    rng = e1:e2;
    tim = tim(e1:e2);

    if ~isempty(WT)
        WT = chop(WT, rng);
    end
    if ~isempty(WTRe)
        WTRe = chop(WTRe, rng);
    end
    if ~isempty(WTIm)
        WTIm = chop(WTIm, rng);
    end   
end

function [success, fullPath] = saveAnalysis(ioProc, subject, condition, processingType, WT, WTRe, WTIm, chanlocs, ...
        Fs, Fa, waveType, tim, nEpochs, nFlatEpochs) 
    wtLog = WTLog();

    if isempty(WT)
        argsName = WTCodingUtils.argsName(WTRe, WTIm, nFlatEpochs);
    else 
        argsName = WTCodingUtils.argsName(WT, nFlatEpochs);
    end

    argsName = [argsName WTCodingUtils.argsName(chanlocs, Fs, Fa, waveType, tim, nEpochs)];

    [success, fullPath] = ioProc.writeWaveletsAnalysis(subject, condition, processingType, argsName{:});
    if ~success
        wtLog.err('Failed to save wavelet analisys (subject: %s, condition: %s, type: %s)', subject, condition, processingType);
    else
        wtLog.info('Saved wavelet analisys (subject: %s, condition: %s, type: %s) to file %s', subject, condition, processingType, fullPath);
    end
end