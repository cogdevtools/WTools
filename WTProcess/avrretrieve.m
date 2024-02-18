% avrretrieve.m
% Created by Eugenio Parise
% CDC CEU 2010 - 2013
% Function to estract time-frequency points from ERPWAVELABv1.1 compatible data files.
% Baseline correction is assumed to be already done.
% It is set to process the whole final sample of subjects of the study.
% Set indFr to 0 to extract a frequency band (e.g. the average between 5 and
% 10 Hz). Set it to 1 to extract individual frequencies (e.g. at 5, 6, 7, 8,
% 9 and 10 Hz separately).
% Add 'evok' as last argument to retrieve averages of evoked
% oscillations (of course, if they have been previously computed).
% DO NOT ENTER ARGUMENTS TO RUN THIS FUNCTION INTERACTIVELY THROUGH GUI.
% Interactive user interface needs inputgui.m from EEGLab.
% 
% Usage:
% 
% avrretrieve(ChannelsList,tMin,tMax,FrMin,indFr,FrMax);
% avrretrieve(ChannelsList,tMin,tMax,FrMin,FrMax,indFr,varargin);
% avrretrieve();
% 
% avrretrieve({'E1' 'E57' 'Cz'},600,800,34,41,0);
% avrretrieve({'E1' 'E57' 'Cz'},600,800,34,41,1,'evok');
% avrretrieve();

function datatab=avrretrieve(ChannelsList,tMin,tMax,FrMin,FrMax,indFr,varargin)
    % Uncomment the tic below and the toc at the very bottom to test performance
    % tic

    wtProject = WTProject();
    if ~wtProject.checkIsOpen()
        return
    end

    wtLog = WTLog();
    PROJECTPATH = wtProject.Config.getRootDir();

    % Make Config folder to store config files for gui working functions
    if exist('PROJECTPATH','var')
        CommonPath = strcat (PROJECTPATH,'/');
        alreadyexistdir=strcat(CommonPath,'Config');
        if ~exist(alreadyexistdir,'dir')
            mkdir (CommonPath,'Config');
        end
        addpath(strcat(PROJECTPATH,'/Config'));
        pop_cfgfile = strcat(CommonPath,'Config/avrretrieve_cfg.m');
    else
        CommonPath = strcat ('../');
        alreadyexistdir=strcat(CommonPath,'Config');
        if ~exist(alreadyexistdir,'dir')
            mkdir (CommonPath,'Config');
        end
        addpath(strcat('../','Config'));
        pop_cfgfile = strcat('../Config/avrretrieve_cfg.m');
    end

    % Call gui only if no arguments were entered
    if ~nargin
        
        if ~exist('PROJECTPATH','var')
            subj;
        else
            if exist('subjgrand.m','file') && exist('condgrand.m','file')
                
                % Ask the user whether new subjects have been added and processed to the
                % already existing project
                parameters = { ...
                    { 'style' 'text' 'string' 'Have you added any new subjects to the project?' } ...
                    { 'style' 'text' 'string' '(Ok = Yes)' } };
                
                geometry = { [1] [1] };
                [answer userdat strhalt] = WTUtils.eeglabInputMask('geometry',geometry,'uilist',parameters,'title','Subjects lists rebuild');
                
                if strcmp(strhalt,'retuninginputui')
                    if exist('subjects','var') % Necessary to make subjects working in the function workspace
                        subjN = size(subjects,2);
                    else
                        subjgrand; % In case the user quit the wtRebuildSubjects module after calling it
                    end
                else
                    subjgrand;
                end            
                condgrand;            
            else
                assignin('caller','subjects',subjects);
                fprintf(2,'\nFile-list of transformed subjects and/or conditions not found!!!\n');
                fprintf('\n');
                return
            end        
        end
        
        % CHECK Evok
        [logFlag, last_tfcmor] = wtCheckEvokLog();

        % SET defaultanswer0
        defaultanswer0={'1',[],[],[],[],0,last_tfcmor};
        
        answersN=length(defaultanswer0);
        
        % Load previously called parameters if existing
        if exist(pop_cfgfile,'file')
            avrretrieve_cfg;
            try
                defaultanswer=defaultanswer;
                defaultanswer{1,answersN};
                defaultanswer{1,answersN}=last_tfcmor;
            catch
                fprintf('\n');
                fprintf(2, 'The avrretrieve_cfg.m file in the Config folder was created by a previous version\n');
                fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
                fprintf('\n');
                defaultanswer=defaultanswer0;
            end
        else
            defaultanswer=defaultanswer0;
        end
        
        assignin('base','defaultanswer',defaultanswer);
        assignin('base','subjects',subjects);
        assignin('base','conditions',conditions);
        % load the first dataset to take information from the matrixs 'Fa' and 'tim'
        % (see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
        try
            firstSubj = strcat (CommonPath,subjects(1),'/',subjects(1),'_',conditions(1),'_bc-avWT.mat');
            load (char(firstSubj));
        catch
            firstSubj = strcat (CommonPath,subjects(1),'/',subjects(1),'_',conditions(1),'_bc-evWT.mat');
            load (char(firstSubj));
        end
        assignin('base','chanlocs',chanlocs);
        
        cb_subj = [ ...
            'if length(subjects)>1,' ...
            '[subjlist, ok] = listdlg(''PromptString'',''Select subjects to retrieve:'',''SelectionMode'',''multiple'',''ListString'',subjects);' ...
            'if ~ok,' ...
            'assignin(''caller'',''subjects'',subjects);' ...
            'return;' ...
            'end;' ...
            'subjects = subjects(subjlist);' ...
            'else;' ...
            'subjects = subjects(1);' ...
            'fprintf(2,''\nThere is only one subject!!!\n'');' ...
            'fprintf(''\n'');' ...
            'assignin(''caller'',''subjects'',subjects);' ...
            'end;' ];
        
        cb_cond = [ ...
            'if length(conditions)>1,' ...
            '[condlist, ok] = listdlg(''PromptString'',''Select conditions:'',''SelectionMode'',''multiple'',''ListString'',conditions);' ...
            'if ~ok,' ...
            'assignin(''caller'',''subjects'',subjects);' ...
            'return;' ...
            'end;' ...
            'conditions = conditions(condlist);' ...
            'else;' ...
            'conditions = conditions(1);' ...
            'fprintf(2,''\nThere is only one condition!!!\n'');' ...
            'fprintf(''\n'');' ...
            'assignin(''caller'',''subjects'',subjects);' ...
            'end;' ];
        
        cb_chan = [ ...
            'labels={};' ...
            'labels=cat(1,labels,chanlocs(1,:).labels);' ...
            'labels=labels'';' ...
            'chans=WTUtils.str2nums(defaultanswer{1,1});' ...
            '[ChannelsList, ok] = listdlg(''PromptString'',''Select channels:'',''SelectionMode'',''multiple'',''ListString'',labels,''InitialValue'',chans);' ...
            'if ~ok,' ...
            'assignin(''caller'',''subjects'',subjects);' ...
            'return;' ...
            'end;' ];
        
        parameters    = { ...
            { 'style' 'pushbutton'          'string' 'Subjects'    'callback'    cb_subj} ...
            { 'style' 'pushbutton'          'string' 'Conditions'  'callback'    cb_cond} ...
            { 'style' 'pushbutton'          'string' 'Channels'    'callback'    cb_chan} ...
            { 'style' 'text'                'string' '' } ...
            { 'style' 'text'                'string' 'Time (ms): From     ' } ...
            { 'style' 'edit'                'string' defaultanswer{1,2} } ...
            { 'style' 'text'                'string' 'To' } ...
            { 'style' 'edit'                'string' defaultanswer{1,3} } ...
            { 'style' 'text'                'string' 'Frequency (Hz): From' } ...
            { 'style' 'edit'                'string' defaultanswer{1,4} } ...
            { 'style' 'text'                'string' 'To' } ...
            { 'style' 'edit'                'string' defaultanswer{1,5} } ...
            { 'style' 'text'                'string' '' } ...
            { 'style' 'checkbox'            'string' 'Retrieve Individual frequencies'   'value' defaultanswer{1,6} } ...
            { 'style' 'text'                'string' '' } ...
            { 'style' 'text'                'string' '' } ...
            { 'style' 'checkbox'            'string' 'Retrieve Evoked Oscillations'      'value' defaultanswer{1,7} } ...
            { 'style' 'text'                'string' '' } ...
            { 'style' 'text'                'string' '' } };
        
        geometry = { [1 1 1] [2.25] [1 0.5 0.25 0.5]  [1 0.5 0.25 0.5] [2.25] [1.5 0.25 0.5] [1.5 0.25 0.5] };
        
        answer =  WTUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters,'title', 'Set average retrieving parameters');
        
        if isempty(answer)
            assignin('caller','subjects',subjects);
            evalin('base','clear chanlocs chans conditions condlist defaultanswer labels ok subjects subjlist');
            return % quit on cancel button
        end
        
        % import variables from the base workspace
        subjects = evalin('base','subjects');
        conditions = evalin('base','conditions');
        if evalin('base', 'exist(''ChannelsList'',''var'')')==1
            ChannelsList = evalin('base','ChannelsList');
        else
            assignin('caller','subjects',subjects);
            evalin('base','clear chanlocs chans conditions condlist defaultanswer labels ok subjects subjlist');
            wtLog.err('No channels selected!');
            return
        end
        if isempty(ChannelsList)
            assignin('caller','subjects',subjects);
            evalin('base','clear chanlocs chans conditions condlist defaultanswer labels ok subjects subjlist');
            wtLog.err('No channels selected!');
            return
        end    
        labels={};
        labels=cat(1,labels,chanlocs(1,:).labels);
        labels=labels';    
        temp=cell(1,answersN);
        temp{1,1}={ChannelsList};
        for index=2:answersN
            temp{1,index}=answer{1,index-1};
        end
        answer=temp;
        tMin=WTUtils.str2nums(answer{1,2});
        tMax=WTUtils.str2nums(answer{1,3});
        FrMin=WTUtils.str2nums(answer{1,4});
        FrMax=WTUtils.str2nums(answer{1,5});
        indFr=answer{1,6};
        if answer{1,7}
            varargin={'evok'};
        end    
        evalin('base','clear chanlocs chans conditions condlist defaultanswer labels ok subjects subjlist');    
    end

    % Check the input is correct
    if tMin > tMax
        assignin('caller','subjects',subjects);
        wtLog.err('Invalid time windows: [%i, %i]', tMin, tMax);
        return
    end
    if FrMin > FrMax
        assignin('caller','subjects',subjects);
        wtLog.err('Invalid frequency band: [%i, %i]', FrMin, FrMax);
        return
    end

    subjN = size(subjects,2);
    condN = size(conditions,2);

    if ~indFr
        OutFileName = strcat(char(filename),num2str(tMin),'_',num2str(tMax),...
            'ms_',num2str(FrMin),'_',num2str(FrMax),'Hz');
    else
        OutFileName = strcat(char(filename),num2str(tMin),'_',num2str(tMax),...
            'ms_',num2str(FrMin),'_',num2str(FrMax),'Hz','_IndFr');
    end

    if logFlag
        OutFileName = strcat('Log_',OutFileName);
    end

    if exist('PROJECTPATH','var')
        CommonPath = strcat (PROJECTPATH,'/');
        alreadyexistdir=strcat(CommonPath,'stat');
        if ~exist(alreadyexistdir,'dir')
            mkdir (CommonPath,'stat');
        end
        outPath = strcat(CommonPath,'stat/',OutFileName);
    else
        CommonPath = strcat ('../');
        alreadyexistdir=strcat(CommonPath,'stat');
        if ~exist(alreadyexistdir,'dir')
            mkdir (CommonPath,'stat');
        end
        outPath = strcat('../stat/',OutFileName);
    end

    if length(varargin)>=1
        varargin=varargin{1};
    end

    if isempty(varargin)    
        measure = strcat('_bc-avWT.mat');
        outPath = strcat(outPath,measure(1:findstr(measure,'.mat')-1),'.tab');    
    elseif ischar(varargin) && strcmp(varargin,'evok')    
        measure=strcat('_bc-evWT.mat');
        outPath = strcat(outPath,measure(1:findstr(measure,'.mat')-1),'.tab');    
    else    
        assignin('caller','subjects',subjects);
        wtLog.warn(['The measure % s is not present in the subjects folders! If you want to retrieve averages from\n'...
            'evoked oscillations, append ''evok'' to the list of the parameters of this funciton.\n'...
            'Or append no parameters ,if you want to retrieve averages from total-induced oscillations.'], strcat(varargin));
        return    
    end

    % load the first dataset to take information from the matrixs 'Fa' and 'tim'
    % (see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
    timeRes = tim(2) - tim(1); % find time resolution
    if length(Fa)>1
        frRes = Fa(2) - Fa(1); % find frequency resolution
    else
        frRes = 1;
    end

    % Adjust times and frequencies limits according with the data sampling
    temp=tMin;
    if tMin<min(tim)
        tMin=min(tim);
        wtLog.warn('Time min = %i ms was out of boundaries: value clipped to the lowest time (%i ms)', temp, min(tim));
    else
        tMin=tMin-mod(tMin,timeRes);
        while ~any(tim==tMin)
            tMin=tMin+1;
        end
    end
    temp=tMax;
    if tMax>max(tim)
        tMax=max(tim);
        wtLog.warn('Time max = %i ms was out of boundaries: value clipped to the highest time (%i ms)', temp, max(tim));
    else
        tMax=tMax-mod(tMax,timeRes);
        while ~any(tim==tMax)
            tMax=tMax+1;
        end
    end
    temp=FrMin;
    if FrMin<min(Fa)
        FrMin=min(Fa);
        wtLog.warn('Freq min = %i Hz was out of boundaries: value clipped to the lowest frequency (%i Hz)', temp, min(Fa));
    else
        FrMin=FrMin-mod(FrMin,frRes);
        while ~any(Fa==FrMin)
            FrMin=FrMin+1;
        end
    end
    temp=FrMax;
    if FrMax>max(Fa)
        FrMax=max(Fa);
        wtLog.warn('Freq max = %i Hz was out of boundaries: value clipped the highest frequency (%i Hz)', temp, max(Fa));
    else
        FrMax=FrMax-mod(FrMax,frRes);
        while ~any(Fa==FrMax)
            FrMax=FrMax+1;
        end
    end

    % Save the user input parameters in the Config folder
    if ~nargin
        fid = fopen(pop_cfgfile, 'wt'); % Overwrite preexisting file with the same name
        fprintf(fid, 'defaultanswer={ ''[%s]'' ''%s'' ''%s'' ''%s'' ''%s'' %i %i};',...
            num2str(ChannelsList),num2str(tMin),num2str(tMax),num2str(FrMin),num2str(FrMax),answer{1,6},answer{1,7});
        fclose(fid);    
        rehash;    
    end

    % FIND channels to process from gui
    if ~nargin
        channelsN=length(ChannelsList);
    else
        % SET parameters
        channelsN = size(ChannelsList,2);
    end

    % SET time and frequency limits
    lt1=find(tim==tMin);
    lt2=find(tim==tMax);
    f1=find(Fa==FrMin);
    f2=find(Fa==FrMax);

    % SET the final results matrix
    if ~indFr % for frequency band...
        datatab=cell(subjN+1,condN*channelsN+1); % 1 row and 1 colon extra to write subjects and conditions
        datatab{1,1}='subj';
    else % ... or for indivudual frequencies
        FrN=length(f1:f2);
        datatab=cell(subjN+1,condN*channelsN+1,FrN); % 1 row and 1 colon extra to write subjects and conditions
        datatab(1,1,:)={'subj'};
    end

    % WRITE subjects list in the matrix
    for s = 1:subjN
        if ~indFr
            datatab{s+1,1}=char(strcat('#',subjects(s)));
        else
            datatab(s+1,1,:)={char(strcat('#',subjects(s)))};
        end
    end

    % WRITE conditions and channels list in the matrix
    for cn = 1:condN    
        for ch = 1:channelsN        
            actualchan=ChannelsList(ch);        
            % Process channels found from gui
            if ~nargin            
                actualchan=labels(actualchan);            
            else % FIND channels to process from commandline            
                labels={};            
                % FIND channels to process
                labels=cat(1,labels,chanlocs(1,:).labels);
                labels=labels';
                chanindex=strfind(labels,char(actualchan));
                chan=find(~cellfun(@isempty,chanindex));
                chan=chan(1,1); % Avoid douplicate values (e.g. E100 to E109 when searching E10)            
                % QUIT and inform the user if the channel is not found
                if isempty(chan)
                    assignin('caller','subjects',subjects);
                    wtLog.err(['No channel %s selected!\n'...
                        'The channel you are trying to retrieve might had not been transformed.\n'...
                        'This function is case sensitive: enter the channels in capital letters.'], char(actualchan));
                    return
                end            
            end        
            if ~indFr
                datatab{1,ch+(cn*channelsN)-channelsN+1}=strcat(char(conditions(cn)),'_',char(actualchan));
            else
                datatab(1,ch+(cn*channelsN)-channelsN+1,:)={strcat(char(conditions(cn)),'_',char(actualchan))};
            end        
        end    
    end

    % RETRIEVE numbers and write them in the matrix
    wtLog.info('Retrieving numbers: please wait...');

    for s = 1:subjN    
        % Inform the user about the progress
        fprintf('Processing subject: %s\n', char(subjects(s)));    
        for cn = 1:condN       
            currectSubj = fullfile(strcat(CommonPath,subjects(s)), strcat(subjects(s),'_',conditions(cn),measure));        
            load (char(currectSubj));        
            if ~indFr            
                AbsFrMatrix = WT(ChannelsList,f1:f2,:);            
                % Data calculation by averaging frequencies and...
                % AvrFrMatrix=mean(AbsFrMatrix(:,:,lt1:lt2),2);
                % ... latencies. Store double precision numbers data in the matrix 'datatab'
                datatab(s+1,(2+(cn*channelsN)-channelsN):(cn*channelsN)+1)=num2cell((mean((mean(AbsFrMatrix(:,:,lt1:lt2),2)),3))');
                % OR if we want strings rather than double precision numbers:
                % datatab{s+1,cn+(ch*condN)-condN+1}=(mat2str(mean(AvrFrMatrix,3)))';            
            else            
                for fr=f1:f2
                    AbsFrMatrix = WT(ChannelsList,fr,:);
                    datatab(s+1,(2+(cn*channelsN)-channelsN):(cn*channelsN)+1,fr-f1+1)=num2cell(((mean(AbsFrMatrix(:,:,lt1:lt2),3)))');
                end            
            end        
        end    
    end

    % Save the file in the stat folder and...
    fid = fopen(outPath, 'wt'); % Overwrite preexisting file with the same name
    fclose(fid);                % in the same folder. Comment to append.
    fid = fopen(outPath, 'a+');

    if ~indFr    
        for i=1:size(datatab,1)
            for j=1:size(datatab,2)
                if j<size(datatab,2)
                    fprintf(fid, '%s\t', datatab{i,j}); %TAB separated cells
                else
                    fprintf(fid, '%s\r', datatab{i,j}); %RETURN at the end of each row
                end
            end
        end    
    else    
        for h=1:size(datatab,3)
            fprintf(fid, '%s\r', strcat(num2str(FrMin+h-1),' Hz')); % RETURN at the end of each row
            for i=1:size(datatab,1)
                for j=1:size(datatab,2)
                    if j<size(datatab,2)
                        fprintf(fid, '%s\t', datatab{i,j,h}); % TAB separated cells
                    else
                        fprintf(fid, '%s\r', datatab{i,j,h}); % RETURN at the end of each row
                    end
                end
            end
            if h<size(datatab,3)
                fprintf(fid, '\r'); % RETURN at the end of each frequency
            end
        end    
    end

    fclose(fid);

    % ... inform the user
    wtLog.info('File %s.tab successfully saved',strcat(OutFileName,measure(1:findstr(measure,'.mat')-1)));

    % Uncomment the toc below and the tic at the very top to test performance
    % toc

    % Alternative ways to save:
    % save (outPath, 'datatab', '-ASCII', '-DOUBLE', '-TABS', '-MAT');
    % uisave ('datatab',outPath);

    % Assign the variable subjects to the caller workspace
    assignin('caller','subjects',subjects);

end
