function tf_cmor(subjects,tmin,tmax,tres,frmin,frmax,fres,extraedges,ChannelsList,EpochsList,normalizeWavelet,logtransform,varargin)

%tf_cmor.m
%Created by Eugenio Parise
%CDC CEU 2010 - 2011
%Function to calculate the individual subject time-frequency transformed
%matrix using complex Morlet wavelts algorithm.
%Wavelets transformation will be calculated for each experimental
%condition.
%This script does not perform the actual wavelet transormation (done by the
%chain average.m and complexwt.m), but prepares the eeg file enlarging the
%edges to avoid distortion and it calculates the wavelets at each frequency.
%It also runs through subjects and conditions to process the whole study.
%To set this script to process the whole final sample of subjects in a study,
%edit 'subj.m' in the 'cfg' folder and digit tf_cmor([],...); ([]=empty).
%Add 'evok' as last argument to compute of evoke oscillations
%(of course, if they have been previously computed).
%
%Usage:
%
%tf_cmor('01',-300,1200,1,10,90,1,0,[],[],0,1);
%tf_cmor([],-300,1200,1,10,90,1,2000,[],[],0,1);
%tf_cmor([],-300,1200,1,10,90,1,2000,[],[],0, 0,'evok');

if ~exist('inputgui.m','file')    
    fprintf(2,'\nPlease, start EEGLAB first!!!\n');
    fprintf('\n');
    return    
end

if ispc
    sla='\';
else
    sla='/';
end

try
    PROJECTPATH=evalin('base','PROJECTPATH');
    addpath(strcat(PROJECTPATH,sla,'pop_cfg'));
    filenm;
    if exist('subj.m','file')
        subj;
        cond;
    else
        fprintf(2,'\nFile-list of imported subjects not found!!!');
        fprintf(2,'\nPlease, import the subjects first.\n');
        fprintf('\n');
        return
    end
catch
    if exist('../cfg','dir')
        addpath('../cfg');
        filenm;
        cond;
    else
        fprintf(2,'\nProject not found!!!\n');
        fprintf('\n');
        return
    end
end

if nargin
    if isempty(subjects)
        subj;
    elseif ischar(subjects)
        subjects={subjects};
    elseif ~iscell(subjects)
        fprintf(2,'\nPlease, enter a subject number in the right format (e.g. tf_cmor(''01'',...);) to process\n');
        fprintf(2,'an individual subject, or edit ''subj.m'' in the ''cfg'' folder and enter empty value,\n');
        fprintf(2,'(i.e. tf_cmor([],...);), to process the whole sample.\n');
        fprintf('\n');
        return
    end
end

if ~nargin
    
    if length(subjects)>1        
        %Select subjects interactively via GUI
        [subjlist, ok] = listdlg('PromptString','Select subjects to transform:','SelectionMode','multiple','ListString',subjects);        
        if ~ok
            return %quit on cancel button
        end      
        subjects = subjects(subjlist);        
    end
    
    %Save the processed subjects list in the subjgrand.m file in the
    %pop_cfg folder. It will be used by baseline_chop.m and
    %difference.m to process the same subjects in batch mode, by
    %grand.m and avrretrieve.m to process only transformed subjects.
    pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'subjgrand.m');
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'subjects = { ');
    for i=1:length(subjects)
        fprintf(fid, ' ''%s'' ',char(subjects(i)));
    end
    fprintf(fid, ' };');
    fclose(fid);
    
    if length(conditions)>1        
        %Select conditions interactively via GUI
        [condlist, ok] = listdlg('PromptString','Select conditions to transform:',...
            'SelectionMode','multiple','ListString',conditions,'ListSize',[180 300]);        
        if ~ok
            return %quit on cancel button
        end        
        conditions = conditions(condlist);        
    end
    
    %Save the processed conditions list in the condgrand.m file in the
    %pop_cfg folder. It will be used by baseline_chop.m and
    %difference.m to process the same conditions in batch mode, by
    %grand.m and avrretrieve.m to process only transformed conditions.
    pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'condgrand.m');
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'conditions = { ');
    for i=1:length(conditions)
        fprintf(fid, ' ''%s'' ',char(conditions(i)));
    end
    fprintf(fid, ' };\r');
    fprintf(fid, 'condiff = {};');
    fclose(fid);
    
    %Check if log was already run after averaging and if so disable the option here
    [enable_uV logFlag last_tfcmor last_bschop bs_Log]=check_evok_log(sla, PROJECTPATH);
    enable_Log='on';
    if bs_Log
        enable_Log='off';
    end
    
    %SET defaultanswer0
    defaultanswer0={[],[],1,[],[],1,0,'[  ]','[  ]',0,0,0,7};
    
    mandatoryanswersN=length(defaultanswer0);
    
    %Load previously called parameters if existing
    pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'tf_cmor_cfg.m');
    if exist(pop_cfgfile,'file')
        defaultanswer={};
        tf_cmor_cfg;
        try
            defaultanswer{1,mandatoryanswersN};
        catch
            fprintf('\n');
            fprintf(2, 'The tf_cmor_cfg.m file in the pop_cfg folder was created by a previous version\n');
            fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
            fprintf('\n');
            defaultanswer=defaultanswer0;
        end
    else
        defaultanswer=defaultanswer0;
    end
    
    parameters    = { ...
        { 'style' 'text'       'string' 'Time (ms): From     ' } ...
        { 'style' 'edit'       'string' defaultanswer{1,1} } ...
        { 'style' 'text'       'string' 'To' } ...
        { 'style' 'edit'       'string' defaultanswer{1,2} } ...
        { 'style' 'text'       'string' 'By (default = 1)' } ...
        { 'style' 'edit'       'string' defaultanswer{1,3} } ...
        { 'style' 'text'       'string' 'Frequency (Hz): From' } ...
        { 'style' 'edit'       'string' defaultanswer{1,4} } ...
        { 'style' 'text'       'string' 'To' } ...
        { 'style' 'edit'       'string' defaultanswer{1,5} } ...
        { 'style' 'text'       'string' 'By (default = 1)' } ...
        { 'style' 'edit'       'string' defaultanswer{1,6} } ...
        { 'style' 'text'       'string' 'Edges Padding (ms; default = 0)' } ...
        { 'style' 'edit'       'string' defaultanswer{1,7} } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' 'Channels to process ([  ] = all)' } ...
        { 'style' 'edit'       'string' defaultanswer{1,8} } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' 'Epochs to process ([  ] = all)' } ...
        { 'style' 'edit'       'string' defaultanswer{1,9} } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' 'Log10-Transform' 'enable' enable_Log } ...
        { 'style' 'checkbox'   'value' defaultanswer{1,10} 'enable' enable_Log } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' 'Compute Evoked Oscillations' } ...
        { 'style' 'checkbox'   'value' defaultanswer{1,11} } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' 'Normalize wavelets' } ...
        { 'style' 'checkbox'   'value' defaultanswer{1,12} } ...
        { 'style' 'text'       'string' 'Wavelet cycles (value in [2,15])' } ...
        { 'style' 'edit'       'string' defaultanswer{1,13} } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ... 
        };
    
    geometry = { ...
        [1 0.5 0.25 0.5 0.5 0.5] [1 0.5 0.25 0.5 0.5 0.5] [1 0.5 0.25 0.5 0.5 0.5] ...
        [1.34 2 0.25 0.25 0.25 0.25] [1.34 2 0.25 0.25 0.25 0.25] [1 0.5 0.25 0.5 0.5 0.5] ...
        [1 0.5 0.25 0.5 0.5 0.5] [1 0.5 0.25 0.5 0.5 0.5] [1 0.5 1 0.25 0.25 0.25] };
    
    answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set wavelet transformation parameters');
    
    if isempty(answer)
        return %quit on cancel button
    end
    
    tmin=str2num(answer{1,1});
    tmax=str2num(answer{1,2});
    tres=str2num(answer{1,3});
    frmin=str2num(answer{1,4});
    frmax=str2num(answer{1,5});
    fres=str2num(answer{1,6});
    extraedges=str2num(answer{1,7});
    ChannelsList=str2num(answer{1,8});
    EpochsList=str2num(answer{1,9});
    logtransform=answer{1,10};
    evok=answer{1,11}
    normalizeWavelet=answer{1,12};
    cycles=str2num(answer{1,13});
    if isempty(cycles) || ~(isfinite(cycles) && cycles==floor(cycles)) || cycles < 2 || cycles > 15
        fprintf(2,'\nWavelet cycles must be an positive integer in [2,15], got: %s\n', answer{1,13});
        return
    end
    if evok
        varargin='evok';
    end
    
    %Load first subject to adjust time limits
    if exist('PROJECTPATH','var')
        CommonPath = strcat (PROJECTPATH,'/');
    else
        CommonPath = strcat ('../');
    end
    currectSubj = char (strcat (filename,subjects(1),'_',conditions(1),'.set'));
    InPath = char (strcat (CommonPath,subjects(1),'/'));
    EEG = pop_loadset( 'filename', currectSubj, 'filepath', InPath);
    
    %Adjust time limits according to the data
    if tmin < fix(single(EEG.xmin*1000))
        fprintf(2,'\n%i ms is out of boundaries!!!',tmin);
        tmin = fix(single(EEG.xmin*1000));
        fprintf(2,'\nValue adjusted to lower time limit (%i ms)\n',tmin);
        fprintf('\n');
    end
    if tmax > fix(single(EEG.xmax*1000))
        fprintf(2,'\n%i ms is out of boundaries!!!',tmax);
        tmax = fix(single(EEG.xmax*1000));
        fprintf(2,'\nValue adjusted to upper time limit (%i ms)\n',tmax);
        fprintf('\n');
    end
    
    %Save the user input parameters in the pop_cfg folder
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'defaultanswer={ ''%s'' ''%s'' ''%s'' ''%s'' ''%s'' ''%s'' ''%s'' ''[ %s ]'' ''[ %s ]'' %i %i %i ''%s''};',...
        num2str(tmin),num2str(tmax),num2str(tres),num2str(frmin),num2str(frmax),num2str(fres),num2str(extraedges),...
        num2str(ChannelsList),num2str(EpochsList),logtransform,evok,normalizeWavelet,num2str(cycles));
    fclose(fid);
    
    rehash;
    
end

%Check the input is correct
if tmin > tmax
    fprintf(2,'\nThe time window is  not valid!!!\n');
    fprintf('\n');
    return
end
if frmin > frmax
    fprintf(2,'\nThe frequency band is not valid!!!\n');
    fprintf('\n');
    return
end

subjN=length(subjects);
condN = size(conditions,2);

%Generate Wavelet folder and conditions subfolders
if exist('PROJECTPATH','var')
    CommonPath = strcat (PROJECTPATH,'/');
    alreadyexistdir=strcat(CommonPath,'Wavelets');
    if ~exist(alreadyexistdir,'dir')
        mkdir(PROJECTPATH,'Wavelets');
    end
    for i = 1:condN
        alreadyexistdir=strcat(CommonPath,'Wavelets/',char(conditions(i)));
        if ~exist(alreadyexistdir,'dir')
            mkdir(strcat(CommonPath,'/Wavelets'),char(conditions(i)));
        end
    end
else
    CommonPath = strcat ('../');
    alreadyexistdir=strcat(CommonPath,'Wavelets');
    if ~exist(alreadyexistdir,'dir')
        mkdir('../','Wavelets');
    end
    for i = 1:condN
        alreadyexistdir=strcat(CommonPath,'Wavelets/',char(conditions(i)));
        if ~exist(alreadyexistdir,'dir')
            mkdir('../Wavelets',char(conditions(i)));
        end
    end
end

for i = 1:subjN
    for j = 1:condN
        
        currectSubj = char (strcat (filename,subjects(i),'_',conditions(j),'.set'));
        InPath = char (strcat (CommonPath,subjects(i),'/'));
        OutPath = char (strcat (CommonPath,'Wavelets/',conditions(j),'/',subjects(i),'_',conditions(j)));
        
        try
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        catch
            fprintf(2,'\nPlease, start EEGLAB first!!!\n');
            fprintf('\n');
            return
        end
        
        EEG = pop_loadset( 'filename', currectSubj, 'filepath', InPath);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        EEG = eeg_checkset( EEG );
        
        %ROUND times to 0 in case they are in floating point format
        EEG.times = round(EEG.times);
        
        if length(varargin)==1
            varargin=varargin{1};
        end
        
        if ~isempty(varargin)
            
            if strcmp(varargin,'evok')
                
                EEG.data=mean(EEG.data,3);
                EEG.trials=1;
                temp=EEG.epoch(1);
                EEG.epoch=[];
                EEG.epoch=temp;
                temp=EEG.event(1);
                EEG.event=[];
                EEG.event=temp;
                
            elseif ~strcmp(varargin,'evok')
                
                fprintf(2,'\nThe measure %s is unknown!!!\n',varargin);
                fprintf(2,'If you want to compute evoked oscillations, please type ''evok'' as last argument.\n');
                fprintf(2,'Type nothing if you want to compute total-induced oscillations.\n');
                fprintf('\n');
                return
                
            end
            
        end
        
        %ENLARGE the edges before starting the wavelet transformation
        if (extraedges/frmin)>=1 %There is edges padding
            %timetoadd = ceil(extraedges/frmin);
            timetoadd = ceil(extraedges/1); %This value will be used
            %to enlarge the edges and avoid distortions.
            %It will be added to the left and to the right of the epoch.
            try
                timeRes = EEG.times(2) - EEG.times(1); %find time resolution
            catch %find time resolution and restore EEG.times when there is only one trial (e.g. for evoked oscillations).
                EEG.times=[(EEG.xmin*1000):(1000/EEG.srate):((EEG.xmax*1000)+(1000/EEG.srate))];
                timeRes = EEG.times(2) - EEG.times(1);
            end
            
            pointstoadd = timetoadd/timeRes; %number of points to add to the left and to the right
            
            %check that the number of time points to add is
            %still a multiple of the sampling rate
            if mod(pointstoadd,timeRes) ~= 0
                pointstoadd = pointstoadd - mod(pointstoadd,timeRes);
                timetoadd = timeRes*pointstoadd;
            end
            
            left_edge = EEG.data(:,1:pointstoadd,:); %we double the edges of the actual signal...
            left_edge = left_edge(:,end:-1:1,:);       %... and revert them
            right_edge = EEG.data(:,end-pointstoadd+1:end,:);
            right_edge = right_edge(:,end:-1:1,:);
            
            EEGtemp = EEG.data;
            EEGnew = cat(2,left_edge, EEGtemp); %add to the left
            EEGnew = cat(2,EEGnew,right_edge);   %add to the right
            EEG.data = EEGnew;
            
            %adjust other EEGlab variables accordingly (for consistency)
            EEG.times = [single((min(EEG.times)-timetoadd)):timeRes:single((max(EEG.times)+timetoadd))];
            EEG.xmin = min(EEG.times)/1000;
            EEG.xmax = max(EEG.times)/1000;
            EEG.pnts = EEG.pnts + 2*pointstoadd; %2 because we add both to left and right of the segment
            
            %Adjust times limits according to the sampling and the new edges
            %and find them as timepoints in EEG.times
            if i==1 && j == 1 %do it only once
                
                extrapoints = mod(tmin,timeRes);
                tmin = tmin-timetoadd;
                if isempty(find(EEG.times==tmin,1))
                    tmin = tmin-extrapoints;
                end
                tmin = find(EEG.times==tmin);
                
                extrapoints = mod(tmax,timeRes);
                tmax = tmax+timetoadd;
                if isempty(find(EEG.times==tmax,1))
                    tmin = tmax+extrapoints;
                end
                tmax = find(EEG.times==tmax);
                
                clear left_edge right_edge EEGtemp EEGnew
                
            end
            
        else %There is no edges padding
            
            try
                timeRes = EEG.times(2) - EEG.times(1); %find time resolution
            catch %find time resolution and restore EEG.times when there is only one trial (e.g. for evoked oscillations).
                EEG.times=[(EEG.xmin*1000):(1000/EEG.srate):((EEG.xmax*1000)+(1000/EEG.srate))];
                timeRes = EEG.times(2) - EEG.times(1);
            end
            
            EEG.times = [single(min(EEG.times)):timeRes:single(max(EEG.times))];
            
            %Adjust times limits according to the sampling and the new edges
            %and find them as timepoints in EEG.times
            if i==1 && j == 1 %do it only once
                
                if ~find(EEG.times==tmin)
                    tmin = tmin-mod(tmin,timeRes);
                end
                tmin = find(EEG.times==tmin);
                
                if ~find(EEG.times==tmax)
                    tmax = tmax+mod(tmax,timeRes);
                end
                tmax = find(EEG.times==tmax);
                
            end
            
        end
        
        if isempty(ChannelsList)
            ChannelsList = [1:size(EEG.data,1)];
        end
        
        %Calculate wavelets at each frequency
        if i==1 && j==1 %do it only once      
            %Fa=linspace(frmin,frmax,(frmax-frmin+1));
            Fa=(frmin:fres:frmax);
            scales=Fa;
            Fs=EEG.srate/tres;
            n=cycles;
            
            cwtmatrix=cell(length(Fa),2);
            
            %Calculate CWT at each frequency.
            for iFreq=1:(length(scales))
                
                fprintf('\nComputing complex Morlet wavelet at %i Hz', scales(iFreq));
                
                freq = scales(iFreq);
                sigmaT = n/(2*freq*pi);
                
                %use COMPLEX wavelet (sin and cos components) in a form that gives
                %the RMS strength of the signal at each frequency.
                time = -4/freq:1/Fs:4/freq;
                if normalizeWavelet 
                    %generate wavelets with unit energy
                    waveletScale = (1/sqrt(Fs*sigmaT*sqrt(pi))).*exp(((time.^2)/(-2*(sigmaT^2))));
                else
                    waveletScale = (1/(Fs*sigmaT*sqrt(pi))).*exp(((time.^2)/(-2*(sigmaT^2))));
                end
                waveletRe = waveletScale.*cos(2*pi*freq*time);
                waveletIm = waveletScale.*sin(2*pi*freq*time);
                
                cwtmatrix{iFreq,1}=waveletRe(1,:);
                cwtmatrix{iFreq,2}=waveletIm(1,:);
            end
            
            fprintf('\n');
            fprintf(2,'\nWavelets saved in cell array matrix!!!\n');
            fprintf('\n');
            
            if logtransform %Log transformation requested
                %warning('off','last'); %Suppresses "Warning: Log of zero"
                fprintf(2,'Epochs will be log-transformed after wavelet transformation!!!\n');
                fprintf('\n');
            end
            
        end
        
        average(EEG,OutPath,Fa,tmin,tmax,tres,'cwt',fb,ChannelsList,[0  0  0  1  0  0],0,EpochsList,cwtmatrix,extraedges,logtransform,varargin);
        
        EEG = eeg_checkset( EEG );
        
    end
    
    eeglab redraw;
    
end

%Assign the variable subjects to the caller workspace
assignin('caller','subjects',subjects);

end