% Credits: a modified version of the tfanalisys.m function from (ERPWAVELAB)
% ---------------------------------------------------------------------------
% Copyright (C) Morten M¯rup and Technical University of Denmark, 
% September 2006
%                                          
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
% Revision:
% 6 November 2006    Change of t1 and t2 to be in time index instead of ms.
% 17 November 2006   Normalization by 1/f removed to main ERPWAVELAB program.
% 21 November 2006   Wrong output in Induced measure corrected.

function [success, files] = wtAverage(EEG, cwtParams, subject, condition, Fa, timeMin, timeMax, ... 
        waveletType, chansToAnalyse, selection, normalization, epochsList, cwtMatrix)

    success = false;
    files = {};

    wtProject = WTProject();
    wtLog = WTLog();
   
    WTValidations.mustBeA(cwtParams, ?WTWaveletTransformCfg);
    if ~WTValidations.isALinearCellArrayOfString(selection)
        WTException.badArgType('expected cell array of strings, got %s', class(selection)).throw();
    end 

    % The other params should be checked here: there are too many of them BTW...
    % ...

    ioProc = wtProject.Config.IOProc;
    extraEdges = single(cwtParams.EdgePadding);
    logTransform = cwtParams.LogarithmicTransform;
    evokedOscillations = cwtParams.EvokedOscillations;

    dt = cwtParams.TimeRes;
    fb = double(cwtParams.WaveletsCycles)/2;
    Fs = EEG.srate/dt;
    X = double(EEG.data);
    chanlocs = EEG.chanlocs;
    Fc = 1;
    scales = Fc*Fs./Fa;
    nEpochs = size(X,3);
    nChans = length(chansToAnalyse);
    ITPC = 0;
    ITLC = 0;
    ITLCN = 0;
    ERSP = 0;
    avWT = 0;
    WTav = 0;
    avWTi = 0;
    WTavi = 0;
    t = 0;
    timeIdxs = timeMin:dt:timeMax;
    N = length(timeIdxs);
    nFlatEpochs = 0;

    if isempty(selection)
        WT = zeros([length(chansToAnalyse),length(Fa),N,size(X,3)]);
    else
        WT = zeros([length(chansToAnalyse),length(Fa),N]);
    end

    wtLog.info('Transforming & averaging (subject/condition ''%s/%s'')...', subject, condition);
    wtLog.pushStatus().contextOn('Transform & Average').HeaderOn = false;
    
    selected = @(value)(any(cellfun(@(y)(strcmp(y,value)), selection)));
    ITPCSelected = selected(WTIOProcessor.WaveletsAnalisys_ITPC);
    ITLCSelected = selected(WTIOProcessor.WaveletsAnalisys_ITLC);
    ERSPSelected = selected(WTIOProcessor.WaveletsAnalisys_ERSP);
    avWTSelected = selected(WTIOProcessor.WaveletsAnalisys_avWT);
    WTavSelected = selected(WTIOProcessor.WaveletsAnalisys_WTav);
    InducedSelected = selected(WTIOProcessor.WaveletsAnalisys_Induced);

    emptySelection = ~any([ITPCSelected, ITLCSelected, ERSPSelected, avWTSelected, WTavSelected, InducedSelected]);
    
    if ~isempty(selection) && emptySelection
        wtLog.err('Not a valid selection: %s', string(join(selection, ',')));
        return
    end

    if emptySelection
        k = 0;
        for j = chansToAnalyse
            k = k+1;
            if k == 1
                wtLog.dbg('Operating on channel nr: %d/%d', k, nChans);
            else
                wtLog.dbg('Operating on channel nr: %d/%d, estimated time remaining %.2f minutes', k, nChans, (nChans-k)*(cputime-t)/60);
            end
            t = cputime;
            if strcmp(waveletType,'Gabor (stft)')
                WT(k,:,:,:) = gabortf(squeeze(X(j,:,:)), Fa, Fs, fb, timeIdxs);
            else
                WT(k,:,:,:) = fastwavelet(squeeze(X(j,:,:)), scales, waveletType, fb, timeIdxs);
            end
        end
    else
        % Introduced by Eugenio Parise to process individual epochs -- ON --
        if isempty(epochsList)
            epochsN = size(X,3);
            epochsToTransform = 1:epochsN;
            nChans = size(X,3);
        else
            epochsN = size(epochsList,2);
            epochsToTransform = epochsList;
            nChans = size(epochsList,2);
        end
        % Introduced by Eugenio Parise to process individual epochs -- OFF --

        for i = 1:epochsN
            actualEpoch = epochsToTransform(i);
            if i == 1
                wtLog.dbg('Operating on epoch %d/%d', i, nChans);
            else
                wtLog.dbg('Operating on epoch %d/%d, estimated time remaining %.2f minutes', i, nChans, (nChans-i)*(cputime-t)/60);
            end

            t = cputime;
            
            if strcmp(waveletType,'Gabor (stft)')
                WT = gabortf(squeeze(X(chansToAnalyse,:,actualEpoch))', Fa, Fs, fb, timeIdxs);
            elseif strcmp(waveletType,'cmor')
                WT = fastwavelet(squeeze(X(chansToAnalyse,:,actualEpoch))', scales, waveletType, fb, timeIdxs);
            elseif strcmp(waveletType,'cwt')  %Introduced by Eugenio Parise
                WT = wtCWT(squeeze(X(chansToAnalyse,:,actualEpoch))', Fa, timeIdxs, cwtMatrix);
            else 
                wtLog.err('Unknown wavelet type: ''%s''', waveletType);
                return
            end

            WT = permute(WT,[3 1 2]);
            
            if sum(sum(sum(WT))) == 0 % Prevent flat epochs to affect the final outcome
                nFlatEpochs = nFlatEpochs+1;
                flatEpoch = 1;
            else
                flatEpoch = 0;
            end
            
            if logTransform && ~flatEpoch % Log transform (10-based) the data before baseline correction 
                WT = log10(WT); 
            end
            
            if length(normalization) == 2
                WT = WT./repmat(mean(abs(WT(:,:,normalization(1):normalization(2))),3),[1 1 size(WT,3)]);
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
            if WTavSelected
                WTav = WTav+abs(WT);
            end
            if InducedSelected
                avWTi = avWTi+WT;
                WTavi = WTavi+abs(WT);
            end
        end
    end

    wtLog.popStatus();

    if nFlatEpochs > 0
        wtLog.warn('%i flat ephoch(s) detected (the average and final result won''t be affected).', nFlatEpochs);
    end

    wtLog.info('Saving time/frequency analisys: this might take a while...');
    tim = EEG.times(timeIdxs);
    waveType = [waveletType '-' num2str(fb)];
    chanlocs = chanlocs(chansToAnalyse);

    if emptySelection
        [success, files{1}] = saveAnalysis(ioProc, subject, condition, WTIOProcessor.WaveletsAnalisys, ...
            WT, chanlocs, Fs, Fa, waveType, tim, nEpochs);
        if ~success 
            return
        end
    else
        if ITPCSelected
            WT = ITPC/size(X,3);
            [success, files{1}] = saveAnalysis(ioProc, subject, condition, WTIOProcessor.WaveletsAnalisys_ITPC, ...
                WT, chanlocs, Fs, Fa, waveType, tim, nEpochs);
            if ~success 
                return
            end
        end

        if ITLCSelected
            WT = 1/sqrt(size(X,3))*ITLC./sqrt(ITLCN);
            [success, files{end+1}] = saveAnalysis(ioProc, subject, condition, WTIOProcessor.WaveletsAnalisys_ITLC, ...
                WT, chanlocs, Fs, Fa, waveType, tim, nEpochs);
            if ~success 
                return
            end
        end

        if ERSPSelected
            WT = ERSP/size(X,3);
            [success, files{end+1}] = saveAnalysis(ioProc, subject, condition, WTIOProcessor.WaveletsAnalisys_ERSP, ...
                WT, chanlocs, Fs, Fa, waveType, tim, nEpochs);
            if ~success 
                return
            end
        end
        
        if avWTSelected
            if strcmp(waveType,'cwt-3.5')
                % Modified by Eugenio Parise to cut the extra edges before saving -- ON --
                WT = avWT/(size(X,3)-nFlatEpochs);
                
                if extraEdges/single(min(Fa)) >= 1
                    extratime = extraEdges;
                    timeRes = tim(2) - tim(1);
                    extrapoints = floor(extratime/timeRes);
                    extratime = extrapoints*timeRes;
                    
                    e1 = 1 + extrapoints;
                    e2 = length(tim) - extrapoints;
                    t1 = tim(1) + extratime;
                    t2 = tim(end) - extratime;
                    tim = t1 : timeRes : t2;
                    WT = WT(:,:,e1:e2);
                end
                
                nEpochs = nEpochs-nFlatEpochs;
                wType = WTCodingUtils.ifThenElse(evokedOscillations, ...
                    WTIOProcessor.WaveletsAnalisys_evWT, WTIOProcessor.WaveletsAnalisys_avWT);

                [success, files{end+1}] = saveAnalysis(ioProc, subject, condition, wType, ...
                    WT, chanlocs, Fs, Fa, waveType, tim, nEpochs);
                if ~success 
                    return
                end
            % Modified by Eugenio Parise to cut the extra edges before saving -- OFF --
            else % Original ERPWAVELAB saving
                WT = avWT/size(X,3);
                [success, files{end+1}] = saveAnalysis(ioProc, subject, condition, WTIOProcessor.WaveletsAnalisys_avWT, ...
                    WT, chanlocs, Fs, Fa, waveType, tim, nEpochs);
                if ~success 
                    return
                end
            end
        end

        if WTavSelected
            WT = WTav/size(X,3);
            [success, files{end+1}] = saveAnalysis(ioProc, subject, condition, WTIOProcessor.WaveletsAnalisys_WTav, ...
                WT, chanlocs, Fs, Fa, waveType, tim, nEpochs);
            if ~success 
                return
            end
        end

        if InducedSelected
            WT = (WTavi-abs(avWTi))/size(X,3);
            [success, files{end+1}] = saveAnalysis(ioProc, subject, condition, WTIOProcessor.WaveletsAnalisys_Induced, ...
                WT, chanlocs, Fs, Fa, waveType, tim, nEpochs);
            if ~success 
                return
            end
        end

        wtLog.info('Time/Frequency analysis saved');
    end
end

function [success, fullPath] = saveAnalysis(ioProc, subject, condition, wType, WT, chanlocs, Fs, Fa, waveType, tim, nEpochs) 
    argsName = WTCodingUtils.argsName(WT, chanlocs, Fs, Fa, waveType, tim, nEpochs);
    [success, fullPath] = ioProc.writeWaveletsAnalysis(subject, condition, wType, argsName{:});
    if ~success
        WTLog().err('Failed to save wavelet analisys (type ''%s'') for subject ''%s'' / condition ''%s''', wType, subject, condition);
    end 
end