function brv2eegl(subjects,epochlimits,hpf,lpf)

%brv2eegl.m
%Created by Eugenio Parise
%CDC CEU 2013
%Function to import .mat BrainVision files in EEGLAB. After importing the
%script will segment the imported file into multiple EEGLAB datasets:
%one for each experimental condition.
%To set this script to process the whole final sample of subjects in a study,
%edit 'subj.m' in the 'cfg' folder and digit eep2eegl([],...) (empty value) at
%the console prompt.
%
%Usage:
%
%brv2eegl(subjects,epochlimits,hpf,lpf)
%brv2eegl('02',[-200 1000],0.3,65)
%brv2eegl([],[-200 1000],0.3,65)
%
%Enter no argument To run from GUI:
%brv2eegl()

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
    if ~nargin
        try
            PROJECTPATH=evalin('base','PROJECTPATH');
            cd (PROJECTPATH);
            addpath(strcat(PROJECTPATH,sla,'pop_cfg'));
            if exist('filenm.m','file') && exist('exported.m','file')
                filenm;
                exported;
            else
                fprintf(2,'\nPlease, create a new project or open an existing one.\n');
                fprintf('\n');
                return
            end
        catch
            fprintf(2,'\nPlease, create a new project or open an existing one.\n');
            fprintf('\n');
            return
        end
    end
catch
    addpath('../cfg');
    filenm;
    exported;
    chan;
    cond;
end

if ~nargin    
    if ~exist('PROJECTPATH','var')
        subj;
    else        
        %Select subjects interactively via GUI
        if exist(strcat(PROJECTPATH,sla,'pop_cfg',sla,'subj.m'),'file')
            
            parameters = { ...
                { 'style' 'text' 'string' 'The subject configuration file already exists!' } ...
                { 'style' 'text' 'string' 'Do you want to import the subjects again?' } ...
                { 'style' 'text' 'string' 'Ok = Yes      Cancel = No' } };
            
            geometry = { [1] [1] [1] };
            [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Re-import subjects?');
            
            if ~strcmp(strhalt,'retuninginputui')
                return;
            end            
        end
        
        subjects = { ...
            '01' '02' '03' '04' '05' '06' '07' '08' '09' '10' '11' '12' '13' '14' '15' ...
            '16' '17' '18' '19' '20' '21' '22' '23' '24' '25' '26' '27' '28' '29' '30' ...
            '31' '32' '33' '34' '35' '36' '37' '38' '39' '40' '41' '42' '43' '44' '45' ...
            '46' '47' '48' '49' '50' '51' '52' '53' '54' '55' '56' '57' '58' '59' '60' ...
            '61' '62' '63' '64' '65' '66' '67' '68' '69' '70' '71' '72' '73' '74' '75' ...
            '76' '77' '78' '79' '80' '81' '82' '83' '84' '85' '86' '87' '88' '89' '90' ...
            '91' '92' '93' '94' '95' '96' '97' '98' '99' '100' '101' '102' '103' '104' '105' ...
            '106' '107' '108' '109' '110' '111' '112' '113' '114' '115' '116' '117' '118' '119' '120' };
        
        cd ('Export');
        [filenames, pathname, filterindex]=uigetfile({ '*.mat' },'Select files to import','MultiSelect','on');
        cd ('..');
        
        if ~pathname
            return %quit on cancel button
        end
        
        if ischar(filenames)
            filenames = {filenames};
        end
        
        subtoimport = zeros(1,length(filenames));
        
        for i=1:length(filenames)
            subtoimport(i) = str2num(filenames{1,i}(1:findstr(filenames{1,i},' ')-1));
        end
        subjects = subjects(subtoimport);
        
        %Save the subjects config file in the pop_cfg folder
        pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'subj.m');
        fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
        fprintf(fid, 'subjects = { ');
        for i=1:length(subjects)
            fprintf(fid, ' ''%s'' ',char(subjects(i)));
        end
        fprintf(fid, ' }; ');
        fclose(fid);        
    end    
elseif isempty(subjects)
    subj;
elseif ischar(subjects)
    subjects={subjects};
elseif ~iscell(subjects)
    fprintf(2,'\nPlease, enter a subject number in the right format (e.g. brv2eegl(''01'');) to process\n');
    fprintf(2,'an individual subject, or edit ''subj.m'' in the ''cfg'' folder and enter nothing,\n');
    fprintf(2,'(i.e. brv2eegl();), to process the whole sample.\n');
    fprintf('\n');
    return
end

subjN = size(subjects,2);

if exist('PROJECTPATH','var')
    temp=char(exportvar);
    InPath = strcat (PROJECTPATH,temp,sla);
    OutPath = strcat (PROJECTPATH,sla);
else
    InPath = strcat (exportvar);
    OutPath = strcat ('../');
end

for i = 1:subjN    
    subjDir = char (strcat (subjects(i)));
    alreadyexistdir=strcat(OutPath,subjDir);
    if ~exist(alreadyexistdir,'dir')
        mkdir (OutPath, subjDir);
    end
    if ~nargin && exist('PROJECTPATH','var')
        currectSubj = char (strcat (InPath,sla,filenames(i)));
    else
        currectSubj = char (strcat (InPath,sla,filename,subjects(i),'.mat'));
    end    
    if exist('PROJECTPATH','var') && i==1 %do it only once
        wtoolspath = which('brv2eegl.m');
        slashes = findstr(wtoolspath,sla);
        chanpath = strcat(wtoolspath(1:slashes(end-1)),'chans_splines');
        cd (chanpath);
        %Set channels config file (*.sfp file)
        %[ChanLocFile, pathname, filterindex]=uigetfile({ '*.ced' },'Select channels location file','MultiSelect','off');       
        if ~pathname
            cd (PROJECTPATH);
            return %quit on cancel button
        end        
        load(currectSubj, 'Channels');
        labels={};
        labels=cat(1,labels,Channels(1,:).Name);
        labels=labels';
        
        %Save the channels location file in the pop_cfg folder
        pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'chan.m');
        fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
        
        %Save the spline file in the pop_cfg folder
        [SplineFile, pathname, filterindex]=uigetfile({ '*.spl' },'Select spline file','MultiSelect','off');
        
        if ~pathname
            cd (PROJECTPATH);
            return %quit on cancel button
        end
        
        fprintf(fid, 'splnfile = { ''%s'' };\r',SplineFile);
        cd (PROJECTPATH);
        
        parameters    = { { 'style' 'text' 'string' 'Do you want to re-reference? (Ok = yes)' } };
        
        geometry = { [1] };
        
        [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Re-referencing');
        if strcmp(strhalt,'retuninginputui')
            parameters    = { { 'style' 'text' 'string' 'Click Ok to re-reference to average reference,' } ...
                { 'style' 'text' 'string' 'click Cancel to select new reference electrodes' } };
            
            geometry = { [1] [1] };
            [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Select channels');
            
            if strcmp(strhalt,'retuninginputui')
                %Save the re-ref info (re-ref to avr) and no new reference channels in the pop_cfg folder
                fprintf(fid, 'ReRef = %i;\r',1);
                fprintf(fid, 'newrefchan = {};\r');
            else
                %Save the re-ref info (re-ref to new channels) in the pop_cfg folder
                fprintf(fid, 'ReRef = %i;\r',2);
                chanlist = listdlg('PromptString','Select channels:','SelectionMode','multiple','ListString',labels);
                
                if isempty(chanlist)
                    return %quit on cancel button
                end
                
                newrefchan = labels(chanlist);
                %Save the new reference channels in the pop_cfg folder
                fprintf(fid, 'newrefchan = { ');
                for k=1:length(newrefchan)
                    fprintf(fid, ' ''%s'' ',char(newrefchan(k)));
                end
                fprintf(fid, ' };\r');                
            end            
        else
            %Save the re-ref info (no re-ref needed) in the pop_cfg folder
            fprintf(fid, 'ReRef = %i;\r',0);
        end
        
        parameters    = { { 'style' 'text' 'string' 'Do you need to cut some channels? (Ok = yes)' } };
        
        geometry = { [1] };
        
        [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Cut channels');
        if strcmp(strhalt,'retuninginputui')
            chanlist = listdlg('PromptString','Select channels:','SelectionMode','multiple','ListString',labels);
            
            if isempty(chanlist)
                return %quit on cancel button
            end
            
            CutChannels = labels(chanlist);
            %Save the channels to cut info in the pop_cfg folder
            fprintf(fid, 'CutChannels = { ');
            for k=1:length(CutChannels)
                if k<length(CutChannels)
                    fprintf(fid, ' ''%s'', ',char(CutChannels(k)));
                else
                    fprintf(fid, ' ''%s'' ',char(CutChannels(k)));
                end
            end            
            fprintf(fid, ' };');
            fclose(fid);            
        else            
            fprintf(fid, 'CutChannels = {};');            
        end
        chan;
    end
    
    SetFileName = char (strcat (filename,subjects(i),'.set'));
    SetFilePath = char (strcat (OutPath,subjects(i),'/'));
    
    try
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;        
    catch        
        fprintf(2,'\nPlease, start EEGLAB first!!!\n');
        fprintf('\n');
        return        
    end
    
    EEG = pop_loadbva(currectSubj);
    
    %Select conditions interactively via GUI
    if exist('PROJECTPATH','var') && i==1 %do it only once
        
        allfields={};
        allfields=(sort(unique(cat(1,allfields,EEG.event(1,:).type))))';
        
        if length(allfields)>1            
            %Prompt the user to select the conditions to import from a list
            condlist = listdlg('PromptString','Select conditions:','SelectionMode','multiple','ListString',allfields);
            
            if isempty(condlist)
                return %quit on cancel button
            end            
            allfields = allfields(condlist);
        end
        
        %Save the conditions config file in the pop_cfg folder
        pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'cond.m');
        fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
        fprintf(fid, 'conditions = { ');
        for k=1:length(allfields)
            fprintf(fid, ' ''%s'' ',strtrim(char(allfields(k))));
        end
        fprintf(fid, ' };\r');
        fprintf(fid, 'condiff = {};');
        fclose(fid);
        
        cd ('pop_cfg');
        cond;
        cd (PROJECTPATH);
        condN = size(conditions,2);        
    else        
        condN = size(conditions,2);        
    end
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', subjects, 'gui', 'off');
    
    if ~isempty(CutChannels) %Cut some channels if required
        EEG = pop_select( EEG, 'nochannel',CutChannels);
        EEG.nbchan = size(EEG.data,1);
    end
    
    %SET defaultanswer0
    defaultanswer0={'[  ]',[],[]};
    answersN=length(defaultanswer0);
    
    if ~nargin && i==1
        %Load previously called parameters if existing
        pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'brv2eegl_cfg.m');
        if exist(pop_cfgfile,'file')
            brv2eegl_cfg;
            try
                defaultanswer=defaultanswer;
                defaultanswer{1,answersN};
            catch
                fprintf('\n');
                fprintf(2, 'The brv2eegl_cfg.m file in the pop_cfg folder was created by a previous version\n');
                fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
                fprintf('\n');
                defaultanswer=defaultanswer0;
            end
        else
            defaultanswer=defaultanswer0;
        end
        
        parameters    = { ...
            { 'style' 'text'       'string' 'Epochs limits' } ...
            { 'style' 'edit'       'string' defaultanswer{1,1} } ...
            { 'style' 'text'       'string' 'Highpass filter' } ...
            { 'style' 'edit'       'string' defaultanswer{1,2} }...
            { 'style' 'text'       'string' 'Lowpass filter' } ...
            { 'style' 'edit'       'string' defaultanswer{1,3} } };
        
        geometry = { [1 1] [1 1]  [1 1] };
        
        answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set parameters');
        
        if isempty(answer)
            return %quit on cancel button
        end
        
        epochlimits=str2num(answer{1,1});
        hpf=str2num(answer{1,2});
        lpf=str2num(answer{1,3});
        
        %Save the user input parameters in the pop_cfg folder
        fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
        fprintf(fid, 'defaultanswer={''[%s]'' ''%s'' ''%s''};',...
            num2str(epochlimits),num2str(hpf),num2str(lpf));
        fclose(fid);
    end
    
    %APPLY HighPass and LowPass filters separately. This is a workaround
    %because sometimes MATLAB does not find a good solution for BandPass
    %filter.
    if ~isempty(hpf)
        EEG = pop_eegfilt( EEG, hpf, [], [], [0]);
    end
    if ~isempty(lpf)
        EEG = pop_eegfilt( EEG, [], lpf, [], [0]);
    end
    
    %APPLY channels location
    %EEG=pop_chanedit(EEG,  'load',{ ChanLocFile, 'filetype', filetp});
    
    %PERFORM re-referencing
    if  ReRef==1
        
        EEG = pop_reref( EEG, [] );
        
    elseif ReRef==2
        
        newref=[];
        
        for ch=1:length(newrefchan)
            actualchan=newrefchan(ch);
            
            labels={};
            
            %FIND channels to process
            labels=cat(1,labels,EEG.chanlocs(1,:).labels);
            labels=labels';
            chanindex=strfind(labels,char(actualchan));
            chann=find(~cellfun(@isempty,chanindex));
            chann=chann(1,1); %Avoid douplicate values (e.g. E100 to E109 when searching E10)
            newref=cat(1,newref,chann);
            
        end
        
        EEG = pop_reref( EEG, newref ,'keepref','on');
        
    end

    if i==1
        epochlimits=epochlimits/1000;
    end
    
    %EPOCH the continuous EEG
    EEG = pop_epoch( EEG, {  }, epochlimits, 'epochinfo', 'yes');
    
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    EEG = pop_saveset( EEG,  'filename', SetFileName, 'filepath', SetFilePath);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    eeglab redraw;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Epoch the dataset: one dataset for each condition%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    currectSubj = char (strcat (filename,subjects(i),'.set'));
    SetFilePath = char (strcat (OutPath,subjects(i),'/'));
    
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset( 'filename', currectSubj, 'filepath', SetFilePath);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
    
    for j=1:condN        
        Cond = char (conditions(j));
        SetFileName = char (strcat (filename,subjects(i),'_',conditions(j)));
        SetNewFile = char (strcat(SetFilePath,SetFileName,'.set'));
        
        EEG = pop_selectevent( EEG,  'type',{Cond}, 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');       
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', SetFileName, 'savenew', SetNewFile, 'gui', 'off');
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, j+1, 'retrieve',1, 'study',0);
        EEG = eeg_checkset( EEG );        
    end    
    eeglab redraw;    
end

rehash;

fprintf('\nDone!!!\n');
fprintf('\n');

end