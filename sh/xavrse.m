function xavrse(subj,tMin,tMax,FrMin,FrMax,varargin)
%xavrse.m
%Created by Eugenio Parise
%CDC CEU 2013
%Based on xavr.m Written by Morten Moerup (ERPWAVELABv1.1)
%One line of code has been taken from Luca Filippin's EGIWaveletPlot.m
%Plots the time-frequency activity of a frequency band with Standard Error bars on top.
%Channels are plotted in the correct head position according to each channel
%topographic location.
%Datafile are located in the folder 'grand', already separated by
%condition, baseline corrected and chopped.
%Add 'evok' as last argument to plot evoked oscillations
%(of course if they have been previously computed).
%DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
%Interactive user interface needs inputgui.m from EEGLab.
%
%Usage:
%
%At present thgis function only works for grand average files, thus
%subj='grand'
%
%xavrse(subj,tMin,tMax,FrMin,FrMax);
%xavrse(subj,tMin,tMax,FrMin,FrMax,'evok');
%
%xavrse('grand',-200,1200,10,90); %to plot the grand average
%
%xavrse('grand',-200,1200,10,90,'evok'); %to plot the grand
%average of evoked oscillations
%
%xavrse(); to run via GUI

if ~exist('inputgui.m','file')    
    fprintf(2,'\nPlease, start EEGLAB first!!!\n');
    fprintf('\n');
    return    
end

try
    PROJECTPATH=evalin('base','PROJECTPATH');
    addpath(strcat(PROJECTPATH,'/pop_cfg'));
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

%Make pop_cfg folder to store config files for gui working functions
if exist('PROJECTPATH','var')
    CommonPath = strcat (PROJECTPATH,'/');
    alreadyexistdir=strcat(CommonPath,'pop_cfg');
    if ~exist(alreadyexistdir,'dir')
        mkdir (CommonPath,'pop_cfg');
    end
    addpath(strcat(PROJECTPATH,'/pop_cfg'));
    pop_cfgfile = strcat(CommonPath,'pop_cfg/xavrse_cfg.m');
else
    CommonPath = strcat ('../');
    alreadyexistdir=strcat(CommonPath,'pop_cfg');
    if ~exist(alreadyexistdir,'dir')
        mkdir (CommonPath,'pop_cfg');
    end
    addpath(strcat('../','pop_cfg'));
    pop_cfgfile = strcat('../pop_cfg/xavrse_cfg.m');
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
    
    [filenames, pathname, filterindex]=uigetfile({ '*-avWT.ss'; '*-evWT.ss' },'Select files to plot','MultiSelect','on');
    
    if ~pathname
        cd (PROJECTPATH);
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
    [enable_uV logFlag]=check_evok_log(PROJECTPATH);
    
    %SET defaultanswer0
    defaultanswer0={[],[],[],[],1};
    
    answersN=length(defaultanswer0);
    
    %Load previously called parameters if existing
    if exist(pop_cfgfile,'file')
        xavrse_cfg;
        try
            defaultanswer=defaultanswer;
            defaultanswer{1,answersN};
        catch
            fprintf('\n');
            fprintf(2, 'The xavrse_cfg.m file in the pop_cfg folder was created by a previous version\n');
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
        { 'style' 'edit'       'string' defaultanswer{1,4} }...
        { 'style' 'text'       'string' 'Plot all channels' } ...
        { 'style' 'checkbox'   'value' defaultanswer{1,5} } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } };
    
    geometry = { [0.25 0.15 0.15 0.15]  [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };
    
    answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set plotting parameters');
    
    if isempty(answer)
        return %quit on cancel button
    end
    
    tMin=str2num(answer{1,1});
    tMax=str2num(answer{1,2});
    FrMin=str2num(answer{1,3});
    FrMax=str2num(answer{1,4});
    allchan=answer{1,5};
    
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
    [condtoplot,ok] =listdlg('ListString', condgrands, 'SelectionMode', 'multiple', 'Name', 'Select Conditions',...
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

%Calculate latency subset to plot and reduce time vector to speed up
%plotting of individual channels
reduction=10;
lat=find(tim==tMin):reduction:find(tim==tMax);
lat2=find(tim==tMin):find(tim==tMax);

%Calculate frequency submset to plot
fr=find(Fa==FrMin):find(Fa==FrMax);
if length(fr)==1
    frchar=num2str(FrMin);
else
    frchar=strcat(num2str(FrMin),'_',num2str(FrMax));
end

%Save the user input parameters in the pop_cfg folder
if ~nargin
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'defaultanswer={ ''%s'' ''%s'' ''%s'' ''%s'' %i};',...
        num2str(tMin),num2str(tMax),num2str(FrMin),num2str(FrMax),allchan);
    fclose(fid);    
    rehash;    
end

%FIND channels to plot from gui
if ~nargin && ~allchan
    labels={};
    labels=cat(1,labels,chanlocs(1,:).labels);
    labels=labels';
    [ChannelsList, ok] = listdlg('PromptString','Select channels:','SelectionMode','multiple','ListString',labels);
    if ~ok
        return
    else
        channelsN=length(ChannelsList);
    end
else
    %SET parameters
    channelsN = size(WT,1);
    ChannelsList = 1:channelsN;
end

chanlocs = chanlocs(ChannelsList);

width=0.1;
height=0.1;

fprintf('\n');
fprintf('Plotting...\n');
fprintf('\n');

if strcmp(subj,'grand')    
    figurename=char(strcat(filename,frchar,'Hz',measure));    
else    
    figurename=char(strcat(filename,'Subj',subj,'_',frchar,'Hz',measure));    
end

for k=1:length(chanlocs)
    if ~isempty(chanlocs(k).radius)
        x(k)=sin(chanlocs(k).theta/360*2*pi)*chanlocs(k).radius;
        y(k)=cos(chanlocs(k).theta/360*2*pi)*chanlocs(k).radius;
    end
end
minx=min(x);
miny=min(y);
maxx=max(x);
maxy=max(y);
a=(maxx-minx)/50; % air to edge of plot
b=(maxy-miny)/50; % air to edge of plot
mx=maxx-minx+width;
my=maxy-miny+height;

% Create the main figure
h = figure('WindowButtonDownFcn',{@showChannel,WT,SS,x,y,chanlocs,ChannelsList,...
    mx,my,a,b,width,height,fr,lat2,figurename,timeRes,tMin,tMax,condN,subj,CommonPath,condgrands,measure,enable_uV});
set(h, 'Name', figurename);
set(h, 'NumberTitle', 'off');
set(h, 'ToolBar','none');

clf;
set(h, 'Color', [1 1 1]);
set(h, 'PaperUnits', 'centimeters');
set(h, 'PaperType', '<custom>');
set(h, 'PaperPosition', [0 0 12 12]);

% Create axes for the main figure
h = axes('position', [0 0 1 1]);
set(h, 'Visible', 'off');

H=zeros(1,length(ChannelsList));

for cn = 1:condN    
    %load conditions
    if strcmp(subj,'grand')
        dataset = char(strcat (CommonPath,condgrands(cn),measure));
        load (dataset,'-mat');
    else
        dataset = char(strcat (CommonPath,subj,'/',subj,'_',condgrands(cn),measure));
        load (dataset,'-mat');
    end    
    
    chanlocs = chanlocs(ChannelsList);   
    
    for ch = 1:channelsN        
        %Average frequencies
        WTch = squeeze(mean(WT(ChannelsList(ch),fr,lat),2));
        
        %Compute SE
        SEch = squeeze(mean(std(SS(ChannelsList(ch),fr,lat,:),0,4)./sqrt(size(SS,4)),2));
        
        %Plot channels
        if cn==1
            % Create axes for each channel
            h = axes('Position',[(x(ch)-minx+a)/(mx+2*a), (y(ch)-miny+a)/(my+2*b), width/mx, height/mx ]);
            H(ch)=gca;
            %yl=ylim;
            %text(0,(yl(1)-0.22),chanlocs(ch).labels,'FontSize',8,'FontWeight','bold');
            hold on;
            errorbar(H(ch),WTch,SEch,'b'); %blue line
        else
            errorbar(H(ch),WTch,SEch,'r'); %red line
            yl=ylim;
            title(H(ch),chanlocs(ch).labels,'FontSize',8,'FontWeight','bold','pos',[0,(yl(1)-0.22)]);
        end        
        axis off;        
    end    
end
hold off;

function showChannel(src,event,WT,SS,x,y,chanlocs,ChannelsList,mx,my,a,b,width,height,...
    fr,lat2,figurename,timeRes,tMin,tMax,condN,subj,CommonPath,condgrands,measure,enable_uV)
% Button down function for plot figure - displays single channel
minx=min(x);
miny=min(y);
x=(x-minx+a)/(mx+2*a)+width/(2*mx);
y=(y-miny+a)/(my+2*b)+height/(2*mx);
ppl=[x' y'];
cp=get(src,'CurrentPoint');
cp2=get(src,'Position');
pos=cp./cp2(3:4);
dist=sum((ppl-repmat(pos,[size(ppl,1) ,1])).^2,2);
[Y,k]=min(dist);
alreg=abs(pos-ppl(k,:));

if alreg(1)<=width/(2*mx) && alreg(2)<=height/(2*mx)    
    F=figure('NumberTitle', 'off', 'Name', figurename, 'ToolBar','none');    
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
    for cn = 1:condN        
        %load conditions
        if strcmp(subj,'grand')
            dataset = char(strcat (CommonPath,condgrands(cn),measure));
            load (dataset,'-mat');
        else
            dataset = char(strcat (CommonPath,subj,'/',subj,'_',condgrands(cn),measure));
            load (dataset,'-mat');
        end        
        chanlocs = chanlocs(ChannelsList);        
        %Average frequencies
        WT = squeeze(mean(WT(ChannelsList(k(1)),fr,lat2),2));        
        %Compute SE
        SE = squeeze(mean(std(SS(ChannelsList(k(1)),fr,lat2,:),0,4)./sqrt(size(SS,4)),2));        
        %Plot selected channel 
        if cn==1
            errorbar(WT,SE,'b'); %blue line
            hold on;
        else
            errorbar(WT,SE,'r'); %red line
            legend(char(condgrands(1)), char(condgrands(2)));
            set(gca, 'XTick', [1:grpc/timeRes:length(lat2)])
            set(gca, 'XTickLabel', [tMin:grpc:tMax]);
            set(gca, 'XMinorTick', 'on', 'xgrid', 'on', 'YMinorTick','on',...
                'ygrid', 'on', 'gridlinestyle', ':', 'YDIR', 'normal');
            axis tight;
            title(chanlocs(k(1)).labels,'FontSize',16,'FontWeight','bold');
            xlabel('ms','FontSize',12,'FontWeight','bold');
            if strcmp(enable_uV,'on')
                ylabel('\muV','FontSize',12,'FontWeight','bold');
            else
                ylabel('% change','FontSize',12,'FontWeight','bold');
            end
            hold off;
        end        
    end    
    hold on;    
    %1st click = display dashed grid
    %2nd click = display no grid
    %3rd click = display dotted grid
    try
        while F
            w = waitforbuttonpress;
            if (w == 0) && F
                set(gca, 'xgrid', 'on', 'ygrid', 'on','gridlinestyle', '--');
            end
            w = waitforbuttonpress;
            if (w == 0) && F
                set(gca, 'xgrid', 'on', 'ygrid', 'on','gridlinestyle', 'none');
            end
            w = waitforbuttonpress;
            if (w == 0) && F
                set(gca, 'xgrid', 'on', 'ygrid', 'on','gridlinestyle', ':');
            end
        end        
    catch        
        pause(1);
        return        
    end    
end