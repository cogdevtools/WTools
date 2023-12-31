function eegl2eegl(subjects)

%eggl2eegl.m
%Created by Eugenio Parise
%Lancaster University 2017
%Function to import segmented EEGLAB datasets in EEGLAB/WTools. Files must be
%in .set format (including a separate .fdt), and already segmented/cleaned. Only
%good segments are assumed to be in the dataset. After importing the original dataset in
%EEGLAB/WTools, the script will segmented the file into multiple EEGLAB datasets:
%one for each experimental condition.
%Call the script from the main WTools GUI.
%NON GUI USAGE (not tested!):
%To set this script to process the whole final sample of subjects in a study,
%edit 'subj.m' in the 'cfg' folder and digit eegl2eegl() (with no argument) at
%the console prompt.
%
%Usage:
%
%eegl2eegl(subjects)
%
%eegl2eegl('01');
%eegl2eegl();

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
        [filenames, pathname, filterindex] = uigetfile({ '*.set' },'Select files to import','MultiSelect','on');
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
elseif ischar(subjects)
    subjects={subjects};
elseif ~iscell(subjects)
    fprintf(2,'\nPlease, enter a subject number in the right format, e.g. eegl(''01'');, to process\n');
    fprintf(2,'an individula subject, or edit ''subj.m'' in the ''cfg'' folder and enter nothing,\n');
    fprintf(2,'(i.e. eegl();), to process the whole sample.\n');
    fprintf('\n');
    return
end

subjN = size(subjects,2);

%Select conditions interactively via GUI
if exist('PROJECTPATH','var')
    
    firstSubj = char (filenames{1});
    firstFilePath = char (strcat (PROJECTPATH,exportvar{1},sla));
    
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset( 'filename', firstSubj, 'filepath', firstFilePath);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
    
    tmpevent = EEG.event;
    events=unique({ tmpevent.type });
    condlist =listdlg('Name', 'Select Conditions', 'SelectionMode', 'multiple', 'ListString', events);
    
    if isempty(condlist)
        return %quit on cancel button
    end
    
    condlist=events(condlist);
    
    %Save the conditions config file in the pop_cfg folder
    pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'cond.m');
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'conditions = { ');
    for i=1:length(condlist)
        fprintf(fid, ' ''%s'' ',char(condlist(i)));
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
    if exist('filenames','var')
        currectSubj = char (strcat (InPath,filenames(i)));
    else
        currectSubj = char (strcat (InPath,subjects(i),'export.mat'));
    end
    
    if exist('PROJECTPATH','var') && i==1 %do it only once
        wtoolspath = which('wtEGIToEEGLab.m');
        slashes = findstr(wtoolspath,sla);
        chanpath = strcat(wtoolspath(1:slashes(end-1)),'chans_splines');
        cd (chanpath);
        %Set channels config file (*.sfp file)
        [ChanLocFile, pathname, filterindex]=uigetfile({ '*.sfp' },'Select channels location file','MultiSelect','off');
        
        if ~pathname
            cd (PROJECTPATH);
            return %quit on cancel button
        end
        
        chanloc = { strcat(pathname,ChanLocFile) };
        filetyp = { 'autodetect' };
        
        %Create channels array from the chan config file (*.sfp file) used
        %to set channels to re-ref (eventually) and channels to cut
        [a b c d]=textread(chanloc{1},'%s %s %s %s','delimiter', '\t');
        labels=a(1:end);
        labels=labels';
        
        %Save the channels location file in the pop_cfg folder
        pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'chan.m');
        fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
        fprintf(fid, 'chanloc = { ''%s'' };\r',ChanLocFile);
        fprintf(fid, 'filetyp = { ''autodetect'' };\r');
        
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
            parameters    = { { 'style' 'text' 'string' 'Click Ok to rereference to average reference,' } ...
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
            %Save the the channels to cut info in the pop_cfg folder
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
            fclose(fid);            
        end
        chan;
        ChanLocFile = char (strcat (pathname,chanloc));
        filetp = char (filetyp);
    else        
        if i==1
            ChanLocFile = char (strcat (OutPath,'cfg/',chanloc));
            filetp = char (filetyp);
        end
    end
    
    SetFileName = char (strcat (filename,subjects(i),'.set'));
    SetFilePath = char (strcat (OutPath,subjects(i),'/'));
    
    if i == 1 %READ sampling rate, trigger latency and set max trial ID to process (only once, for the first subject)
        samplingrate = EEG.srate;
        %Save the user input parameters in the pop_cfg folder
        pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'samplrate.m');
        fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
        fprintf(fid, 'defaultanswer={''%s''};',...
            num2str(samplingrate));
        fclose(fid);
    end    
    try
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;        
    catch        
        fprintf(2,'\nPlease, start EEGLAB first!!!\n');
        fprintf('\n');
        return        
    end
    
    EEG = pop_loadset('filename',char (filenames{i}),'filepath',InPath);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    eeglab redraw;
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', subjects, 'gui', 'off');
    
    if ~isempty(CutChannels) %Cut some channels if required
        EEG = pop_select( EEG,'nochannel',chanlist);
        EEG.nbchan = size(EEG.data,1);
    end
    
    if  ReRef==1 %Re-reference to average reference        
        EEG = pop_reref( EEG, []);        
    elseif ReRef==2 %Re-reference to average of some channels (e.g. linked mastoids)        
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
        
    else %Do not rereference
        EEG=pop_chanedit(EEG,  'load',{ ChanLocFile, 'filetype', filetp});
    end
    
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