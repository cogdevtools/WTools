function egi2eegl(subjects)

%egi2eegl.m
%Created by Eugenio Parise
%CDC CEU 2010
%Function to import netstation files in EEGLAB. Netstation files must be
%previously exported in .mat format, each trial in individual array. Only
%good segments must be exported. After importing the original dataset in
%one EEGLAB file, the script will segmented such file into multiple EEGLAB datasets:
%one for each experimental condition.
%To set this script to process the whole final sample of subjects in a study,
%edit 'subj.m' in the 'cfg' folder and digit egi2eegl() (with no argument) at
%the console prompt.
%
%Usage:
%
%egi2eegl(subjects)
%egi2eegl('01');
%egi2eegl();

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
elseif ischar(subjects)
    subjects={subjects};
elseif ~iscell(subjects)
    fprintf(2,'\nPlease, enter a subject number in the right format, e.g. egi2eegl(''01'');, to process\n');
    fprintf(2,'an individual subject, or edit ''subj.m'' in the ''cfg'' folder and enter nothing,\n');
    fprintf(2,'(i.e. egi2eegl();), to process the whole sample.\n');
    fprintf('\n');
    return
end

subjN = size(subjects,2);

%Select conditions interactively via GUI
if exist('PROJECTPATH','var')
    allfields = load ('-mat',strcat(PROJECTPATH,exportvar{1},sla,filenames{1}));
    allfields = fieldnames(allfields);    
    for index = 1:length(allfields)        
        if ~isempty(allfields{index}(1:findstr(allfields{index}, 'Segment')+6))
            allfields{index} = allfields{index}(1:findstr(allfields{index}, 'Segment')-2);
        else
            allfields{index} = 'ThisIsNotACondition';
        end        
    end    
    allfields = unique(allfields);
    k=1;
    while k<=length(allfields)
        if strcmp(allfields{k},'ThisIsNotACondition')
            allfields(k)=[];
        end
        k=k+1;
    end    
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
    for i=1:length(allfields)
        fprintf(fid, ' ''%s'' ',char(allfields(i)));
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
        currectSubj = char (strcat (InPath,sla,filenames(i)));
    else
        currectSubj = char (strcat (InPath,subjects(i),'export.mat'));
    end    
    tempfile = char (strcat (InPath,'temp.mat'));    
    if exist('PROJECTPATH','var') && i==1 %do it only once
        wtoolspath = which('egi2eegl.m');
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
        labels=a(4:end);
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
        load(currectSubj, 'ECI_TCPIP_55513');
        
        samplingrate = 0;
        warning off all
        
        try
            load(currectSubj, 'samplingRate'); %Netstation 4.4.x
            samplingrate = samplingRate;
        end
        
        try
            load(currectSubj, 'EEGSamplingRate'); %Netstation 5.x.x
            samplingrate = EEGSamplingRate;
        end
        
        warning on all
        
        %Older version of Netstation
        if ~samplingrate
            
            %Load previously called parameters if existing
            pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'samplrate.m');
            if exist(pop_cfgfile,'file')
                samplrate;
                defaultanswer=defaultanswer;
            else
                defaultanswer={''};
            end
            
            parameters    = { ...
                { 'style' 'text' 'string' 'Sampling rate (Hz):' } ...
                { 'style' 'edit' 'string' defaultanswer{1,1} } ...
                { 'style' 'text' 'string' 'Enter the recording sampling rate' } };
            
            geometry = { [1 0.5] [1] };
            [answer userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters, 'title', 'Set trigger' );
            
            %Quit on cancel button
            if ~strcmp(strhalt,'retuninginputui')
                return;
            end
            
            samplingrate=str2num(answer{1,1});
            
            %Save the user input parameters in the pop_cfg folder
            fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
            fprintf(fid, 'defaultanswer={''%s''};',...
                num2str(samplingrate));
            fclose(fid);
            
        end
        
        %Load previously called parameters if existing
        pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'trigger.m');
        if exist(pop_cfgfile,'file')
            trigger;
            defaultanswer=defaultanswer;
        else
            defaultanswer={''};
        end
        
        parameters    = { ...
            { 'style' 'text' 'string' 'Trigger latency (ms):' } ...
            { 'style' 'edit' 'string' defaultanswer{1,1} } ...
            { 'style' 'text' 'string' 'Enter nothing to time lock to the onset of the stimulus,' } ...
            { 'style' 'text' 'string' 'enter a positive value to time lock to any point from' } ...
            { 'style' 'text' 'string' 'the begin of the segment.' } };
        
        geometry = { [1 0.5] [1] [1] [1] };
        [answer userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters, 'title', 'Set trigger' );
        
        %Quit on cancel button
        if ~strcmp(strhalt,'retuninginputui')
            return;
        end
        
        triglat=str2num(answer{1,1});
        
        %Save the user input parameters in the pop_cfg folder
        fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
        fprintf(fid, 'defaultanswer={''%s''};',...
            num2str(triglat));
        fclose(fid);
        
        %Read trigger latency from the exported .mat file (automatic time
        %lock to the stimulus onset).
        if isempty(triglat)
            triglat = cell2mat(ECI_TCPIP_55513(4,1))*(1000/samplingrate); %Transform trigger latency in ms
        end
        
        %SET defaultaswer0
        defaultanswer0={ '', '' };
        answersN=length(defaultanswer0);
        
        %Load previously called parameters if existing
        pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'minmaxtrialid.m');
        
        if exist(pop_cfgfile,'file')
            minmaxtrialid;
            try
                defaultanswer=defaultanswer;
                defaultanswer{1,answersN};
            catch
                fprintf('\n');
                fprintf(2, 'The minmaxtrialid.m file in the pop_cfg folder was created by a previous version\n');
                fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
                fprintf('\n');
                defaultanswer=defaultanswer0;
            end
        else
            defaultanswer=defaultanswer0;
        end
        
        parameters    = { ...
            { 'style' 'text' 'string' 'min Trial ID:' } ...
            { 'style' 'edit' 'string' defaultanswer{1,1} } ...
            { 'style' 'text' 'string' 'Max Trial ID:' } ...
            { 'style' 'edit' 'string' defaultanswer{1,2} } ...
            { 'style' 'text' 'string' 'Enter nothing to process all available trials.' } ...
            { 'style' 'text' 'string' 'Enter only min or Max to process trials above/below a trial ID.' } ...
            { 'style' 'text' 'string' 'Enter min/max positive integers to set the min/max trial' } ...
            { 'style' 'text' 'string' 'ID to process.' } };
        
        geometry = { [1 0.5] [1 0.5] [1] [1] [1] [1] };
        [answer userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters, 'title', 'Set min/Max Trial ID' );
        
        %Quit on cancel button
        if ~strcmp(strhalt,'retuninginputui')
            return;
        end
        
        mintrid=str2num(answer{1,1});
        maxtrid=str2num(answer{1,2});
        
        %Save the user input parameters in the pop_cfg folder
        fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
        fprintf(fid, 'defaultanswer={''%s'' ''%s''};',...
            num2str(mintrid),num2str(maxtrid));
        fclose(fid);
        
        %SET trials to process (all vs. user defined interval)
        if isempty(mintrid) && isempty(maxtrid)
            alltrials = 1; %Process all available trials
            mintrid = NaN;
            maxtrid = NaN;
        elseif isempty(maxtrid) % = min trial id is an integer
            alltrials = 0;
            maxtrid = 1000000; %The trial ID will pass the test mintrid<=ID<=maxtrid below
        elseif isempty(mintrid) % = max trial id is an integer
            alltrials = 0;
            mintrid = 0; %The trial ID will pass the test mintrid<=ID<=maxtrid below
        else
            alltrials = 0;
        end
        
    end
    
    try
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;        
    catch        
        fprintf(2,'\nPlease, start EEGLAB first!!!\n');
        fprintf('\n');
        return        
    end
    
    try
        eeg_getversion; %introduced in EEGLAB v9.0.0.0b
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Import the subject in EEGLAB version 9 or higher: no adjustements needed%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        EEG = pop_importegimat(currectSubj, samplingrate, triglat);
        
    catch
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Rename trials in continous way to avoid stop importing in EEGLAB old versions%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        c = []; %Inizialization necessary when using with All();
        
        tmpdata = load('-mat', currectSubj);
        allfields = fieldnames(tmpdata);
        allfields2 = fieldnames(tmpdata);
        t=1;
        
        index = 1;
        
        while length(allfields)
            
            if index > length(allfields)
                break
            end
            
            segmentFlag = 0;
            
            %Test wheter the field is a segment
            fieldname=allfields{index}(1:findstr(allfields{index}, 'Segment')+6);
            if ~isempty(fieldname)
                segmentFlag = 1; %Segment found = the string 'Segment' is in the field lable                
                segN=allfields{index}(length(fieldname)+1:end);                
                if (str2double(segN) >= mintrid && str2double(segN) <= maxtrid) || alltrials                    
                    allfields{index} = fieldname; %Cut original segment number                   
                else                    
                    segmentFlag = 0;
                    allfields(index)=[];
                    allfields2(index)=[];
                    index = index - 1;                    
                end                
            end            
            if index == 1 && segmentFlag
                allfields{index}=char(strcat(allfields{index},num2str(t))); %Replace segment number with progressive number t
                t=t+1;
            elseif segmentFlag                
                %If index >1 compare field label with previous one
                a=cellstr(allfields{index-1}(1:findstr(allfields{index-1}, 'Segment')-2));  %Previous label
                b=cellstr(allfields{index}(1:findstr(allfields{index}, 'Segment')-2));      %Present label                
                if segmentFlag && strcmp(a,b) %Field labels are equal = same condition
                    allfields{index}=char(strcat(allfields{index},num2str(t))); %Replace segment number with progressive number t
                    t=t+1;
                elseif segmentFlag %Field labels are not equal = the field is a segment of the next condition
                    t=1;
                    allfields{index}=char(strcat(allfields{index},num2str(t))); %Replace segment number with progressive number t
                    t=t+1;
                elseif ~segmentFlag %The field is not a segment
                    %allfields{index}=char(strcat(allfields{index})); %Replace field label with itself
                    t=1;
                end                
            end            
            index = index + 1;            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Adjust allfields and allfields2 to include only the selected conditions%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        allfields3 = [];
        allfields4 = [];
        
        for k = 1:length(conditions)            
            for index = 1:length(allfields)                
                if (~isempty(findstr(allfields{index},conditions{k})) ||...
                        strcmp(allfields{index},'samplingRate') ||...
                        strcmp(allfields{index},'ECI_TCPIP_55513'))
                    
                    allfields3{index} = allfields{index};                    
                end                
                if (~isempty(findstr(allfields2{index},conditions{k})) ||...
                        strcmp(allfields2{index},'samplingRate') ||...
                        strcmp(allfields2{index},'ECI_TCPIP_55513'))
                    
                    allfields4{index} = allfields2{index};                    
                end                
            end            
        end
        
        allfields3 = allfields3';
        allfields4 = allfields4';
        
        delcond = find(cellfun(@isempty,allfields3));
        allfields3(delcond) = [];
        allfields = allfields3;
        
        delcond = find(cellfun(@isempty,allfields4));
        allfields4(delcond) = [];
        allfields2 = allfields4;
        
        for index = 1:length(allfields)
            c.(char(allfields(index)))=tmpdata.(char(allfields2(index)));
        end
        
        save (tempfile, '-struct', 'c');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Import the subject in EEGLAB verion 8 or lower%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        EEG = pop_importegimat(tempfile, samplingrate, triglat);        
        delete (tempfile);        
    end
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', subjects, 'gui', 'off');
    
    if (ReRef==1 || ReRef==2) %If rereferencing is required restore Cz back
        
        ref=zeros(1,size(EEG.data,2),size(EEG.data,3)); %restore reference back (because cutted by pop_importegimat.m)
        EEG.data = cat(1,EEG.data,ref);
        EEG.nbchan = size(EEG.data,1);
        EEG = eeg_checkset(EEG);
        
        EEG=pop_chanedit(EEG,  'load',{ ChanLocFile, 'filetype', filetp},...
            'delete',1, 'delete',1, 'delete',1);
    end
    
    if ~isempty(CutChannels) %Cut some channels if required
        EEG = pop_select( EEG,'nochannel',CutChannels);
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
        EEG=pop_chanedit(EEG,  'load',{ ChanLocFile, 'filetype', filetp},...
            'delete',1, 'delete',1, 'delete',1,'delete',129);
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