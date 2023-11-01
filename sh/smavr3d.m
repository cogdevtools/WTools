function smavr3d(subj,tMintMax,FrMinFrMax,scale,varargin)
%smavr3d.m
%Created by Eugenio Parise
%CDC CEU 2011
%One line of code has been taken from Luca Filippin's EGIWaveletPlot.m
%It plots 3D scalpmaps of wavelet transformed EEG channels (for each condition).
%It uses headplot function from EEGLab, so EEGLab must be installed and
%included in Matlab path.
%It can plot a single timepoint, the average of a time window, as well as a
%single frequency or an averaged frequency band.
%
%It does not plot scalpmap series! Please, use smavr.m for this purpose.
%
%Add 'evok' as last argument to compute 3D scalp maps of evoked
%oscillations (of course, if they have been previously computed).
%DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
%Interactive user interface needs inputgui.m from EEGLab.
%
%Usage:
%
%smavr3d(subj,tMintMax,FrMinFrMax,scale);
%
%smavr3d('01',800,15,[-0.2 0.2]); %to plot a single subject,
%at 800 ms and at 15 Hz
%
%smavr3d('05',[240 680],5,[-0.2 0.2]); %to plot a single subject,
%average between 240 and 680 ms at 5 Hz
%
%smavr3d('grand',350,[10 60],[-0.2 0.2]); %to plot the grand average,
%average between at 350 ms in the 10 to 60 Hz averaged band
%
%smavr3d('grand',[100 400],[10 60],[-0.2 0.2]); %to plot the grand average,
%average between 100 and 400 ms in the 10 to 60 Hz averaged band
%
%smavr3d(); to run via GUI

if ~exist('headplot.m','file')    
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
    addpath(strcat(PROJECTPATH,'/pop_cfg'));
    filenm;
    if exist('condgrand.m','file')
        condgrand;
        condgrands=cat(2,conditions,condiff);
    else
        fprintf(2,'\nFile-list of transformed conditions not found!!!\n');
        fprintf('\n');
        return
    end
    chan;
    wtoolspath = which('smavr3d.m');
    slashes = findstr(wtoolspath,sla);
    splnFile = char (strcat (wtoolspath(1:slashes(end-1)),'chans_splines/',splnfile));    
    if cell2mat(strfind(splnfile,'Infant'))
        meshFile = char (strcat (wtoolspath(1:slashes(end-1)),'chans_splines/',splnfile{1}(1:end-3),'mat'));
    end    
    cd (PROJECTPATH);
catch
    if exist('../cfg','dir')
        addpath('../cfg');
        filenm;
        condgrand;
        condgrands=cat(2,conditions,condiff);
        chan;
        splnFile = char (strcat ('../cfg/',splnfile));        
        if cell2mat(strfind(splnfile,'Infant'))
            meshFile = char (strcat (wtoolspath(1:slashes(end-1)),'chans_splines/',splnfile{1}(1:end-3),'mat'));
        end        
    else
        fprintf(2,'\nProject not found!!!\n');
        fprintf('\n');
        return
    end
end

if length(varargin)==1
    varargin=varargin{1};
end

if isempty(varargin)    
    measure=strcat('_bc-avWT.mat');    
elseif strcmp(varargin,'evok')    
    measure=strcat('_bc-evWT.mat');    
elseif ~strcmp(varargin,'evok')
    
    fprintf(2,'\nThe measure %s is not present in the %s folder!!!\n',varargin,subj);
    fprintf(2,'If you want to plot evoked oscillations, please type ''evok'' as last argument (after the argument scale).\n');
    fprintf(2,'Type nothing after the argument scale if you want to plot total-induced oscillations.\n');
    fprintf('\n');
    return    
end

%Make pop_cfg folder to store config files for gui working functions
if exist('PROJECTPATH','var')
    CommonPath = strcat (PROJECTPATH,'/');
    alreadyexistdir=strcat(CommonPath,'pop_cfg');
    if ~exist(alreadyexistdir,'dir')
        mkdir (CommonPath,'pop_cfg');
    end
    addpath(strcat(PROJECTPATH,'/pop_cfg'));
    pop_cfgfile = strcat(CommonPath,'pop_cfg/smavr3d_cfg.m');
else
    CommonPath = strcat ('../');
    alreadyexistdir=strcat(CommonPath,'pop_cfg');
    if ~exist(alreadyexistdir,'dir')
        mkdir (CommonPath,'pop_cfg');
    end
    addpath(strcat('../','pop_cfg'));
    pop_cfgfile = strcat('../pop_cfg/smavr3d_cfg.m');
end

%Call gui only if no arguments were entered
if ~nargin
    [filenames, pathname, filterindex]=uigetfile({ '*-avWT.mat'; '*-evWT.mat' },...
        'Select files to plot','MultiSelect','on');    
    if ~pathname
        return %quit on cancel button
    end    
    %Find subject/grand folder from the path
    if ispc
        sla='\';
    else
        sla='/';
    end
    slashs=findstr(pathname,sla);
    subj=pathname(slashs(end-1)+1:end-1);    
    if filterindex==2
        varargin='evok';
        measure=strcat('_bc-evWT.mat');
    elseif filterindex==3
        fprintf(2,'\nYou cannot select -avWT.mat and -evWT.mat at the same time,\n');
        fprintf(2,'neither any other different kind of file!!!\n');
        fprintf(2,'Please, select either -avWT.mat or -evWT.mat files.\n');
        fprintf('\n');
        return
    end

    %CHECK if the data have been log-transformed
    [enable_uV logFlag]=check_evok_log(PROJECTPATH);
    
    %SET defaultanswer0
    %SET color limits and GUI
    if logFlag
        defaultanswer0={'[    ]','[    ]','[-10.0    10.0]'};
        Scale='Scale (�x% change)';
    else
        defaultanswer0={'[    ]','[    ]','[-0.5    0.5]'};
        Scale='Scale (mV)';
    end
    
    answersN=length(defaultanswer0);
    
    %Load previously called parameters if existing
    if exist(pop_cfgfile,'file')
        smavr3d_cfg;
        try
            defaultanswer=defaultanswer;
            defaultanswer{1,answersN};
            
            %Reset default scale if needed (e.g. the user changed from uV
            %to log or vice versa) and if the scale is symmetric
            scale=str2num(defaultanswer{1,3});
            if (abs(scale(1))==abs(scale(2))) && (logFlag && (scale(2)<3)) || (~logFlag && (scale(2)>=3))
                defaultanswer{1,3}=defaultanswer0{1,3};
            end
            
        catch
            fprintf('\n');
            fprintf(2, 'The smavr3d_cfg.m file in the pop_cfg folder was created by a previous version\n');
            fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
            fprintf('\n');
            defaultanswer=defaultanswer0;
        end
    else
        defaultanswer=defaultanswer0;
    end
    
    parameters = { ...
        { 'style' 'text'       'string' 'Time (ms): From - To     ' } ...
        { 'style' 'edit'       'string' defaultanswer{1,1} } ...
        { 'style' 'text'       'string' 'Frequency (Hz): From - To' } ...
        { 'style' 'edit'       'string' defaultanswer{1,2} }...
        { 'style' 'text'       'string' Scale } ...
        { 'style' 'edit'       'string' defaultanswer{1,3} } };
    
    geometry = { [1 1] [1 1]  [1 1] };
    
    answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set plotting parameters');
    
    if isempty(answer)
        return %quit on cancel button
    end
    
    tMintMax=str2num(answer{1,1});
    FrMinFrMax=str2num(answer{1,2});
    scale=str2num(answer{1,3});
    
    if length(tMintMax)>2 || length(FrMinFrMax)>2
        fprintf(2,'\nsmavr3d cannot plot scalp map series!!!\n');
        fprintf(2,'For that, use smavr instead.\n');
        fprintf('\n');
        return
    end
    
    %Find conditions to plot from the user selected files
    if ~iscell(filenames)
        filenames={filenames};
    end
    filenames=sort(filenames);
    condtoplot=cell(length(filenames),length(condgrands));
    condgrands=sort(condgrands);
    
    %Clean filenames from measure and file extensions
    a=cell(length(filenames));
    for i=1:length(filenames)
        a{i}=strfind(filenames,measure);
        if ~strcmp(subj,'grand')
            b=strfind(filenames,'_');
            filenames{i}=filenames{i}(b{i}(1)+1:a{1}{i}-1);
        else
            filenames{i}=filenames{i}(1:a{1}{i}-1);
        end
    end
    
    for i=1:length(filenames)
        for j=1:length(condgrands)
            condtoplot{i,j}=strcmp(filenames{i},condgrands{j});
            if condtoplot{i,j}==0
                condtoplot{i,j}=[];
            end
        end
    end
    
    [a,b]=find(~cellfun(@isempty,condtoplot));
    condtoplot=unique(b');
    condgrands=condgrands(condtoplot);
    condN = size(condgrands,2);
    
end

%CHECK if difference and/or grand average files are up to date
[diffConsistency grandConsistency]=check_diff_grand(filenames, condiff, subj, logFlag);
if ~diffConsistency || ~grandConsistency
    return
end

%Check the input is correct
if isempty(tMintMax) || tMintMax(1) > tMintMax(end)
    fprintf(2,'\nThe time window is  not valid!!!\n');
    fprintf('\n');
    return
end
if isempty(FrMinFrMax) || FrMinFrMax(1) > FrMinFrMax(end)
    fprintf(2,'\nThe frequency band is not valid!!!\n');
    fprintf('\n');
    return
end
if scale(1) >= scale(2)
    fprintf(2,'\nThe scale is not valid!!!\n');
    fprintf('\n');
    return
end

if length(tMintMax)>2 || length(FrMinFrMax)>2
    fprintf(2,'\nsmavr3d cannot plot scalp map series!!!\n');
    fprintf(2,'Use smavr instead.\n');
    fprintf('\n');
    return
end

%Prompt the user to select the conditions to plot when using command line
%function call
if ~exist('condtoplot','var')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Taken from Luca Filippin's EGIWaveletPlot.m%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [condtoplot,ok] =listdlg('ListString', condgrands, 'SelectionMode', 'multiple',...
        'Name', 'Select Conditions','ListSize', [200, 200]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    if ~ok
        return
    else
        condgrands=condgrands(condtoplot);
        condN = size(condgrands,2);
    end    
end

if strcmp(subj,'grand')    
    if exist('PROJECTPATH','var')
        CommonPath = strcat (PROJECTPATH,'/grand/');
    else
        CommonPath = strcat ('../grand/');
    end    
    %load the first condition to take information from the matrixs 'Fa', 'tim' and 'chanlocs'
    %(see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
    firstCond = strcat (CommonPath,condgrands(1),measure);
    load (char(firstCond));    
else    
    if exist('PROJECTPATH','var')
        CommonPath = strcat (PROJECTPATH,'/');
    else
        CommonPath = strcat ('../');
    end    
    %load the first condition to take information from the matrixs 'Fa', 'tim' and 'chanlocs'
    %(see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
    firstCond = strcat (CommonPath,subj,'/',subj,'_',condgrands(1),measure);
    load (char(firstCond));    
end

timeRes = tim(2) - tim(1); %find time resolution
if length(Fa)>1
    frRes = Fa(2) - Fa(1);     %find frequency resolution
else
    frRes = 1;
end

%Adjust times and frequencies limits according to the data sampling
tMin=tMintMax(1);
if tMin<min(tim)
    tMin=min(tim);
    fprintf(2,'\n%i ms is out of boundaries!!!',tMintMax(1));
    fprintf(2,'\nValue adjusted to the lower time (%i ms)\n',min(tim));
    tTemp=[tMin];
elseif tMin>max(tim)
    tMin=max(tim);
    fprintf(2,'\n%i ms is out of boundaries!!!',tMintMax(1));
    fprintf(2,'\nValue adjusted to the higher time (%i ms)\n',max(tim));
    tTemp=[tMin];
else
    tMin=tMintMax(1)-mod(tMintMax(1),timeRes);
    while ~any(tim==tMin)
        tMin=tMin+1;
    end
    tTemp=[tMin];
end
if length(tMintMax)==2
    tMax=tMintMax(2);
    if tMax>max(tim)
        tMax=max(tim);
        fprintf(2,'\n%i ms is out of boundaries!!!',tMintMax(2));
        fprintf(2,'\nValue adjusted to the higher time (%i ms)\n',max(tim));
    else
        tMax=tMintMax(2)-mod(tMintMax(2),timeRes);
        while ~any(tim==tMax)
            tMax=tMax+1;
        end
    end
    tTemp=[tMin tMax];
end
FrMin=FrMinFrMax(1);
if FrMin<min(Fa)
    FrMin=min(Fa);
    fprintf(2,'\n%i Hz is out of boundaries!!!',FrMinFrMax(1));
    fprintf(2,'\nValue adjusted to the lower frequency (%i Hz)\n',min(Fa));
    FrTemp=[FrMin];
elseif FrMin>max(Fa)
    FrMin=max(Fa);
    fprintf(2,'\n%i Hz is out of boundaries!!!',FrMinFrMax(1));
    fprintf(2,'\nValue adjusted to the higher frequency (%i Hz)\n',max(Fa));
    FrTemp=[FrMin];
else
    FrMin=FrMinFrMax(1)-mod(FrMinFrMax(1),frRes);
    while ~any(Fa==FrMin)
        FrMin=FrMin+1;
    end
    FrTemp=[FrMin];
end
if length(FrMinFrMax)==2
    FrMax=FrMinFrMax(2);
    if FrMax>max(Fa)
        FrMax=max(Fa);
        fprintf(2,'\n%i Hz is out of boundaries!!!',FrMinFrMax(2));
        fprintf(2,'\nValue adjusted to the higher frequency (%i Hz)\n',max(Fa));
    else
        FrMax=FrMinFrMax(2)-mod(FrMinFrMax(2),frRes);
        while ~any(Fa==FrMax)
            FrMax=FrMax+1;
        end
    end
    FrTemp=[FrMin FrMax];
end

%Save the user input parameters in the pop_cfg folder
if ~nargin
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'defaultanswer={''[%s]'' ''[%s]'' ''[%s]''};',...
        num2str(tTemp),num2str(FrTemp),num2str(scale,'%.1f'));
    fclose(fid);    
    rehash;    
end

%Calculate latency subset to plot
if length(tMintMax)==2
    lat=find(tim==tMin):find(tim==tMax);
    latchar=strcat(num2str(tMin),'_',num2str(tMax));
else
    lat=find(tim==tMin);
    latchar=num2str(tMin);
end

%Calculate frequency subset to plot
if length(FrMinFrMax)==2
    fr=find(Fa==FrMin):find(Fa==FrMax);
    frchar=strcat(num2str(FrMin),'_',num2str(FrMax));
else
    fr=find(Fa==FrMin);
    frchar=num2str(FrMin);
end

fprintf('\n');
fprintf('Plotting...\n');
fprintf('\n');

for cn=1:condN    
    if logFlag %Convert the data back to non-log scale straight in percent change        
        WT=100*(10.^WT - 1);        
    end    
    if strcmp(subj,'grand')        
        figurename=char(strcat(filename,condgrands(cn),'_',latchar,'ms','_',frchar,'Hz',measure));        
    else        
        figurename=char(strcat(filename,'Subj',subj,'_',condgrands(cn),'_',latchar,'ms','_',frchar,'Hz',measure));        
    end
    
    %Average along times
    WT=mean(WT(:,:,lat),3);
    %Average along frequencies
    WT=mean(WT(:,fr,:),2);
    
    %Create the figure
    figure('NumberTitle', 'off', 'Name', figurename, 'ToolBar','none');
    
    if exist('meshFile','var')
        [hdaxis cbaraxis]=headplot(WT,splnFile,'meshfile',meshFile,'electrodes',...
            'off','maplimits',scale,'cbar',0);
    else
        [hdaxis cbaraxis]=headplot(WT,splnFile,'electrodes','off','maplimits',...
            scale,'cbar',0);
    end
    
    if strcmp(enable_uV,'on')
        set(get(cbaraxis,'xlabel'),'String','\muV','FontSize',12,'FontWeight',...
            'bold','Position',[8 0.55]);
    else
        set(get(cbaraxis,'xlabel'),'String','% change','Rotation',90,'FontSize',12,...
            'FontWeight','bold','Position',[8 0.55]);
    end
    
    %load next condition
    if strcmp(subj,'grand') && (cn < condN)
        dataset = char(strcat (CommonPath,condgrands(cn+1),measure));
        load (dataset);
    elseif cn < condN
        dataset = char(strcat (CommonPath,subj,'/',subj,'_',condgrands(cn+1),measure));
        load (dataset);
    end
    
end

end