function smavr(subj,tMintMax,FrMinFrMax,scale,varargin)
% smavr.m
% Created by Eugenio Parise
% CDC CEU 2011
% A small portion of code has been taken from pop_topoplot.m EEGLab fuction.
% One line of code has been taken from Luca Filippin's EGIWaveletPlot.m
% It plots 2D scalpmaps/scalpmap series of wavelet transformed EEG channels (for each condition).
% It uses topoplot function from EEGLab, so EEGLab must be installed and
% included in Matlab path.
% It can plot a single timepoint, the average of a time window, a series of time points, as well as a
% single frequency, an averaged frequency band or a series of frequencies.
%
% WARNING: it is not possible to plot simultaneously a time and a frequency series
% (e.g. tMintMax=[0:50:350],FrMinFrMax=[5:15]), either the time or the frequency
% series must be a single number (e.g. tMintMax=300) or a 2 numbers vector
% (e.g. FrMinFrMax=[10 50]). tMintMax and FrMinFrMax cannot be
% simultaneously more than 3 numbers.
% DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
% Interactive user interface needs inputgui.m from EEGLab.
%
% Add 'evok' as last argument to compute scalp maps of evoked
% oscillations (of course, if they have been previously computed).
%
% Usage:
%
% smavr(subj,tMintMax,FrMinFrMax,scale);
%
% smavr('01',800,15,[-0.2 0.2]); %to plot a single subject,
% at 800 ms and at 15 Hz
%
% smavr('05',[240 680],5,[-0.2 0.2]); %to plot a single subject,
% average between 240 and 680 ms at 5 Hz
%
% smavr('grand',350,[10 60],[-0.2 0.2]); %to plot the grand average,
% average between at 350 ms in the 10 to 60 Hz averaged band
%
% smavr('grand',[100 400],[10 60],[-0.2 0.2]); %to plot the grand average,
% average between 100 and 400 ms in the 10 to 60 Hz averaged band
%
% smavr('grand',[100 400],[7:12],[-0.2 0.2]); %to plot the grand average,
% average between 100 and 400 ms at 7, 8, 9, 10, 11, 12 Hz
%
% smavr('grand',[100:100:500],[7 12],[-0.2 0.2]); %to plot the grand average,
% average at 100, 200, 300, 400, 500 ms in the 7 to 12 Hz averaged band
%
% smavr('grand',[100:100:500],[7 12],[-0.2 0.2],'evok'); %to plot the grand average,
% average at 100, 200, 300, 400, 500 ms in the 7 to 12 Hz averaged band, of
% evoked oscillations
%
% smavr(); to run via GUI

if ~exist('topoplot.m','file')
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

% Make Config folder to store config files for gui working functions
if exist('PROJECTPATH','var')
    CommonPath = strcat (PROJECTPATH,'/');
    alreadyexistdir=strcat(CommonPath,'Config');
    if ~exist(alreadyexistdir,'dir')
        mkdir (CommonPath,'Config');
    end
    addpath(strcat(PROJECTPATH,'/Config'));
    pop_cfgfile = strcat(CommonPath,'Config/smavr_cfg.m');
else
    CommonPath = strcat ('../');
    alreadyexistdir=strcat(CommonPath,'Config');
    if ~exist(alreadyexistdir,'dir')
        mkdir (CommonPath,'Config');
    end
    addpath(strcat('../','Config'));
    pop_cfgfile = strcat('../Config/smavr_cfg.m');
end

% Call gui only if no arguments were entered
if ~nargin
    [filenames, pathname, filterindex]=uigetfile({ '*-avWT.mat'; '*-evWT.mat' },...
        'Select files to plot','MultiSelect','on');
    if ~pathname
        return %quit on cancel button
    end
    % Find subject/grand folder from the path
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
    
    % CHECK if the data have been log-transformed
    logFlag = wtCheckEvokLog();
    enable_uV = fastif(logFlag, 'off', 'on');

    % SET defaultanswer0
    % SET color limits and GUI
    if logFlag
        defaultanswer0={'[    ]','[    ]','[-10.0    10.0]',1,1,0};
        Scale='Scale (�x% change)';
    else
        defaultanswer0={'[    ]','[    ]','[-0.5    0.5]',1,1,0};
        Scale='Scale (mV)';
    end
    
    answersN=length(defaultanswer0);
    
    % Load previously called parameters if existing
    if exist(pop_cfgfile,'file')
        smavr_cfg;
        try
            defaultanswer=defaultanswer;
            defaultanswer{1,answersN};
            % Reset default scale if needed (e.g. the user changed from uV
            % to log or vice versa) and if the scale is symmetric
            scale=WTUtils.str2nums(defaultanswer{1,3});
            if (abs(scale(1))==abs(scale(2))) && (logFlag && (scale(2)<3)) || (~logFlag && (scale(2)>=3))
                defaultanswer{1,3}=defaultanswer0{1,3};
            end
        catch
            fprintf('\n');
            fprintf(2, 'The smavr_cfg.m file in the Config folder was created by a previous version\n');
            fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
            fprintf('\n');
            defaultanswer=defaultanswer0;
        end
    else
        defaultanswer=defaultanswer0;
    end
    
    parameters    = { ...
        { 'style' 'text'       'string' 'Time (ms): From - To     ' } ...
        { 'style' 'edit'       'string'  defaultanswer{1,1} } ...
        { 'style' 'text'       'string' 'Frequency (Hz): From - To' } ...
        { 'style' 'edit'       'string'  defaultanswer{1,2} } ...
        { 'style' 'text'       'string'  Scale } ...
        { 'style' 'edit'       'string'  defaultanswer{1,3} } ...
        { 'style' 'text'       'string' 'Peripheral Electrodes' } ...
        { 'style' 'checkbox'   'value'   defaultanswer{1,4} } ...
        { 'style' 'text'       'string' 'Draw contours' } ...
        { 'style' 'checkbox'   'value'   defaultanswer{1,5} } ...
        { 'style' 'text'       'string' 'Electrode labels' } ...
        { 'style' 'checkbox'   'value'   defaultanswer{1,6} } };
    
    geometry = { [1 1] [1 1]  [1 1] [1 1] [1 1] [1 1] };
    
    answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set plotting parameters');
    
    if isempty(answer)
        return %quit on cancel button
    end
    
    tMintMax=WTUtils.str2nums(answer{1,1});
    FrMinFrMax=WTUtils.str2nums(answer{1,2});
    scale=WTUtils.str2nums(answer{1,3});
    periphelectr=answer{1,4};
    contours=answer{1,5};
    labels=answer{1,6};
    
    if length(tMintMax)>2 && length(FrMinFrMax)>2
        fprintf(2,'\nYou cannot plot scalp map series in time and frequency at the same time!!!\n');
        fprintf(2,'Please, choose to plot either a time or a frequency scalp map series.\n');
        fprintf('\n');
        return
    end
    
    % Find conditions to plot from the user selected files
    if ~iscell(filenames)
        filenames={filenames};
    end
    filenames=sort(filenames);
    condtoplot=cell(length(filenames),length(condgrands));
    condgrands=sort(condgrands);
    
    % Clean filenames from measure and file extensions
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

% CHECK if difference and/or grand average files are up to date
[diffConsistency grandConsistency]=wtCheckDiffAndGrandAvg(filenames, strcmp(subj,'grand'));
if ~diffConsistency || ~grandConsistency
    return
end

% Check the input is correct
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
    fprintf(2,'\nThe Scale is not valid!!!\n');
    fprintf('\n');
    return
end

% Prompt the user to select the conditions to plot when using command line
% function call
if ~exist('condtoplot','var')
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Taken from Luca Filippin's EGIWaveletPlot.m%
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [condtoplot,ok] =listdlg('ListString', condgrands, 'SelectionMode', 'multiple', 'Name', 'Select Conditions',...
        'ListSize', [200, 200]);
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    % load the first condition to take information from the matrixs 'Fa', 'tim' and 'chanlocs'
    % (see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
    firstCond = strcat (CommonPath,condgrands(1),measure);
    load (char(firstCond));
else
    if exist('PROJECTPATH','var')
        CommonPath = strcat (PROJECTPATH,'/');
    else
        CommonPath = strcat ('../');
    end
    % load the first condition to take information from the matrixs 'Fa', 'tim' and 'chanlocs'
    % (see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
    firstCond = strcat (CommonPath,subj,'/',subj,'_',condgrands(1),measure);
    load (char(firstCond));
end

timeRes = tim(2) - tim(1); %find time resolution
if length(Fa)>1
    frRes = Fa(2) - Fa(1);     %find frequency resolution
else
    frRes = 1;
end

% Adjust times and frequencies limits according to the data sampling
tMin=tMintMax(1);
if tMin<min(tim)
    tMin=min(tim);
    fprintf(2,'\n%i ms is out of boundaries!!!',tMintMax(1));
    fprintf(2,'\nValue adjusted to the lower time (%i ms)\n',min(tim));
elseif tMin>max(tim)
    tMin=max(tim);
    fprintf(2,'\n%i ms is out of boundaries!!!',tMintMax(1));
    fprintf(2,'\nValue adjusted to the higher time (%i ms)\n',max(tim));
else
    tMin=tMintMax(1)-mod(tMintMax(1),timeRes);
    while ~any(tim==tMin)
        tMin=tMin+1;
    end
end
if length(tMintMax)>=2
    tMax=tMintMax(end);
    if tMax>max(tim)
        tMax=max(tim);
        fprintf(2,'\n%i ms is out of boundaries!!!',tMintMax(end));
        fprintf(2,'\nValue adjusted to the higher time (%i ms)\n',max(tim));
    else
        tMax=tMintMax(end)-mod(tMintMax(end),timeRes);
        while ~any(tim==tMax)
            tMax=tMax+1;
        end
    end
end
FrMin=FrMinFrMax(1);
if FrMin<min(Fa)
    FrMin=min(Fa);
    fprintf(2,'\n%i Hz is out of boundaries!!!',FrMinFrMax(1));
    fprintf(2,'\nValue adjusted to the lower frequency (%i Hz)\n',min(Fa));
elseif FrMin>max(Fa)
    FrMin=max(Fa);
    fprintf(2,'\n%i Hz is out of boundaries!!!',FrMinFrMax(1));
    fprintf(2,'\nValue adjusted to the higher frequency (%i Hz)\n',max(Fa));
else
    FrMin=FrMinFrMax(1)-mod(FrMinFrMax(1),frRes);
    while ~any(Fa==FrMin)
        FrMin=FrMin+1;
    end
end
if length(FrMinFrMax)>=2
    FrMax=FrMinFrMax(end);
    if FrMax>max(Fa)
        FrMax=max(Fa);
        fprintf(2,'\n%i Hz is out of boundaries!!!',FrMinFrMax(end));
        fprintf(2,'\nValue adjusted to the higher frequency (%i Hz)\n',max(Fa));
    else
        FrMax=FrMinFrMax(end)-mod(FrMinFrMax(end),frRes);
        while ~any(Fa==FrMax)
            FrMax=FrMax+1;
        end
    end
end

% Calculate latency subset to plot
if length(tMintMax)>2
    newtimeres=(tMintMax(2)-tMintMax(1));
    if newtimeres<timeRes
        newtimeres=1;
    else
        newtimeres=floor((tMintMax(2)-tMintMax(1))/timeRes);
    end
    lat=find(tim==tMin):newtimeres:find(tim==tMax);
    latchar=strcat(num2str(tMin),'_',num2str(tMax));
    tTemp=[tMin tMax];
elseif length(tMintMax)==2
    lat=find(tim==tMin):find(tim==tMax);
    latchar=strcat(num2str(tMin),'_',num2str(tMax));
    tTemp=[tMin tMax];
else
    lat=find(tim==tMin);
    latchar=num2str(tMin);
    tTemp=[tMin];
end

% Calculate frequency subset to plot
if length(FrMinFrMax)>2
    newfrres=(FrMinFrMax(2)-FrMinFrMax(1));
    if newfrres<frRes
        newfrres=1;
    else
        newfrres=floor((FrMinFrMax(2)-FrMinFrMax(1))/frRes);
    end
    fr=find(Fa==FrMin):newfrres:find(Fa==FrMax);
    frchar=strcat(num2str(FrMin),'_',num2str(FrMax));
    FrTemp=[FrMin FrMax];
elseif length(FrMinFrMax)==2
    fr=find(Fa==FrMin):find(Fa==FrMax);
    frchar=strcat(num2str(FrMin),'_',num2str(FrMax));
    FrTemp=[FrMin FrMax];
else
    fr=find(Fa==FrMin);
    frchar=num2str(FrMin);
    FrTemp=[FrMin];
end

% Check the user is not trying to create time and frequency scalpmaps at the
% same time (if so exit), and set the number of scalpmap to create.
if length(tMintMax)>2 && length(FrMinFrMax)>2
    fprintf(2,'\nYou cannot plot scalp map series in time and frequency at the same time!!!\n');
    fprintf(2,'Please, choose to plot either a time or a frequency scalp map series.\n');
    fprintf('\n');
    return
elseif length(tMintMax)>2
    subplotN=length(lat);
elseif length(FrMinFrMax)>2
    subplotN=length(fr);
else
    subplotN=1;
end

% Save the user input parameters in the Config folder
if ~nargin
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    if length(tMintMax)<=2 && length(FrMinFrMax)<=2
        fprintf(fid, 'defaultanswer={''[%s]'' ''[%s]'' ''[%s]'' %i %i %i};',...
            num2str(tTemp),num2str(FrTemp),num2str(scale,'%.1f'),periphelectr,contours,labels);
    elseif length(tMintMax)>2
        t1=tTemp(1);
        t2=tTemp(2);
        peace=tMintMax(2)-tMintMax(1);
        if peace==1
            t1t2=strcat(num2str(t1),':',num2str(t2));
        else
            t1t2=strcat(num2str(t1),':',num2str(peace),':',num2str(t2));
        end
        fprintf(fid, 'defaultanswer={''[%s]'' ''[%s]'' ''[%s]'' %i %i %i};',...
            t1t2,num2str(FrTemp),num2str(scale,'%.1f'),periphelectr,contours,labels);
    elseif length(FrMinFrMax)>2
        fr1=FrTemp(1);
        fr2=FrTemp(2);
        peace=FrMinFrMax(2)-FrMinFrMax(1);
        if peace==1
            fr1fr2=strcat(num2str(fr1),':',num2str(fr2));
        else
            fr1fr2=strcat(num2str(fr1),':',num2str(peace),':',num2str(fr2));
        end
        fprintf(fid, 'defaultanswer={''[%s]'' ''[%s]'' ''[%s]'' %i %i %i};',...
            num2str(tMintMax),fr1fr2,num2str(scale,'%.1f'),periphelectr,contours,labels);
    end
    fclose(fid);
    rehash;
end

try %Periferal electrodes, contours and electrode labels controls only available from GUI.
    if ~periphelectr
        periphelectr=0.5;
    end
    if contours
        contours=6;
    end
    if ~labels
        labels='on';
    else
        labels='labels';
    end
catch %SET default papmeters from command line call
    periphelectr=1;
    contours=6;
    labels='on';
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
    
    % Average along times
    if length(tMintMax)<3
        WT=mean(WT(:,:,lat),3);
    end
    % Average along frequencies
    if length(FrMinFrMax)<3
        WT=mean(WT(:,fr,:),2);
    end
    
    % Create the main figure
    h = figure('NumberTitle', 'off', 'Name', figurename, 'ToolBar','none');
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%
    % Taken from pop_topoplot.m%
    % %%%%%%%%%%%%%%%%%%%%%%%%%%
    curfig = get(0, 'currentfigure');
    SIZEBOX = 200; %modified from its original value
    rowcols(2) = ceil(sqrt(subplotN));
    rowcols(1) = ceil(subplotN/rowcols(2));
    % %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Matrix of indices of scalpmaps
    subplotS=zeros(rowcols);
    subplotS(1)=1;
    for i=1:size(subplotS,1)
        for j=1:size(subplotS,2)
            if i==1 && j==1
                % do nothing
            elseif i>1 && j-1==0
                % increment the value of the first cell of a row based
                % on the last cell on the previous row
                subplotS(i,j)=subplotS(i-1,size(subplotS,2))+1;
            else
                % increment the next cell on the same row
                subplotS(i,j)=subplotS(i,j-1)+1;
            end
        end
    end
    % Flip the order of the rows, because Matlab starts counting from the
    % bottom of the figures.
    subplotS=flipdim(subplotS,1);
    
    for i=1:subplotN
        
        subplot(rowcols(1),rowcols(2),i);
        
        % %%%%%%%%%%%%%%%%%%%%%%%%%%
        % Taken from pop_topoplot.m%
        % %%%%%%%%%%%%%%%%%%%%%%%%%%
        if subplotN > 1
            if mod(i, rowcols(1)*rowcols(2)) == 1
                curfig = h;
                pos = get(curfig,'Position');
                posx = max(0, pos(1)+(pos(3)-SIZEBOX*rowcols(2))/2);
                posy = pos(2)+pos(4)-SIZEBOX*rowcols(1);
                set(h,'Position', [posx posy  SIZEBOX*rowcols(2)  SIZEBOX*rowcols(1)]);
            end
        end
        % %%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if size(WT,3)>1
            topoplot(WT(:,:,lat(i)), chanlocs, 'electrodes', labels, 'maplimits',...
                scale, 'intrad',periphelectr,'numcontour',contours);
            title(strcat(num2str(tim(lat(i))),'ms'),'FontSize',8,'FontWeight','bold');
            h2=figure(curfig);
            set(h2,'WindowButtonDownFcn',{@showSingleScalpmap,rowcols,subplotS,...
                subplotN,figurename,WT,fr,Fa,lat,tim,chanlocs,scale,periphelectr,contours,labels,enable_uV});
        elseif size(WT,2)>1
            topoplot(WT(:,fr(i),:), chanlocs, 'electrodes', labels, 'maplimits',...
                scale, 'intrad',periphelectr,'numcontour',contours);
            title(strcat(num2str(Fa(fr(i))),'Hz'),'FontSize',8,'FontWeight','bold');
            h2=figure(curfig);
            set(h2,'WindowButtonDownFcn',{@showSingleScalpmap,rowcols,subplotS,...
                subplotN,figurename,WT,fr,Fa,lat,tim,chanlocs,scale,periphelectr,contours,labels,enable_uV});
        else
            topoplot(WT, chanlocs, 'electrodes', labels, 'maplimits',...
                scale, 'intrad',periphelectr,'numcontour',contours);
            peace=linspace(min(scale),max(scale),64);
            peace=peace(2)-peace(1);
            C = colorbar('peer',gca,'YTick',sort([0 scale]));
            if strcmp(enable_uV,'on')
                set(get(C,'xlabel'),'String','\muV','FontSize',12,...
                    'FontWeight','bold','Position',[5 2*peace]);
            else
                set(get(C,'xlabel'),'String','% change','Rotation',90,...
                    'FontSize',12,'FontWeight','bold','Position',[5 2*peace]);
            end
        end
        
    end
    
    % load next condition
    if strcmp(subj,'grand') && (cn < condN)
        dataset = char(strcat (CommonPath,condgrands(cn+1),measure));
        load (dataset);
    elseif cn < condN
        dataset = char(strcat (CommonPath,subj,'/',subj,'_',condgrands(cn+1),measure));
        load (dataset);
    end
    
end

% PopUp the clicked scalp map
function showSingleScalpmap(h2,event,rowcols,subplotS,subplotN,figurename,...
    WT,fr,Fa,lat,tim,chanlocs,scale,periphelectr,contours,labels,enable_uV)

cp=get(h2,'CurrentPoint'); %get the clicked point on the figure
cp2=get(h2,'Position'); %get the figure size

% Ideally devide the figure in a grid, each cell containing a scalpmap.
% Find a vector of boundaries between the rows of the figure
xratio=cp2(4)/rowcols(1);
xbound=zeros(1,rowcols(1)+1);
xbound(1)=0;
for k=2:length(xbound)
    xbound(k)=xbound(k-1)+xratio;
end

% Find a vector of boundaries between the colons of the figure
yratio=cp2(3)/rowcols(2);
ybound=zeros(1,rowcols(2)+1);
ybound(1)=0;
for k=2:length(ybound)
    ybound(k)=ybound(k-1)+yratio;
end

% Find which row has been clicked
x=0;
i=1;
while xbound(i)<cp(2)
    x=x+1;
    i=i+1;
end

% Find which colon has been clicked
y=0;
i=1;
while ybound(i)<cp(1)
    y=y+1;
    i=i+1;
end

% Define which scalpmap has been clicked
i=subplotS(x,y);

if i>subplotN
    return %exit when an empty region of the figure has been clicked
end

% Draw the clicked scalpmap
figure('NumberTitle', 'off', 'Name', figurename, 'ToolBar','none');
[DEFAULT_COLORMAP, clabel, Rotation, xclabel] = wtSetFigure(enable_uV);
if size(WT,3)>1
    topoplot(WT(:,:,lat(i)), chanlocs, 'electrodes', labels, 'maplimits',...
        scale, 'intrad',periphelectr,'numcontour',contours);
elseif size(WT,2)>1
    topoplot(WT(:,fr(i),:), chanlocs, 'electrodes', labels, 'maplimits',...
        scale, 'intrad',periphelectr,'numcontour',contours);
end
peace=linspace(min(scale),max(scale),64);
peace=peace(2)-peace(1);
C = colorbar('peer',gca,'YTick',sort([0 scale]));
set(get(C,'xlabel'),'String',clabel,'Rotation',Rotation,'FontSize',12,...
    'FontWeight','bold','Position',[xclabel 2*peace]);
set(C, 'visible', 'on');
title(strcat(num2str(tim(lat(i))),'ms'),'FontSize',12,'FontWeight','bold');
