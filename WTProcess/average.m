% Function call to perform time-frequency analysis
%
% Written by Morten M�rup (originally called tfanalysis.m)
%
% Modified by Eugenio Parise (CDC CEU 2010 - 2011) to perform time-frequency analysis
% using Gergo's original algorithm, to perform on individual epochs if needed,
% and to cut the extra points at the edges before saving.
%
% Usage:
%   [filename,pathname]=tfanalysis(EEG,str,Fa,tim1,tim2,dt,wname,fb,chantoanal,res,normmeth)
%
% Input:
%   EEG         the EEG CURRENTSET structure
%   str         pathname and filename to save the ERPWAVELAB dataset to
%   Fa          The frequencies at which transform is to be calculated
%   tim1        time index of EEG.times at which to start transformation
%   tim2        time index of EEG.times at which to end transformation
%   dt          interval between timepoints in samples for time-frequency analysis
%   wname       name of time-frequency transformation method
%   fb          Width parameter for time-frequency transformation
%   chantoanal  The indices of channels to analyze
%   res         What measures to calculate:
%                   res(i)=1: measure i is calculated;
%                   res(i)=0: measure i is not calculated.
%                   if res=[] the full time-frequency transform of all
%                   epochs is stored.
%                       res(1): ITPC
%                       res(2): ITLC
%                       res(3): ERSP
%                       res(4): avWT
%                       res(5): WTav
%                       res(6): INDUCED
%                   if res=[0 0 1 0 0 1] then both the ERSP and INDUCED is
%                   given stored in the file savefile-ERSP and
%                   savefile-INDUCED.
%   normmeth    if specific measures are calculated this gives how the
%               time-frequency coefficients are to be normalized prior to
%               calcuting each measure.
%               normmeth=[bt1,bt2] then data is normalized by background
%                                  activity between time sample bt1 and bt2.
%               normmeth=0         no normalization
%
%   Output:
%   files       path and name of files generated
%
% Copyright (C) Morten M�rup and Technical University of Denmark,
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

function [success, files] = average(EEG,ioProc,cwtParams,subj,cond,Fa,tim1,tim2,wname,chantoanal,selection,normmeth,epochsList,cwtmatrix)
    success = false;
    files = {};
    wtLog = WTLog();

    if ~isa(cwtParams, 'WTWaveletTransformCfg')
        wtLog.excpt('BadArgType', 'Bad argument type: expected WTWaveletTransformCfg, got %s', class(cwtParams))
    end
    if ~isa(ioProc, 'IOProcessor')
        wtLog.excpt('BadArgType', 'Bad argument type: expected IOProcessor, got %s', class(ioProc))
    end
    if ~WTValidatons.isALinearCellArrayOfString(selection)
        wtLog.excpt('BadArgType', 'Bad argument type: cell expected cell array of strings, got %s', class(selection))
    end 

    dt =  cwtParams.TimeRes;
    fb = cwtParams.WaveletsCycles/2;
    extraEdges = cwtParams.EdgePadding;
    logTransform = cwtParams.LogarithmicTransform;
    evokedOscillations = cwtParams.EvokedOscillations;

    Fs = EEG.srate/dt;
    X = double(EEG.data);
    chanlocs = EEG.chanlocs;
    Fc = 1;
    scales = Fc*Fs./Fa;
    nepoch = size(X,3);
    ITPC = 0;
    ITLC = 0;
    ITLCN = 0;
    ERSP = 0;
    avWT = 0;
    WTav = 0;
    avWTi = 0;
    WTavi = 0;
    t = 0;
    N = length([tim1:dt:tim2]);
    flatepochN = 0;

    if isempty(selection)
        WT = zeros([length(chantoanal),length(Fa),N,size(X,3)]);
    else
        WT = zeros([length(chantoanal),length(Fa),N]);
    end

    wtLog = WTLog();
    wtLog.info('Transforming & averaging (sibject ''%s'' / condition ''%s'')...', subj, cond)
    wtLog.ctxOn('Transform & Average')
    wtLog.setHeaderOn(false);
    lc = length(chantoanal);

    selected = @(value)(any(cellfun(@(y)(y == value), selection)));
    ITPCSelected = selected(IOProcessor.WaveletsAnalisys_ITPC);
    ITLCSelected = selected(IOProcessor.WaveletsAnalisys_ITLC);
    ERSPSelected = selected(IOProcessor.WaveletsAnalisys_ERSP);
    avWTSelected = selected(IOProcessor.WaveletsAnalisys_avWT);
    WTavSelected = selected(IOProcessor.WaveletsAnalisys_WTav);
    InducedSelected = selected(IOProcessor.WaveletsAnalisys_Induced);

    emptySelection = ~any([ITPCSelected, ITLCSelected, ERSPSelected, avWTSelected, WTavSelected, InducedSelected]);
    
    if ~isempty(selection) && emptySelection
        wtLog.err('Not valid selection: %s', string(join(selection, ',')))
        return
    end

    if emptySelection
        k = 0;
        for j = chantoanals
            k = k+1;
            if k == 1
                wtLog.dbg('Operating on channel nr: %d/%d', k, lc)
            else
                wtLog.dbg('Operating on channel nr:  %d/%d, estimated time remaining %.2f minutes', k, lc, (lc-k)*(cputime-t)/60);
            end
            t = cputime;
            if strcmp(wname,'Gabor (stft)')
                WT(k,:,:,:) = gabortf(squeeze(X(j,:,:)),Fa, Fs, fb,tim1:dt:tim2);
            else
                WT(k,:,:,:) = fastwavelet(squeeze(X(j,:,:)), scales, wname,fb, tim1:dt:tim2);
            end
        end
    else
        % Introduced by Eugenio Parise to process individual epochs -- ON --
        if isempty(epochsList)
            epochsN = size(X,3);
            epochstotransform = [1:epochsN];
            lc = size(X,3);
        else
            epochsN = size(epochsList,2);
            epochstotransform = epochsList;
            lc = size(epochsList,2);
        end

        % Introduced by Eugenio Parise to process individual epochs -- OFF --
        for i = 1:epochsN
            actualepoch = epochstotransform(i);
            if i == 1
                wtLog.dbg('Operating on epoch nr: %d/%d', i, lc)
            else
                wtLog.dbg('Operating on epoch nr:  %d/%d, estimated time remaining %.2f minutes', i, lc, (lc-i)*(cputime-t)/60);
             end

            t = cputime;
            
            if strcmp(wname,'Gabor (stft)')
                WT = gabortf(squeeze(X(chantoanal,:,actualepoch))',Fa, Fs, fb,tim1:dt:tim2);
            elseif strcmp(wname,'cmor')
                WT = fastwavelet(squeeze(X(chantoanal,:,actualepoch))', scales, wname,fb,tim1:dt:tim2);
            elseif strcmp(wname,'cwt')  %Introduced by Eugenio Parise
                WT = wtCWT(squeeze(X(chantoanal,:,actualepoch))', Fa, tim1:dt:tim2, cwtmatrix);
            else 
                wtLog.err('Unknown wavelet type: ''%s''', wname)
                return
            end

            WT = permute(WT,[3 1 2]);
            
            if sum(sum(sum(WT))) == 0 % Prevent flat epochs to affect the final outcome
                flatepochN = flatepochN+1;
                flatepoch = 1;
            else
                flatepoch = 0;
            end
            
            if logTransform && ~flatepoch % Log transform (10-based) the data before baseline correction 
                WT = log10(WT); 
            end
            
            if length(normmeth) == 2
                WT = WT./repmat(mean(abs(WT(:,:,normmeth(1):normmeth(2))),3),[1 1 size(WT,3)]);
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

    wtLog.setHeaderOn(true);
    wtLog.ctxOff()

    if flatepochN
        wtLog.warn('%i flat ephoch(s) detected (the average and final result won''t be affected).', flatepochN);
    end

    wtLog.info('Saving time/frequency analisys: this might take a while...');
    tim = EEG.times(tim1:dt:tim2);
    wavetyp = [wname '-' num2str(fb)];
    chanlocs = chanlocs(chantoanal);

    if emptySelection
        [success, files{1}] = saveAnalysis(subj, cond, IOProcessor.WaveletsAnalisys, ...
            WT, chanlocs, Fs, Fa, wavetyp, tim, nepoch);
        if ~success 
            return
        end
    else
        if ITPCSelected
            WT = ITPC/size(X,3);
            [success, files{1}] = saveAnalysis(subj, cond, IOProcessor.WaveletsAnalisys_ITPC, ...
                WT, chanlocs, Fs, Fa, wavetyp, tim, nepoch);
            if ~success 
                return
            end
        end
        if ITLCSelected
            WT = 1/sqrt(size(X,3))*ITLC./sqrt(ITLCN);
            [success, files{end+1}] = saveAnalysis(subj, cond, IOProcessor.WaveletsAnalisys_ITLC, ...
                WT, chanlocs, Fs, Fa, wavetyp, tim, nepoch);
            if ~success 
                return
            end
        end
        if ERSPSelected
            WT = ERSP/size(X,3);
            [success, files{end+1}] = saveAnalysis(subj, cond, IOProcessor.WaveletsAnalisys_ERSP, ...
                WT, chanlocs, Fs, Fa, wavetyp, tim, nepoch);
            if ~success 
                return
            end
        end

        
        if avWTSelected
            if strcmp(wavetyp,'cwt-3.5')
                % Modified by Eugenio Parise to cut the extra edges before saving -- ON --
                WT = avWT/(size(X,3)-flatepochN);
                
                if (extraEdges/min(Fa)) >= 1
                    extratime = extraEdges/1;
                    timeRes = (tim(2)-tim(1));
                    extrapoints = extratime/timeRes;
                    
                    if mod(extrapoints,timeRes) ~= 0
                        extrapoints = extrapoints - mod(extrapoints,timeRes);
                        extratime = extrapoints*timeRes;
                    end
                    
                    e1 = find(tim == min(tim))+extrapoints;
                    e2 = find(tim == max(tim))-extrapoints;
                    t1 = min(tim)+extratime;
                    t2 = max(tim)-extratime;
                    tim = (t1:timeRes:t2);
                    WT = WT(:,:,e1:e2);
                end
                
                nepoch = nepoch-flatepochN;
                wType = IOProcessor.WaveletsAnalisys_avWT;

                if evokedOscillations
                    wType = IOProcessor.WaveletsAnalisys_evWT;
                end

                [success, files{end+1}] = saveAnalysis(subj, cond, wType, ...
                    WT, chanlocs, Fs, Fa, wavetyp, tim, nepoch);
                if ~success 
                    return
                end
            % Modified by Eugenio Parise to cut the extra edges before saving -- OFF --
            else % Original ERPWAVELAB saving
                WT = avWT/size(X,3);
                [success, files{end+1}] = saveAnalysis(subj, cond, IOProcessor.WaveletsAnalisys_avWT, ...
                    WT, chanlocs, Fs, Fa, wavetyp, tim, nepoch);
                if ~success 
                    return
                end
            end
        end

        if WTavSelected
            WT = WTav/size(X,3);
            [success, files{end+1}] = saveAnalysis(subj, cond, IOProcessor.WaveletsAnalisys_WTav, ...
                WT, chanlocs, Fs, Fa, wavetyp, tim, nepoch);
            if ~success 
                return
            end
        end

        if InducedSelected
            WT = (WTavi-abs(avWTi))/size(X,3);
            [success, files{end+1}] = saveAnalysis(subj, cond, IOProcessor.WaveletsAnalisys_Induced, ...
                WT, chanlocs, Fs, Fa, wavetyp, tim, nepoch);
            if ~success 
                return
            end
        end

        wtLog.info('Time/Frequency analysis saved!');
    end
end

function [success, fileName] = saveAnalysis(ioProc, subj, cond, wType, WT, chanlocs, Fs, Fa, wavetyp, tim,nepoch) 
    fileName = ioProc.getWaveletAnalysisFile(subj, cond, IOProcessor.WaveletsAnalisys);

    success = ioProc.writeWaveletsAnalysis(subj, cond, IOProcessor.WaveletsAnalisys, ...
        'WT', 'chanlocs','Fs','Fa','wavetyp','tim','nepoch');

    if ~success
        wtLog.err('Failed to save wavelet analisys (type ''%s'') for subject ''%s'' / condition ''%s''', ...
            subj, cond, IOProcessor.WaveletsAnalisys)
    end 
end