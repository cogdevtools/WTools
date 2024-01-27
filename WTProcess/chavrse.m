function chavrse(subj, channels, tMin, tMax, FrMin, FrMax, varargin)
%chavrse.m
%Created by Eugenio Parise
%CDC CEU 2013
%One line of code has been taken from Luca Filippin's EGIWaveletPlot.m
%Plots the average frequency activity along time for the desired channels
%(individual or average of channels) with the Standard Error bars on top.
%It only works for the grand average file and max two conditions at once.
%Add 'evok' as last argument to plot evoked oscillations
%(of course, if they have been previously computed).
%DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
%Interactive user interface needs inputgui.m from EEGLab.
%
%Usage:
%
%At present thgis function only works for grand average files, thus
%subj='grand'
%
%chavrse(subj, channels, tMin, tMax, FrMin, FrMax, varargin);
%
%chavrse('grand',{'E2' 'E8' 'E9' 'E14'},-200,1200,10,60); %to plot average of channels from the grand average
%
%chavrse('grand',{'E2' 'E8' 'E9' 'E14'},-200,1200,10,60,'evok'); %to
%plot average of channels from the grand average of evoked oscillations
%
%chavrse(); to run via GUI

if ~exist('inputgui.m','file')    
    fprintf(2,'\nPlease, start EEGLAB first!!!\n');
    fprintf('\n');
    return    
end

try
    PROJECTPATH=evalin('base','PROJECTPATH');
    addpath(strcat(PROJECTPATH,'/Config'));
    filenm;
    if exist('condgrand.m','file')
        condgrand;
        condgrands=cat(2,conditions,condiff);
        cd (PROJECTPATH);
    else
        fprintf(2,'\nFile-list of transformed conditions not found!!!\n');
        fprintf('\n');
        return
    end
catch
    if exist('../cfg','dir')
        addpath('../cfg');
        filenm;
        condgrand;
        condgrands=cat(2,conditions,condiff);
    else
        fprintf(2,'\nProject not found!!!\n');
        fprintf('\n');
        return
    end
end

if isempty(varargin)    
    measure=strcat('_bc-avWT.ss');    
elseif strcmp(varargin,'evok')    
    measure=strcat('_bc-evWT.ss');    
elseif ~strcmp(varargin,'evok')    
    fprintf(2,'\nThe measure %s is not present in the %s folder!!!\n',varargin,subj);
    fprintf(2,'If you want to plot evoked oscillations, please type ''evok'' as last argument (after the contours argument).\n');
    fprintf(2,'Type nothing after the contours argument if you want to plot total-induced oscillations.\n');
    fprintf('\n');
    return    
end

%Make Config folder to store config files for gui working functions
if exist('PROJECTPATH','var')
    CommonPath = strcat (PROJECTPATH,'/');
    alreadyexistdir=strcat(CommonPath,'Config');
    if ~exist(alreadyexistdir,'dir')
        mkdir (CommonPath,'Config');
    end
    addpath(strcat(PROJECTPATH,'/Config'));
    pop_cfgfile = strcat(CommonPath,'Config/chavrse_cfg.m');
else
    CommonPath = strcat ('../');
    alreadyexistdir=strcat(CommonPath,'Config');
    if ~exist(alreadyexistdir,'dir')
        mkdir (CommonPath,'Config');
    end
    addpath(strcat('../','Config'));
    pop_cfgfile = strcat('../Config/chavrse_cfg.m');
end

%Call gui only if no arguments were entered
if ~nargin    
    if ispc
        sla='\';
    else
        sla='/';
    end
    grandpath = strcat(PROJECTPATH,sla,'grand');
    cd (grandpath);    
    [filenames, pathname, filterindex]=uigetfile({ '*-avWT.ss'; '*-evWT.ss' },...
        'Select files to plot','MultiSelect','on');    
    if ~pathname
        return %quit on cancel button
    else
        cd (PROJECTPATH);
    end
    
    %No more than 2 conditions can be plotted!!!
    if ischar(filenames) %The user selected onlyone file
        %skip the next control
    elseif length(filenames)>2
        fprintf(2,'No more than 2 conditions can be plotted!!!\n');
        fprintf('\n');
        return
    end
    slashs=findstr(pathname,sla);
    subj=pathname(slashs(end-1)+1:end-1);
    
    if filterindex==2
        varargin='evok';
        measure=strcat('_bc-evWT.ss');
    elseif filterindex==3
        fprintf(2,'\nYou cannot select -avWT.ss and -evWT.ss at the same time,\n');
        fprintf(2,'neither any other different kind of file!!!\n');
        fprintf(2,'Please, select either -avWT.ss or -evWT.ss files.\n');
        fprintf('\n');
        return
    end
    
    %CHECK if the data have been log-transformed
    logFlag = wtCheckEvokLog();
    enable_uV = WTUtils.ifThenElseSet(logFlag, 'off', 'on');

    %SET defaultaswer0
    defaultanswer0={[],[],[],[]};
    
    answersN=length(defaultanswer0);
    
    %Load previously called parameters if existing
    if exist(pop_cfgfile,'file')
        chavrse_cfg;
        try
            defaultanswer=defaultanswer;
            defaultanswer{1,answersN};
        catch
            fprintf('\n');
            fprintf(2, 'The chavrse_cfg.m file in the Config folder was created by a previous version\n');
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
        { 'style' 'edit'       'string' defaultanswer{1,2} }...
        { 'style' 'text'       'string' 'Frequency (Hz): From' } ...
        { 'style' 'edit'       'string' defaultanswer{1,3} }...
        { 'style' 'text'       'string' 'To' } ...
        { 'style' 'edit'       'string' defaultanswer{1,4} } };
    
    geometry = { [0.25 0.15 0.15 0.15]  [0.25 0.15 0.15 0.15] };
    
    answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set plotting parameters');
    
    if isempty(answer)
        return %quit on cancel button
    end
    
    tMin=str2num(answer{1,1});
    tMax=str2num(answer{1,2});
    FrMin=str2num(answer{1,3});
    FrMax=str2num(answer{1,4});
    
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
if tMin > tMax
    fprintf(2,'\nThe time window is  not valid!!!\n');
    fprintf('\n');
    return
end
if FrMin > FrMax
    fprintf(2,'\nThe frequency band is not valid!!!\n');
    fprintf('\n');
    return
end

%Prompt the user to select the conditions to plot when using command line
%function call
if ~exist('condtoplot','var')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Taken from Luca Filippin's EGIWaveletPlot.m%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [condtoplot,ok] =listdlg('ListString', condgrands, 'SelectionMode',...
        'multiple', 'Name', 'Select Conditions',...
        'ListSize', [200, 200]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    if ~ok
        return
    elseif ischar(filenames) %The user selected only one file
        %skip the next control
    elseif length(condtoplot)>2 %No more than 2 conditions can be plotted!!!
        fprintf(2,'No more than 2 conditions can be plotted!!!\n');
        fprintf('\n');
        return
    else
        condgrands=condgrands(condtoplot);
        condN = size(condgrands,2);
    end    
end

if length(varargin)==1
    varargin=varargin{1};
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
    load (char(firstCond),'-mat');    
else    
    if exist('PROJECTPATH','var')
        CommonPath = strcat (PROJECTPATH,'/');
    else
        CommonPath = strcat ('../');
    end    
    %load the first condition to take information from the matrixs 'Fa', 'tim' and 'chanlocs'
    %(see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
    firstCond = strcat (CommonPath,subj,'/',subj,'_',condgrands(1),measure);
    load (char(firstCond),'-mat');    
end

if ~exist('SS','var')
    fprintf(2,'\nSubjects matrix ''SS'' not found in the selected files!!!\n');
    fprintf('\n');
    return
end

avrchlabels={};
figlabels=[];

timeRes = tim(2) - tim(1); %find time resolution
if length(Fa)>1
    frRes = Fa(2) - Fa(1);     %find frequency resolution
else
    frRes = 1;
end

%Adjust times and frequencies limits according with the data sampling
temp=tMin;
if tMin<min(tim)
    tMin=min(tim);
    fprintf(2,'\n%i ms is out of boundaries!!!',temp);
    fprintf(2,'\nValue adjusted to the lower time (%i ms)\n',min(tim));
else
    tMin=tMin-mod(tMin,timeRes);
    while ~any(tim==tMin)
        tMin=tMin+1;
    end
end
temp=tMax;
if tMax>max(tim)
    tMax=max(tim);
    fprintf(2,'\n%i ms is out of boundaries!!!',temp);
    fprintf(2,'\nValue adjusted to the higher time (%i ms)\n',max(tim));
else
    tMax=tMax-mod(tMax,timeRes);
    while ~any(tim==tMax)
        tMax=tMax+1;
    end
end
temp=FrMin;
if FrMin<min(Fa)
    FrMin=min(Fa);
    fprintf(2,'\n%i Hz is out of boundaries!!!',temp);
    fprintf(2,'\nValue adjusted to the lower frequency (%i Hz)\n',min(Fa));
else
    FrMin=FrMin-mod(FrMin,frRes);
    while ~any(Fa==FrMin)
        FrMin=FrMin+1;
    end
end
temp=FrMax;
if FrMax>max(Fa)
    FrMax=max(Fa);
    fprintf(2,'\n%i Hz is out of boundaries!!!',temp);
    fprintf(2,'\nValue adjusted to the higher frequency (%i Hz)\n',max(Fa));
else
    FrMax=FrMax-mod(FrMax,frRes);
    while ~any(Fa==FrMax)
        FrMax=FrMax+1;
    end
end

%Calculate latency subset to plot
lat=find(tim==tMin):find(tim==tMax);

%Calculate frequency submset to plot
fr=find(Fa==FrMin):find(Fa==FrMax);
if length(fr)==1
    frchar=num2str(FrMin);
else
    frchar=strcat(num2str(FrMin),'_',num2str(FrMax));
end

%Save the user input parameters in the Config folder
if ~nargin
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'defaultanswer={''%s'' ''%s'' ''%s'' ''%s''};',...
        num2str(tMin),num2str(tMax),num2str(FrMin),num2str(FrMax));
    fclose(fid);    
    rehash;    
end

%FIND channels to process from gui
if ~nargin
    labels={};
    labels=cat(1,labels,chanlocs(1,:).labels);
    labels=labels';
    [chan, ok] = listdlg('PromptString','Select channels:','SelectionMode','multiple','ListString',labels);
    if ~ok
        return
    else
        chanN=length(chan);
    end
end

%Compute grid peace
if (tMax-tMin)/100<1
    grpc=10;
elseif (tMax-tMin)/100<2
    grpc=20;
elseif (tMax-tMin)/100<8
    grpc=100;
else
    grpc=200;
end

fprintf('\n');
fprintf('Plotting...\n');
fprintf('\n');

for cn=1:condN    
    avrChanWT=zeros(1,size(WT,2),size(WT,3));    
    if cn==1
        if strcmp(subj,'grand')            
            figurename=char(strcat(filename,frchar,'Hz',measure));            
        else            
            figurename=char(strcat(filename,'Subj',subj,'_',frchar,'Hz',measure));            
        end
    end
    
    %Add channels found from gui
    if ~nargin
        for i=1:chanN
            avrChanWT = avrChanWT + WT(chan(i),:,:);
            if cn==1
                avrchlabels=cat(1,avrchlabels,chanlocs(1,chan(i)).labels);
            end
        end        
    else
        %FIND channels to process from commandline
        chanN=length(channels);
        
        for ch = 1:chanN            
            actualchan = channels(ch);           
            labels={};            
            labels=cat(1,labels,chanlocs(1,:).labels);
            labels=labels';
            chanindex=strfind(labels,char(actualchan));
            chan=find(~cellfun(@isempty,chanindex));
            chan=chan(1,1); %Avoid douplicate values (e.g. E100 to E109 when searching E10)            
            if isempty(chan)
                fprintf(2,'\nChannel %s not found!!!\n', char(actualchan));
                fprintf(2,'The channel you are trying to average might had not been transformed.\n');
                fprintf(2,'This function is case sensitive: enter the channels in capital letters.\n');
                fprintf('\n');
                return
            end           
            %Add channels from commandline
            avrChanWT = avrChanWT + WT(chan,:,:);            
            if cn==1
                avrchlabels=cat(1,avrchlabels,char(actualchan));
            end            
        end        
    end
    
    %Average channels
    avrChanWT = avrChanWT./chanN;    
    %Average frequencies
    avrChanWT = avrChanWT(1,fr,lat);
    avrChanWT = mean(avrChanWT,2);
    avrChanWT = squeeze(avrChanWT(1,:,:)); %Squeeze fr but not channel
    avrChanWT = avrChanWT';
    
    %Compute SE
    SE = squeeze(mean(std(mean(SS(chan,fr,lat,:),1),0,4)./sqrt(size(SS,4)),2));
    
    if cn==1
        for i=1:length(avrchlabels)
            figlabels=strcat(figlabels, strcat(avrchlabels(i),', '));
        end
        figlabels=char(figlabels);
        if chanN==1
            figlabels=strcat('Channel: ', figlabels(1:end-1));
        else
            figlabels=strcat('Average of: ', figlabels(1:end-1));
        end
    end
    
    if cn==1
        F=figure('NumberTitle', 'off', 'Name', figurename, 'ToolBar','none');
        set(F,'WindowButtonDownFcn',{@changeGrid});
        errorbar(avrChanWT,SE,'b'); %blue line
        hold on;
    else
        errorbar(avrChanWT,SE,'r'); %red line
        legend(char(condgrands(cn-1)), char(condgrands(cn)));
    end
    
    if cn==condN
        set(gca, 'XTick', [1:grpc/timeRes:length(lat)])
        set(gca, 'XTickLabel', [tMin:grpc:tMax]);
        set(gca, 'XMinorTick', 'on', 'xgrid', 'on', 'YMinorTick','on',...
            'ygrid', 'on', 'gridlinestyle', ':', 'YDIR', 'normal');
        axis tight;
        title(figlabels,'FontSize',16,'FontWeight','bold');
        xlabel('ms','FontSize',12,'FontWeight','bold');
        if strcmp(enable_uV,'on')
            ylabel('\muV','FontSize',12,'FontWeight','bold');
        else
            ylabel('% change','FontSize',12,'FontWeight','bold');
        end
    end
    
    %load next condition
    if strcmp(subj,'grand') && (cn < condN)
        dataset = char(strcat (CommonPath,condgrands(cn+1),measure));
        load (dataset,'-mat');
    elseif cn < condN
        dataset = char(strcat (CommonPath,subj,'/',subj,'_',condgrands(cn+1),measure));
        load (dataset,'-mat');
    end    
end
end

%1st click = display dashed grid
%2nd click = display no grid
%3rd click = display dotted grid
function changeGrid(F,event)

set(gca, 'xgrid', 'on', 'ygrid', 'on','gridlinestyle', '--');

try
    while F
        w = waitforbuttonpress;
        if (w == 0) && F
            set(gca, 'xgrid', 'on', 'ygrid', 'on','gridlinestyle', 'none');
        end
        w = waitforbuttonpress;
        if (w == 0) && F
            set(gca, 'xgrid', 'on', 'ygrid', 'on','gridlinestyle', ':');
        end
        w = waitforbuttonpress;
        if (w == 0) && F
            set(gca, 'xgrid', 'on', 'ygrid', 'on','gridlinestyle', '--');
        end
    end    
catch    
    pause(1);
    return    
end
end