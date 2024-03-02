% wtPlotAverage.m
% Created by Eugenio Parise
% CDC CEU 2010 - 2011
% Based on topmontageplot.m Written by Morten Moerup (ERPWAVELABv1.1)
% One line of code has been taken from Luca Filippin's EGIWaveletPlot.m
% Plots the time-frequency activity of the 3-way array WT in the
% correct position according to each channels topographic location.
% Datafile are located in the folder 'grand', already separated by
% condition, baseline corrected and chopped.
% Add 'evok' as last argument to plot evoked oscillations
% (of course if they have been previously computed).
% DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
% Interactive user interface needs inputgui.m from EEGLab.
%
% Usage:
%
% contr=0, no contours will be plotted; set to 1 to plot them.
%
% wtPlotAverage(subj,tMin,tMax,FrMin,FrMax,scale);
% wtPlotAverage(subj,tMin,tMax,FrMin,FrMax,scale,'evok');
%
% wtPlotAverage('01',-200,1200,10,90,[-0.5 0.5],1); %to plot a single subject
%
% wtPlotAverage('grand',-200,1200,10,90,[-0.5 0.5],0); %to plot the grand average
%
% wtPlotAverage('grand',-200,1200,10,90,[-0.5 0.5],0,'evok'); %to plot the grand
% average of evoked oscillations
%
% wtPlotAverage(); to run via GUI

% Now isempty(subject) => grand average
%     isempty(conditionsToPlot) => all conditions
%     isempty(channelsToPlot) => all channels
function success = wtPlotAverage(subject, conditionsToPlot, channelsToPlot, evokedOscillations)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();

    interactive = wtProject.Interactive;

    if ~interactive 
        mustBeGreaterThanOrEqual(nargin, 4);
        WTValidations.mustBeAStringOrChar(subject);
        WTValidations.mustBeALimitedLinearCellArrayOfString(conditionsToPlot, 1, -1, 0);
        WTValidations.mustBeALinearCellArrayOfString(channelsToPlot);
        subject = char(subject);
        conditionsToPlot = unique(conditionsToPlot);
        channelsToPlot = unique(channelsToPlot);
        evokedOscillations = any(logical(evokedOscillations));
    end
    
    logFlag = wtCheckEvokLog();

    if interactive
        [fileNames, ~, measure, subject] = WTPlotsGUI.selectFilesToPlot();
        if isempty(fileNames)
            return
        end
        if ~setAvgPlotsParams(logFlag) 
            return
        end
    else
        measure = WTUtils.ifThenElse(evokedOscillations, ...
            WTIOProcessor.WaveletsAnalisys_evWT,  WTIOProcessor.WaveletsAnalisys_avWT);
    end

    prefixPrms = wtProject.Config.Prefix;
    conditionsGrandPrms = wtProject.Config.ConditionsGrand;
    conditions = [conditionsGrandPrms.ConditionsList(:)' conditionsGrandPrms.ConditionsDiff(:)'];
    grandAverage = strcmp(subject, '');

    if interactive
        conditionsToPlot = extractConditionsFromFileNames(fileNames);
    elseif isempty(conditionsToPlot)
        conditionsToPlot = conditions;
    end

    intersectConditionsToPlot = sort(intersect(conditionsToPlot, conditions));
    if numel(intersectConditionsToPlot) ~= numel(conditionsToPlot)
        wtLog.warn('The following conditions to plots are not part of the current analysis and have been pruned: %s', ...
            char(join(setdiff(conditionsToPlot, intersectConditionsToPlot), ',')));
    end

    conditionsToPlot = intersectConditionsToPlot;
    nConditionsToPlot = length(conditionsToPlot);

    if nConditionsToPlot == 0
        wtProject.notifyWrn([], 'Plotting aborted due to empty conditions selection')
        return
    end

    [diffConsistency, grandConsistency] = wtCheckDiffAndGrandAvg(conditionsToPlot, grandAverage);
    if ~diffConsistency || ~grandConsistency
        return
    end

    [success, data] = loadDataToPlot(subject, conditionsToPlot{1}, measure);
    if ~success || ~correctAvgPlotParams(data) 
        return
    end

    plotsPrms = wtProject.Config.AveragePlots;
    timeRes = WTUtils.ifThenElse(length(data.tim) > 1, data.tim(2) - data.tim(1), 1); 
    downsampleFactor = WTUtils.ifThenElse(timeRes == 1, 4, timeRes); % apply downsampling to speed up plotting
    timeIdxs = find(data.tim == plotsPrms.TimeMin) : downsampleFactor : find(data.tim == plotsPrms.TimeMax);
    freqIdxs = find(data.Fa == plotsPrms.FreqMin) : find(data.Fa == plotsPrms.FreqMax);
    allChannelsLabels = {data.chanlocs.labels}';

    if plotsPrms.AllChannels
        if ~interactive && numel(channelsToPlot) > 0
            wtLog.warn('All channels will be plotted: subset ignored: %s', char(join(channelsToPlot, ','))); 
        end
        channelsToPlot = allChannelsLabels;
        channelsToPlotIdxs = 1:numel(allChannelsLabels);
    elseif interactive 
        [channelsToPlot, channelsToPlotIdxs] = WTUtils.stringsSelectDlg('Select channels\nto cut:', allChannelsLabels, false, true);
    elseif isempty(channelsToPlot)
        channelsToPlot = allChannelsLabels;
    else
        intersectChannelsToPlot = intersect(channelsToPlot, allChannelsLabels);
        if numel(intersectChannelsToPlot) ~= numel(channelsToPlot)
            wtLog.warn('The following channels to plots are not part of the current analysis and have been pruned: %s', ...
               char(join(setdiff(channelsToPlot, intersectChannelsToPlot), ',')));
        end
        channelsToPlot = intersectChannelsToPlot;
        channelsToPlotIdxs = cellfun(@(l)find(strcmp(allChannelsLabels, l)), channelsToPlot);
    end
    
    if isempty(channelsToPlot)
        wtProject.notifyWrn([], "Plotting aborted due to empty channels selection");
        return
    end
    
    wtLog.info('Plotting %s...', WTUtils.ifThenElse(grandAverage, 'grand average', sprintf('subject %s', subject)));
    wtLog.pushStatus().setHeaderOn(false);
    wtWorspace = WTWorkspace();
    wtWorspace.pushBase()

    try
        nChannelsToPlot = numel(channelsToPlot);
        timeRange = [plotsPrms.TimeMin plotsPrms.TimeMax];
        freqRange = [plotsPrms.FreqMin plotsPrms.FreqMax];
        [DEFAULT_COLORMAP, cLabel, rotation, xcLabel] = wtSetFigure(logFlag);
        width = 0.1;
        height = 0.1;

        for cnd = 1:nConditionsToPlot
            wtLog.ctxOn().info('Condition %s', conditionsToPlot{cnd});
            [success, data] = loadDataToPlot(subject, conditionsToPlot{cnd}, measure);
            if ~success
                return
            end 

            figureName = WTUtils.ifThenElse(grandAverage, ...
                char(strcat(prefixPrms.FilesPrefix, conditionsToPlot{cnd}, measure)), ...
                char(strcat(prefixPrms.FilesPrefix, 'Subj', subject, '_', conditionsToPlot{cnd}, measure)));
            
            if logFlag % convert the data back to non-log scale straight in percent change        
                data.WT = 100 * (10.^data.WT - 1);        
            end

            channelsLocations = data.chanlocs(channelsToPlotIdxs);
            
            x = zeros(1, nChannelsToPlot);
            y = zeros(1, nChannelsToPlot);
            count = 1;

            for k = 1:nChannelsToPlot
                if ~isempty(channelsLocations(k).radius)
                    x(count) = sin(channelsLocations(k).theta / 360 * 2 * pi) * channelsLocations(k).radius;
                    y(count) = cos(channelsLocations(k).theta / 360 * 2 * pi) * channelsLocations(k).radius;
                    count = count + 1;
                end
            end

            if count <= nChannelsToPlot 
                x(count) = [];
                y(count) = [];
            end

            xMin = min(x);
            yMin = min(y);
            xMax = max(x);
            yMax = max(y);
            xAirToEdge = (xMax - xMin) / 50; % air to edge of plot
            yAirToEdge = (yMax - yMin) / 50; % air to edge of plot
            xM = xMax - xMin + width;
            yM = yMax - yMin + height;

            % Create the main figure
            hFigure = figure('WindowButtonDownFcn',{@showTFPlot, data.WT, x, y, channelsLocations, channelsToPlotIdxs, ...
                timeRange, freqRange, plotsPrms.Scale, xM, yM, xAirToEdge, yAirToEdge, width, height, freqIdxs, timeIdxs, figureName, ...
                downsampleFactor, plotsPrms.FreqMin, plotsPrms.FreqMax, plotsPrms.Contours, DEFAULT_COLORMAP, cLabel, rotation, xcLabel});    
                
            colormap(DEFAULT_COLORMAP);    
            set(hFigure, 'Name', figureName);
            set(hFigure, 'NumberTitle', 'off');
            set(hFigure, 'ToolBar','none');
            clf(hFigure);
            set(hFigure, 'Color', [1 1 1]);
            set(hFigure, 'PaperUnits', 'centimeters');
            set(hFigure, 'PaperType', '<custom>');
            set(hFigure, 'PaperPosition', [0 0 12 12]);
            
            % Create axes for the main figure
            hAxes = axes('position', [0 0 1 1]);
            set(hAxes, 'Visible', 'off');

            for chn = 1:nChannelsToPlot  
                wtLog.ctxOn().dbg('Channel %s', channelsToPlot{chn});
                % Create axes for each channel: original below...modified
                % hAxes = axes('Position',[(x(chn) - xMin + xAirToEdge)/(xM + 2 * xAirToEdge), ...
                %     (y(chn) - yMin + xAirToEdge) / (yMin + 2 * yAirToEdge), width / xM, height / xM ]);
                axes('Position',[(x(chn) - xMin + xAirToEdge)/(xM + 2 * xAirToEdge), ...
                    (y(chn) - yMin + yAirToEdge) / (yMin + 2 * yAirToEdge), width / xM, height / yM ]);
                hold('on');        
                imagesc(squeeze(data.WT(channelsToPlotIdxs(chn), freqIdxs, timeIdxs)));
                caxis(plotsPrms.Scale);
                axis('off');
                text(0, 0, channelsLocations(chn).labels, 'FontSize', 8, 'FontWeight', 'bold');
                hold('off');   
                wtLog.ctxOff();     
            end
            wtLog.ctxOff();
        end
    catch me
        wtWorspace.popToBase();
        wtLog.popStatus();
        me.rethrow();
    end

    wtLog.info('Plotting done.');
end

    % if ~exist('inputgui.m','file')    
    %     fprintf(2,'\nPlease, start EEGLAB first!!!\n');
    %     fprintf('\n');
    %     return    
    % end

    % try
    %     PROJECTPATH=evalin('base','PROJECTPATH');
    %     addpath(strcat(PROJECTPATH,'/Config'));
    %     filenm;
    %     if exist('condgrand.m','file')
    %         condgrand;
    %         condgrands=cat(2,conditions,condiff);
    %         cd (PROJECTPATH);
    %     else
    %         fprintf(2,'\nFile-list of transformed conditions not found!!!\n');
    %         fprintf('\n');
    %         return
    %     end
    % catch
    %     if exist('../cfg','dir')
    %         addpath('../cfg');
    %         filenm;
    %         condgrand;
    %         condgrands=cat(2,conditions,condiff);
    %     else
    %         fprintf(2,'\nProject not found!!!\n');
    %         fprintf('\n');
    %         return
    %     end
    % end

    % if isempty(varargin)    
    %     measure=strcat('_bc-avWT.mat');    
    % elseif strcmp(varargin,'evok')    
    %     measure=strcat('_bc-evWT.mat');    
    % elseif ~strcmp(varargin,'evok')    
    %     fprintf(2,'\nThe measure %s is not present in the %s folder!!!\n',varargin,subj);
    %     fprintf(2,'If you want to plot evoked oscillations, please type ''evok'' as last argument (after the contours argument).\n');
    %     fprintf(2,'Type nothing after the contours argument if you want to plot total-induced oscillations.\n');
    %     fprintf('\n');
    %     return    
    % end

    % Make Config folder to store config files for gui working functions
%     if exist('PROJECTPATH','var')
%         CommonPath = strcat (PROJECTPATH,'/');
%         alreadyexistdir=strcat(CommonPath,'Config');
%         if ~exist(alreadyexistdir,'dir')
%             mkdir (CommonPath,'Config');
%         end
%         addpath(strcat(PROJECTPATH,'/Config'));
%         pop_cfgfile = strcat(CommonPath,'Config/xavr_cfg.m');
%     else
%         CommonPath = strcat ('../');
%         alreadyexistdir=strcat(CommonPath,'Config');
%         if ~exist(alreadyexistdir,'dir')
%             mkdir (CommonPath,'Config');
%         end
%         addpath(strcat('../','Config'));
%         pop_cfgfile = strcat('../Config/xavr_cfg.m');
%     end

%     % Call gui only if no arguments were entered
%     if ~nargin
%         [filenames, pathname, filterindex]=uigetfile({ '*-avWT.mat'; '*-evWT.mat' },'Select files to plot','MultiSelect','on');    
%         if ~pathname
%             return %quit on cancel button
%         end    
%         % Find subject/grand folder from the path
%         if ispc
%             sla='\';
%         else
%             sla='/';
%         end
%         slashs=findstr(pathname,sla);
%         subj=pathname(slashs(end-1)+1:end-1);    
%         if filterindex == 2
%             varargin='evok';
%             measure=strcat('_bc-evWT.mat');
%         elseif filterindex == 3
%             fprintf(2,'\nYou cannot select -avWT.mat and -evWT.mat at the same time,\n');
%             fprintf(2,'neither any other different kind of file!!!\n');
%             fprintf(2,'Please, select either -avWT.mat or -evWT.mat files.\n');
%             fprintf('\n');
%             return
%         end
        
%         % CHECK if the data have been log-transformed
%         logFlag = wtCheckEvokLog();
%         enable_uV = WTUtils.ifThenElse(logFlag, 'off', 'on');

%         % SET defaultanswer0
%         % SET color limits and GUI
%         if logFlag
%             defaultanswer0={[],[],[],[],'[-10.0    10.0]',0,1};
%             Scale='Scale (�x% change)';
%         else
%             defaultanswer0={[],[],[],[],'[-0.5    0.5]',0,1};
%             Scale='Scale (mV)';
%         end
        
%         answersN=length(defaultanswer0);
        
%         % Load previously called parameters if existing
%         if exist(pop_cfgfile,'file')
%             xavr_cfg;
%             try
%                 defaultanswer=defaultanswer;
%                 defaultanswer{1,answersN};
                
%                 % Reset default scale if needed (e.g. the user changed from uV
%                 % to log or vice versa) and if the scale is symmetric
%                 scale=WTUtils.str2nums(defaultanswer{1,5});
%                 if (abs(scale(1)) == abs(scale(2))) && (logFlag && (scale(2) < 3)) || (~logFlag && (scale(2) >=3))
%                     defaultanswer{1,5}=defaultanswer0{1,5};
%                 end                
%             catch
%                 fprintf('\n');
%                 fprintf(2, 'The xavr_cfg.m file in the Config folder was created by a previous version\n');
%                 fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
%                 fprintf('\n');
%                 defaultanswer=defaultanswer0;
%             end
%         else
%             defaultanswer=defaultanswer0;
%         end
        
%         parameters    = { ...
%             { 'style' 'text'       'string' 'Time (ms): From     ' } ...
%             { 'style' 'edit'       'string' defaultanswer{1,1} } ...
%             { 'style' 'text'       'string' 'To' } ...
%             { 'style' 'edit'       'string' defaultanswer{1,2} }...
%             { 'style' 'text'       'string' 'Frequency (Hz): From' } ...
%             { 'style' 'edit'       'string' defaultanswer{1,3} }...
%             { 'style' 'text'       'string' 'To' } ...
%             { 'style' 'edit'       'string' defaultanswer{1,4} }...
%             { 'style' 'text'       'string' Scale } ...
%             { 'style' 'edit'       'string' defaultanswer{1,5} }...
%             { 'style' 'text'       'string' 'Draw contours' } ...
%             { 'style' 'checkbox'   'value' defaultanswer{1,6} } ...
%             { 'style' 'text'       'string' 'Plot all channels' } ...
%             { 'style' 'checkbox'   'value' defaultanswer{1,7} } ...
%             { 'style' 'text'       'string' '' } ...
%             { 'style' 'text'       'string' '' } };
        
%         geometry = { [0.25 0.15 0.15 0.15]  [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] };
        
%         % answer=inputdlg(parameters,'Set parameters',1.2,defaultanswer);
        
%         answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set plotting parameters');
        
%         if isempty(answer)
%             return %quit on cancel button
%         end
        
%         tMin=WTUtils.str2nums(answer{1,1});
%         tMax=WTUtils.str2nums(answer{1,2});
%         FrMin=WTUtils.str2nums(answer{1,3});
%         FrMax=WTUtils.str2nums(answer{1,4});
%         scale=WTUtils.str2nums(answer{1,5});
%         contr=answer{1,6};
%         allchan=answer{1,7};
        
%         % Find conditions to plot from the user selected files
%         if ~iscell(filenames)
%             filenames={filenames};
%         end
%         filenames=sort(filenames);
%         condtoplot=cell(length(filenames),length(condgrands));
%         condgrands=sort(condgrands);
        
       

%         % Exatracts conditions....
%         % 11_ADS_bc-evWT.mat => ADS
%         % ADS_bc-evWT.mat => ADS

%          % Clean filenames from measure and file extensions
%         a=cell(length(filenames));
%         for i=1:length(filenames)
%             a{i}=strfind(filenames,measure);
%             if ~strcmp(subj,'grand')
%                 b=strfind(filenames,'_');
%                 filenames{i}=filenames{i}(b{i}(1)+1:a{1}{i}-1);
%             else
%                 filenames{i}=filenames{i}(1:a{1}{i}-1);
%             end
%         end
        
%         % find {i,j} (file/conditions) that matches, set the remaining to empty
%         for i=1:length(filenames)
%             for j=1:length(condgrands)
%                 condtoplot{i,j}=strcmp(filenames{i},condgrands{j});
%                 if condtoplot{i,j} == 0
%                     condtoplot{i,j}=[];
%                 end
%             end
%         end
        
%         % extract a = rows, b = colums of matiching file/cond
%         [a,b]=find(~cellfun(@isempty,condtoplot));
%         condtoplot=unique(b');
%         condgrands=condgrands(condtoplot);
%         condN = size(condgrands,2);
        
%     end

%     % CHECK if difference and/or grand average files are up to date
%     [diffConsistency grandConsistency]=wtCheckDiffAndGrandAvg(filenames, strcmp(subj,'grand'));
%     if ~diffConsistency || ~grandConsistency
%         return
%     end

%     % Check the input is correct
%     if tMin > tMax
%         fprintf(2,'\nThe time window is  not valid!!!\n');
%         fprintf('\n');
%         return
%     end
%     if FrMin > FrMax
%         fprintf(2,'\nThe frequency band is not valid!!!\n');
%         fprintf('\n');
%         return
%     end
%     if scale(1) >= scale(2)
%         fprintf(2,'\nThe scale is not valid!!!\n');
%         fprintf('\n');
%         return
%     end

%     % Prompt the user to select the conditions to plot when using command line
%     % function call
%     if ~exist('condtoplot','var')
%         % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % Taken from Luca Filippin's EGIWaveletPlot.m%
%         % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         [condtoplot,ok] =listdlg('ListString', condgrands, 'SelectionMode', 'multiple', 'Name', 'Select Conditions',...
%             'ListSize', [200, 200]);
%         % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
%         if ~ok
%             return
%         else
%             condgrands=condgrands(condtoplot);
%             condN = size(condgrands,2);
%         end
        
%     end

%     if length(varargin) == 1
%         varargin=varargin{1};
%     end

%     if strcmp(subj,'grand')    
%         if exist('PROJECTPATH','var')
%             CommonPath = strcat (PROJECTPATH,'/grand/');
%         else
%             CommonPath = strcat ('../grand/');
%         end    
%         % load the first condition to take information from the matrixs 'Fa', 'tim' and 'chanlocs'
%         % (see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
%         firstCond = strcat (CommonPath,condgrands(1),measure);
%         load (char(firstCond));    
%     else    
%         if exist('PROJECTPATH','var')
%             CommonPath = strcat (PROJECTPATH,'/');
%         else
%             CommonPath = strcat ('../');
%         end    
%         % load the first condition to take information from the matrixs 'Fa', 'tim' and 'chanlocs'
%         % (see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
%         firstCond = strcat (CommonPath,subj,'/',subj,'_',condgrands(1),measure);
%         load (char(firstCond));    
%     end

%     timeRes = tim(2) - tim(1); %find time resolution
%     if length(Fa)>1
%         frRes = Fa(2) - Fa(1); %find frequency resolution
%     else
%         frRes = 1;
%     end

%     % Adjust times and frequencies limits according with the data sampling
%     temp=tMin;
%     if tMin<min(tim)
%         tMin=min(tim);
%         fprintf(2,'\n%i ms is out of boundaries!!!',temp);
%         fprintf(2,'\nValue adjusted to the lower time (%i ms)\n',min(tim));
%     else
%         tMin=tMin-mod(tMin,timeRes);
%         while ~any(tim == tMin)
%             tMin=tMin+1;
%         end
%     end
%     temp=tMax;
%     if tMax>max(tim)
%         tMax=max(tim);
%         fprintf(2,'\n%i ms is out of boundaries!!!',temp);
%         fprintf(2,'\nValue adjusted to the higher time (%i ms)\n',max(tim));
%     else
%         tMax=tMax-mod(tMax,timeRes);
%         while ~any(tim == tMax)
%             tMax=tMax+1;
%         end
%     end
%     temp=FrMin;
%     if FrMin<min(Fa)
%         FrMin=min(Fa);
%         fprintf(2,'\n%i Hz is out of boundaries!!!',temp);
%         fprintf(2,'\nValue adjusted to the lower frequency (%i Hz)\n',min(Fa));
%     else
%         FrMin=FrMin-mod(FrMin,frRes);
%         while ~any(Fa == FrMin)
%             FrMin=FrMin+1;
%         end
%     end
%     temp=FrMax;
%     if FrMax>max(Fa)
%         FrMax=max(Fa);
%         fprintf(2,'\n%i Hz is out of boundaries!!!',temp);
%         fprintf(2,'\nValue adjusted to the higher frequency (%i Hz)\n',max(Fa));
%     else
%         FrMax=FrMax-mod(FrMax,frRes);
%         while ~any(Fa == FrMax)
%             FrMax=FrMax+1;
%         end
%     end

%     % Calculate latency subset to plot and reduce time to speed up
%     % plotting of individual channels
%     if timeRes == 1
%         reduction=4;
%     elseif timeRes == 2
%         reduction=2;
%     else
%         reduction=timeRes;
%     end
%     lat=find(tim == tMin):reduction:find(tim == tMax);

%     % Calculate frequency submset to plot
%     fr=find(Fa == FrMin):find(Fa == FrMax);

%     % Save the user input parameters in the Config folder
%     if ~nargin
%         fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
%         fprintf(fid, 'defaultanswer={ ''%s'' ''%s'' ''%s'' ''%s'' ''[%s]'' %i %i};',...
%             num2str(tMin),num2str(tMax),num2str(FrMin),num2str(FrMax),num2str(scale,'%.1f'),contr,allchan);
%         fclose(fid);
%         rehash;
%     end

%     % FIND channels to plot from gui
%     if ~nargin && ~allchan
%         labels={};
%         labels=cat(1,labels,chanlocs(1,:).labels);
%         labels=labels';
%         [ChannelsList, ok] = listdlg('PromptString','Select channels:','SelectionMode','multiple','ListString',labels);
%         if ~ok
%             return
%         else
%             channelsN=length(ChannelsList);
%         end
%     else
%         % SET parameters
%         channelsN = size(WT,1);
%         ChannelsList = 1:channelsN;
%     end

%     width = 0.1;
%     height = 0.1;

%     % set figure parameters for current Matlab and EEGLAB version and color axis
%     % measure
%     [DEFAULT_COLORMAP, clabel, Rotation, xclabel] = wtSetFigure(strcmp(enable_uV,'off'));

%     fprintf('\n');
%     fprintf('Plotting...\n');
%     fprintf('\n');

%     for cn = 1:condN    
%         if logFlag % convert the data back to non-log scale straight in percent change        
%             WT = 100 * (10.^WT - 1);        
%         end
        
%         tim = [tMin tMax];
%         Fa = [FrMin FrMax];
        
%         % channelsN=size(WT,1);
%         chanlocs = chanlocs(ChannelsList);
        
%         if strcmp(subj,'grand')        
%             figureName = char(strcat(filename, condgrands(cn), measure));        
%         else        
%             figureName = char(strcat(filename, 'Subj', subj, '_', condgrands(cn), measure));        
%         end
        
%         for k = 1:length(chanlocs)
%             if ~isempty(chanlocs(k).radius)
%                 x(k) = sin(chanlocs(k).theta / 360 * 2 * pi) * chanlocs(k).radius;
%                 y(k) = cos(chanlocs(k).theta / 360 * 2 * pi) * chanlocs(k).radius;
%             end
%         end

%         minx = min(x);
%         miny = min(y);
%         maxx = max(x);
%         maxy = max(y);
%         a = (maxx-minx) / 50; % air to edge of plot
%         b = (maxy-miny) / 50; % air to edge of plot
%         mx = maxx - minx + width;
%         my = maxy - miny + height;
        
%         % Create the main figure
%         h = figure('WindowButtonDownFcn',{@showTFPlot, WT, x, y, chanlocs, ChannelsList,...
%             tim, Fa, scale, mx, my, a, b, width, height, fr, lat, figureName, reduction, FrMin,...
%             FrMax, contr, DEFAULT_COLORMAP, clabel, Rotation, xclabel});    
%         colormap(DEFAULT_COLORMAP);    
%         set(h, 'Name', figureName);
%         set(h, 'NumberTitle', 'off');
%         set(h, 'ToolBar','none');
%         clf;
%         set(h, 'Color', [1 1 1]);
%         set(h, 'PaperUnits', 'centimeters');
%         set(h, 'PaperType', '<custom>');
%         set(h, 'PaperPosition', [0 0 12 12]);
        
%         % Create axes for the main figure
%         h = axes('position', [0 0 1 1]);
%         set(h, 'Visible', 'off');
%         for ch = 1:channelsN        
%             % Create axes for each channel
%             h = axes('Position',[(x(ch) - minx + a)/(mx + 2 * a), (y(ch) - miny + a) / (my + 2 * b), width / mx, height / mx ]);
%             hold on;        
%             % Draw channels
%             imagesc(squeeze(WT(ChannelsList(ch),fr,lat)));
%             % set(gca);
%             caxis(scale);
%             axis off;
%             text(0, 0, chanlocs(ch).labels, 'FontSize', 8, 'FontWeight', 'bold');
%             hold off;        
%         end

%         % load next condition
%         if strcmp(subj, 'grand') && (cn < condN)
%             dataset = char(strcat(CommonPath, condgrands(cn+1), measure));
%             load(dataset);
%         elseif cn < condN
%             dataset = char(strcat(CommonPath, subj, '/', subj, '_', condgrands(cn+1), measure));
%             load(dataset);
%         end    
%     end
% end

function showTFPlot(src,event,WT,x,y,chanlocs,ChannelsList,tim,Fa,scale,mx,my,...
    a,b,width,height,fr,lat,figureName,reduction,FrMin,FrMax,contr,DEFAULT_COLORMAP,clabel,Rotation,xclabel)
    % Button down function for plot figure - displays single channel activity
    xMin = min(x);
    yMin = min(y);
    x = (x - xMin + a) / (mx + 2 * a) + width / (2*mx);
    y = (y - yMin + a) / (my + 2 * b) + height / (2*mx);
    ppl = [x' y'];
    cp = get(src, 'CurrentPoint');
    cp2 = get(src, 'Position');
    pos = cp ./ cp2(3:4);
    dist = sum((ppl - repmat(pos, [size(ppl,1), 1])) .^ 2,2);
    [Y,k] = min(dist);
    alreg = abs(pos - ppl(k,:));
    if alreg(1) <= width / (2*mx) && alreg(2) <= height / (2*mx)
        F = figure('NumberTitle', 'off', 'Name', figureName, 'ToolBar','none');
        % imagesc(tim,Fa,squeeze(WT(k(1),fr,lat)));
        colormap(DEFAULT_COLORMAP);
        figureExist = exist('F','var');
        set(F,'WindowButtonDownFcn', { @changeGrid, figureExist });
        imagesc(tim, Fa, interp2(squeeze(WT(ChannelsList(k(1)),fr,lat)), 4, 'spline'));
        hold on;
        if contr && reduction == 4
            contour(tim(1):2^2:tim(end), Fa(1):Fa(end), squeeze(WT(k(1),fr,lat)), 'k');
        elseif contr
            contour(tim(1):reduction^2:tim(end), Fa(1):Fa(end) ,squeeze(WT(k(1),fr,lat)), 'k');
        end
        caxis(scale);
        
        xconst = (tim(end) - tim(1)) / 200;
        xpeace = (tim(end) - tim(1)) / xconst;
        XTick = tim(1):xpeace:tim(end);
        
        if FrMax-FrMin > 1 && FrMax-FrMin <= 5
            YTick = FrMin:FrMax;
        elseif FrMax - FrMin > 5 && FrMax - FrMin <= 15
            YTick = FrMin:2:FrMax;
        elseif FrMax - FrMin > 15 && FrMax - FrMin <= 25
            YTick = FrMin:5:FrMax;
        elseif FrMax - FrMin > 25 && FrMax - FrMin <= 45
            YTick = FrMin:10:FrMax;
        elseif FrMax - FrMin > 45 && FrMax - FrMin <= 65
            YTick = FrMin:15:FrMax;
        else
            YTick = FrMin:20:FrMax;
        end
        
        set(gca, 'xgrid', 'on', 'ygrid', 'on', 'gridlinestyle', '-', 'YDIR', 'normal', 'XTick', XTick, 'YTick', YTick);
        axis tight;
        title(chanlocs(k(1)).labels, 'FontSize', 16, 'FontWeight', 'bold');
        xlabel('ms', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Hz', 'FontSize', 12, 'FontWeight', 'bold');
        peace = linspace(min(scale), max(scale),64);
        peace = peace(2) - peace(1);
        C = colorbar('peer', gca, 'YTick', sort([0 scale]));
        set(get(C, 'xlabel'), 'String', clabel, 'Rotation', Rotation, 'FontSize', 12, 'FontWeight', 'bold', 'Position', [xclabel 2*peace]);   
    end
end

function changeGrid(F, event, figureExist)
    persistent clickN

    try    
        while figureExist        
            n = get(gcbo, 'Number');
            h = findobj('type', 'figure');
            fn = length(h);        
            if isempty(clickN)
                clickN = zeros(1, fn);
                clickN(n) = 1;
            elseif n>length(clickN)
                temp = zeros(1,(n - length(clickN)));
                clickN = cat(2, clickN, temp);
                clickN(n) = clickN(n) + 1;
            else
                clickN(n) = clickN(n) + 1;
            end        
            if rem(clickN(n),3) == 1
                set(gca, 'xgrid', 'on', 'ygrid', 'on', 'gridlinestyle', ':');
            elseif rem(clickN(n),3) == 2
                set(gca, 'xgrid', 'on', 'ygrid', 'on', 'gridlinestyle', 'none');
            elseif rem(clickN(n),3) == 0
                set(gca, 'xgrid', 'on', 'ygrid', 'on', 'gridlinestyle', '-');
            end        
            waitforbuttonpress;        
        end    
    catch    
        pause(1);
        return    
    end
end


 %===========================

function conditions = extractConditionsFromFileNames(fileNames)
    conditions = cell(1, length(fileNames));
    for i = 1:length(fileNames) 
        [~, condition] = WTIOProcessor.splitBaselineCorrectedFileName(fileNames{i});
        conditions{i} = condition;
    end
end

function [success, data] = loadDataToPlot(subject, condition, measure) 
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;
    grandAverage = isempty(subject);

    if grandAverage
        [success, data] = ioProc.loadGrandAverage(condition, measure, false);
    else
        [success, data] = ioProc.loadBaselineCorrection(subject, condition, measure);
    end
    if ~success 
        wtProject.notifyErr([], 'Failed to load data for condition ''%s''', condition);
    end
end

% Adjust 'edge' to the closest value in the ORDERED vector 'values'.
function adjEdge = adjustEdge(edge, values)
    edgeL = values(find(values <= edge, 1, 'last'));
    edgeR = values(find(values >= edge, 1, 'first'));
    if isempty(edgeL)
        adjEdge = edgeR;
    elseif isempty(edgeR)
        adjEdge = edgeL;
    elseif edge - edgeL <= edgeR - edge
        adjEdge = edgeL;
    else 
        adjEdge = edgeR;
    end
end

function success = correctAvgPlotParams(data)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    
    plotParams = copy(wtProject.Config.AveragePlots);
    tMin = data.tim(1);
    tMax = data.tim(end);

    plotTimeMin = adjustEdge(plotParams.TimeMin, data.tim);
    if plotParams.TimeMin > tMax 
        wtLog.warn('Average plots param TimeMin auto-corrected to minimum sample time %d ms (was %d ms > maximum sample time)', plotTimeMin, plotParams.TimeMin);
    elseif plotTimeMin ~=  plotParams.TimeMin
        wtLog.warn('Average plots param TimeMin adjusted to closest sample time %d ms (was %d ms)', plotTimeMin, plotParams.TimeMin);
    end

    plotTimeMax = adjustEdge(plotParams.TimeMax, data.tim);
    if plotParams.TimeMax < tMin 
        wtLog.warn('Average plots param TimeMax auto-corrected to maximum sample time %d ms (was %d ms < minimum sample time)', plotTimeMax, plotParams.TimeMax);
    elseif plotTimeMin ~=  plotParams.TimeMin
        wtLog.warn('Average plots param TimeMax adjusted to closest sample time %d ms (was %d ms)', plotTimeMax, plotParams.TimeMax);
    end

    if plotTimeMin > plotTimeMax 
        wtProject.notifyErr([], 'Bad average plots range [TimeMin,TimeMax] = [%d,%d] after adjustments...', plotTimeMin, plotTimeMax);
        return
    end

    fMin = data.Fa(1);
    fMax = data.Fa(end);

    plotFreqMin = adjustEdge(plotParams.FreqMin, data.Fa);
    if plotParams.FreqMin > fMax 
        wtLog.warn('Average plots param FreqMin auto-corrected to minimum frequency %d Hz (was %d Hz > maximum frequency)', plotFreqMin, plotParams.FreqMin);
    elseif plotTimeMin ~=  plotParams.TimeMin
        wtLog.warn('Average plots param FreqMin adjusted to closest frequency %d Hz (was %d Hz)', plotFreqMin, plotParams.FreqMin);
    end

    plotFreqMax = adjustEdge(plotParams.FreqMax, data.Fa);
    if plotParams.FreqMax < fMin 
        wtLog.warn('Average plots param FreqMax auto-corrected to maximum frequency %d Hz (was %d Hz < minimum frequency)', plotFreqMax, plotParams.FreqMax);
    elseif plotTimeMin ~=  plotParams.TimeMin
        wtLog.warn('Average plots param FreqMax adjusted to closest frequency %d Hz (was %d Hz)', plotFreqMax, plotParams.FreqMax);
    end

    if plotFreqMin > plotFreqMax 
        wtProject.notifyErr([], 'Bad average plots range [FreqMin,FreqMax] = [%d,%d] after adjustments...', plotFreqMin, plotFreqMax);
        return
    end

    plotParams.TimeMin = plotTimeMin;
    plotParams.TimeMax = plotTimeMax;
    plotParams.FreqMin = plotFreqMin;
    plotParams.FreqMax = plotFreqMax;
    
    if ~plotParams.persist() 
        wtProject.notifyErr([], 'Failed to save average plots params');
        return
    end

    wtProject.Config.AveragePlots = plotParams;
    success = true;
end

 function success = setAvgPlotsParams(logFlag)
    success = false;
    logFlag = any(logical(logFlag));
    wtProject = WTProject();
    plotPrms = copy(wtProject.Config.AveragePlots);

    if ~WTPlotsGUI.defineAvgPlotsSettings(plotPrms, logFlag)
        return
    end
    
    if ~plotPrms.persist()
        wtProject.notifyErr([], 'Failed to save average plots params');
        return
    end

    wtProject.Config.AveragePlots = plotPrms;
    success = true;
end