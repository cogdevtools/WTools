function chavr(subj, channels, tMin, tMax, FrMin, FrMax, scale, contr, varargin)
%chavr.m
%Created by Eugenio Parise
%CDC CEU 2011
%One line of code has been taken from Luca Filippin's EGIWaveletPlot.m
%Plots the average time-frequency activity of the desired channels for an
%individual subject or for the grand average.
%Add 'evok' as last argument to plot evoked oscillations
%(of course, if they have been previously computed).
%DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
%Interactive user interface needs inputgui.m from EEGLab.
%
%Usage:
%
%contr=0, no contours will be plotted; set to 1 to plot them.
%
%chavr(subj, channels, tMin, tMax, FrMin, FrMax, scale, contr);
%
%chavr('01',{'E2' 'E8' 'E9' 'E14'},-200,1200,10,60,[-0.75 0.75],0);
%to plot average of channels from a single subject
%
%chavr('grand',{'E2' 'E8' 'E9' 'E14'},-200,1200,10,60,[-0.75 0.75],1);
%to plot average of channels from the grand average
%
%chavr('grand',{'E2' 'E8' 'E9' 'E14'},-200,1200,10,60,[-0.75 0.75],1,'evok');
%to plot average of channels from the grand average of evoked oscillations
%
%chavr(); to run via GUI

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
    measure=strcat('_bc-avWT.mat');
elseif strcmp(varargin,'evok')
    measure=strcat('_bc-evWT.mat');
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
    pop_cfgfile = strcat(CommonPath,'pop_cfg/chavr_cfg.m');
else
    CommonPath = strcat ('../');
    alreadyexistdir=strcat(CommonPath,'pop_cfg');
    if ~exist(alreadyexistdir,'dir')
        mkdir (CommonPath,'pop_cfg');
    end
    addpath(strcat('../','pop_cfg'));
    pop_cfgfile = strcat('../pop_cfg/chavr_cfg.m');
end

%Call gui only if no arguments were entered
if ~nargin
    [filenames, pathname, filterindex]=uigetfile({ '*-avWT.mat'; '*-evWT.mat' },'Select files to plot','MultiSelect','on');
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
    [enable_uV logFlag]=check_evok_log(sla, PROJECTPATH);
    
    %SET defaultanswer0
    %SET color limits and GUI
    if logFlag
        defaultanswer0={[],[],[],[],'[-10.0    10.0]',1};
        Scale='Scale (±x% change)';
    else
        defaultanswer0={[],[],[],[],'[-0.5    0.5]',1};
        Scale='Scale (mV)';
    end
    
    answersN=length(defaultanswer0);
    
    %Load previously called parameters if existing
    if exist(pop_cfgfile,'file')
        chavr_cfg;
        try
            defaultanswer=defaultanswer;
            defaultanswer{1,answersN};
            
            %Reset default scale if needed (e.g. the user changed from uV
            %to log or vice versa) and if the scale is symmetric
            scale=str2num(defaultanswer{1,5});
            if (abs(scale(1))==abs(scale(2))) && (logFlag && (scale(2)<3)) || (~logFlag && (scale(2)>=3))
                defaultanswer{1,5}=defaultanswer0{1,5};
            end
        catch
            fprintf('\n');
            fprintf(2, 'The chavr_cfg.m file in the pop_cfg folder was created by a previous version\n');
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
        { 'style' 'text'       'string' Scale } ...
        { 'style' 'edit'       'string' defaultanswer{1,5} }...
        { 'style' 'text'       'string' 'Draw contours' } ...
        { 'style' 'checkbox'   'value' defaultanswer{1,6} } };
    
    geometry = { [0.25 0.15 0.15 0.15]  [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };
    
    answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set plotting parameters');
    
    if isempty(answer)
        return %quit on cancel button
    end
    
    tMin=str2num(answer{1,1});
    tMax=str2num(answer{1,2});
    FrMin=str2num(answer{1,3});
    FrMax=str2num(answer{1,4});
    scale=str2num(answer{1,5});
    contr=answer{1,6};
    
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
    fprintf(2,'\nThe time window is not valid!!!\n');
    fprintf('\n');
    return
end
if FrMin > FrMax
    fprintf(2,'\nThe frequency band is not valid!!!\n');
    fprintf('\n');
    return
end
if scale(1) >= scale(2)
    fprintf(2,'\nThe scale is not valid!!!\n');
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

avrchlabels={};
figlabels=[];

timeRes = tim(2) - tim(1); %find time resolution
if length(Fa)>1
    frRes = Fa(2) - Fa(1); %find frequency resolution
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

%Calculate latency subset to plot and reduce time to speed up
%plotting
if timeRes==1
    reduction=4;
elseif timeRes==2
    reduction=2;
else
    reduction=timeRes;
end
lat=find(tim==tMin):reduction:find(tim==tMax);

%Calculate frequency submset to plot
fr=find(Fa==FrMin):find(Fa==FrMax);

%Save the user input parameters in the pop_cfg folder
if ~nargin
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'defaultanswer={''%s'' ''%s'' ''%s'' ''%s'' ''[%s]'' %i};',...
        num2str(tMin),num2str(tMax),num2str(FrMin),num2str(FrMax),num2str(scale,'%.1f'),contr);
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

%set figure parameters for current Matlab and EEGLAB version and color axis measure
[DEFAULT_COLORMAP, clabel, Rotation, xclabel] = setfig(enable_uV);

fprintf('\n');
fprintf('Plotting...\n');
fprintf('\n');

for cn=1:condN
    if logFlag %Convert the data back to non-log scale straight in percent change
        WT=100*(10.^WT - 1);
    end
    avrChanWT=zeros(1,size(WT,2),size(WT,3));
    
    if strcmp(subj,'grand')
        figurename=char(strcat(filename,condgrands(cn),measure));
    else
        figurename=char(strcat(filename,'Subj',subj,'_',condgrands(cn),measure));
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
    avrChanWT = avrChanWT/chanN;
    
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
    
    tim=[tMin tMax];
    Fa=[FrMin FrMax];
    
    F=figure('NumberTitle', 'off', 'Name', figurename, 'ToolBar','none');
    
    colormap(DEFAULT_COLORMAP);
    
    FigureExist = exist('F','var');
    
    set(F,'WindowButtonDownFcn',{@changeGrid,FigureExist});
    %imagesc(tim,Fa,squeeze(WT(k(1),fr,lat)));
    imagesc(tim,Fa,interp2(squeeze(avrChanWT(1,fr,lat)),4,'spline'));
    hold on;
    if contr && reduction==4
        contour([tMin:2^2:tMax],[FrMin:FrMax],squeeze(avrChanWT(1,fr,lat)),'k');
    elseif contr
        contour([tMin:reduction^2:tMax],[FrMin:FrMax],squeeze(avrChanWT(1,fr,lat)),'k');
    end
    caxis(scale);
    
    xconst=(tim(end)-tim(1))/200;
    xpeace=(tim(end)-tim(1))/xconst;
    XTick=[tim(1):xpeace:tim(end)];
    
    if FrMax-FrMin>1 && FrMax-FrMin<=5
        YTick=[FrMin:FrMax];
    elseif FrMax-FrMin>5 && FrMax-FrMin<=15
        YTick=[FrMin:2:FrMax];
    elseif FrMax-FrMin>15 && FrMax-FrMin<=25
        YTick=[FrMin:5:FrMax];
    elseif FrMax-FrMin>25 && FrMax-FrMin<=45
        YTick=[FrMin:10:FrMax];
    elseif FrMax-FrMin>45 && FrMax-FrMin<=65
        YTick=[FrMin:15:FrMax];
    else
        YTick=[FrMin:20:FrMax];
    end
    
    set(gca, 'XMinorTick','on', 'xgrid', 'on', 'YMinorTick','on', 'ygrid', 'on',...
        'gridlinestyle', '-', 'YDIR', 'normal', 'XTick', XTick, 'YTick', YTick);
    axis tight;
    title(figlabels,'FontSize',16,'FontWeight','bold');
    xlabel('ms','FontSize',12,'FontWeight','bold');
    ylabel('Hz','FontSize',12,'FontWeight','bold');
    peace=linspace(min(scale),max(scale),64);
    peace=peace(2)-peace(1);
    C = colorbar('peer',gca,'YTick',sort([0 scale]));
    set(get(C,'xlabel'),'String',clabel,'Rotation',Rotation,'FontSize',12,...
        'FontWeight','bold','Position',[xclabel 2*peace]);
    
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

%1st click = display dotted grid
%2nd click = display no grid
%3rd click = display solid grid
function changeGrid(F,event,FigureExist)

persistent clickN

try
    
    while FigureExist        
        n = get(gcbo,'Number');        
        if isempty(clickN)
            h = findobj('type','figure');
            fn = length(h);
            clickN = zeros(1,fn);
            clickN(n) = 1;
        else
            clickN(n) = clickN(n) + 1;
        end        
        if rem(clickN(n),3)==1
            set(gca, 'xgrid', 'on', 'ygrid', 'on','gridlinestyle', ':');
        elseif rem(clickN(n),3)==2
            set(gca, 'xgrid', 'on', 'ygrid', 'on','gridlinestyle', 'none');
        elseif rem(clickN(n),3)==0
            set(gca, 'xgrid', 'on', 'ygrid', 'on','gridlinestyle', '-');
        end        
        waitforbuttonpress;        
    end
    
catch    
    pause(1);
    return    
end

end