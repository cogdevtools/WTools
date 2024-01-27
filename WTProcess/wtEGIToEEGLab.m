% wtEGIToEEGLab.m
% Created by Eugenio Parise
% CDC CEU 2010
% Function to import netstation files in EEGLAB. Netstation files must be
% previously exported in .mat format, each trial in individual array. Only
% good segments must be exported. After importing the original dataset in
% one EEGLAB file, the script will segmented such file into multiple EEGLAB datasets:
% one for each experimental condition.
% To set this script to process the whole final sample of subjects in a study,
% edit 'subj.m' in the 'cfg' folder and digit wtEGIToEEGLab() (with no argument) at
% the console prompt.
%
% Usage:
%   wtEGIToEEGLab(subjects)
%   wtEGIToEEGLab('01');
%   wtEGIToEEGLab();

function wtEGIToEEGLab()
    wtProject = WTProject();
    wtLog = WTLog();
    wtLog.pushStatus().ctxOn('EGIToEEGLab');

    if ~wtProject.checkIsOpen()
        wtLog.popStatus();
        return
    end

    interactive = wtProject.Interactive;

    if interactive  
        [success, sbjFileNames] = selectUpdateSubjects();
        if ~success
            wtLog.popStatus();
            return
        end  
        if ~selectUpdateConditions(sbjFileNames{1}) || ~selectUpdateChannels()
            wtLog.popStatus();
            return
        end
        getSubjFileName = @(ignoreA, ignoreB, sbj)sbjFileNames{sbj};
    else
        getSubjFileName = @(ioProc, subjectsList, sbj)getImportFileForSubject(ioProc, subjectsList{sbj}); 
    end

    ioProc = wtProject.Config.IOProc;
    subjectsPrms = wtProject.Config.Subjects;
    subjects = subjectsPrms.SubjectsList;
    nSubjects = length(subjects);
    conditionsPrms = wtProject.Config.Conditions;
    conditions = conditionsPrms.ConditionsList;
    nConditions = length(conditions);
    channelsPrms = wtProject.Config.Channels;
    outFilesPrefix = wtProject.Config.Prefix.FilesPrefix;

    if nSubjects == 0 
        wtLog.warn('No subjects to process');
        wtLog.popStatus();
        return 
    end

    subjFileName = getSubjFileName(ioProc, subjects, 1); 
    if ~setSamplingRate(subjFileName) || ...
        ~setTriggerLatency() || ... 
        ~setMinMaxTrialId()
         return
     end

     [success, egi2eeglPrms] = autoSetTriggerLatency(subjFileName);
     if ~success 
         return
     end

    samplingPrms = wtProject.Config.Sampling;

    for sbj = 1:nSubjects 
        subject = subjects{sbj};
        subjFileName = getSubjFileName(ioProc, subjects, sbj); 
        wtLog.info('Processing import file %s', subjFileName);

        [success, ALLEEG, EEG, ~] =  WTUtils.eeglabRun(WTLog.LevelDbg, true);
        if ~success 
            wtProject.notifyErr([], 'Failed to run eeglab');  
            wtLog.popStatus();      
            return
        end

        try
            eeg_getversion; % Introduced in EEGLAB v9.0.0.0b
            fileToImport = ioProc.getImportFile(subjFileName);
            deleteFileToImport = false;
        catch
            wtLog.info('Import file needs trial adjustment...');
            [success, data] = filterAndRenameDataFields(subjFileName); 
            if ~success 
                wtLog.popStatus();
                return
            end
            
            fileToImport = ioProc.getTemporaryFile();
            deleteFileToImport = true;

            if ~WTUtils.saveTo([], tempFileName, '-struct', 'data')
                wtProject.notifyErr([], 'Failed to save temporary data file with trial ajustments (%s)', subjFileName)
                wtLog.popStatus();
                return
            end
        end

        [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_importegimat', ...
            fileToImport, samplingPrms.SamplingRate, egi2eeglPrms.TriggerLatency);

        if deleteFileToImport
            wtLog.dbg('Deleting temporary adjusted import file ''%s''', fileToImport);
            delete(fileToImport);
        end

        if ~success 
            wtProject.notifyErr([], 'Failed to import %s data file in eeglab:\n%s', ...
               WTUtils.ifThenElseSet(deleteFileToImport, 'ADJUSTED ', ''), subjFileName);
            wtLog.popStatus();
            return   
        end

        [success, ALLEEG, EEG, CURRENTSET] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_newset', ...
            ALLEEG, EEG, 0, 'setname', subjects, 'gui', 'off');

        if ~success 
            wtProject.notifyErr([], 'Failed to create new eeglab set');
            wtLog.popStatus();
            return   
        end
        
        try
            if channelsPrms.ReReference ~= channelsPrms.ReReferenceNone
                EEG = restoreCzChannel(EEG, channelsPrms);
            end

            if ~isempty(channelsPrms.CutChannels)
                wtLog.info('Cutting channels: %s', char(join(channelsPrms.CutChannels, ',')));
                EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_select', EEG, 'nochannel', channelsPrms.CutChannels);
                EEG.nbchan = size(EEG.data, 1);
            end

            switch channelsPrms.ReReference
                case channelsPrms.ReReferenceWithAverage
                    wtLog.info('Re-referencing with average...');
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_reref', EEG, []);
                case channelsPrms.ReReferenceWithChannels
                    wtLog.info('Re-referencing with channels...');
                    chansIntersect = intersect(channelsPrms.CutChannels, channelsPrms.NewChannelsReference);
                    if length(chansIntersect)
                        wtProject.notifyErr([], 'Reference channels contains cut channel(s): %s', char(join(chansIntersect)));
                        wtLog.popStatus();
                        return
                    end
                    newRef = [];
                    for ch = 1:length(channelsPrms.NewChannelsReference)
                        actualChan = char(channelsPrms.NewChannelsReference(ch));
                        chanLabels = cat(1, {}, EEG.chanlocs(1,:).labels);
                        chanIdx = find(strcmp(chanLabels, actualChan));
                        newRef = cat(1, newRef, chanIdx);         
                    end
                    
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_reref', EEG, newRef ,'keepref','on');
                otherwise
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_chanedit', EEG, 'load', ...
                        { channelsPrms.ChannelsLocationFile, 'filetype', channelsPrms.ChannelsLocationFileType }, ...
                        'delete', 1, 'delete', 1, 'delete', 1, 'delete', 129);
            end

            % Not sure that the instruction below is useful as repeated just after writeProcessedImport...
            [ALLEEG EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);
            
            [success, ~, EEG] = ioProc.writeProcessedImport(, outFilesPrefix, subject, EEG)
            if ~success
                wtProject.notifyErr([], 'Failed to save processed import for subject ''%s''', subject);
                wtLog.popStatus();
                return
            end

            [ALLEEG EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);
        catch me
            wtLog.mexcpt(me);
            wtProject.notifyErr([], 'Failed to perform channels adjustment');
            wtLog.popStatus();
            return
        end

        [success, EEG] = ioProc.loadProcessedImport(outFilesPrefix, subject);
        if ~success 
            wtProject.notifyErr([], 'Failed to load processed import for subject''%s''', subject);
            wtLog.popStatus();
            return
        end
        
        wtLog.info('Processing conditions...');
        wtLog.pushStatus().ctxOn().setHeaderOn(false);

        for cnd = 1:nConditions
            condition = conditions{cnd};
            wtLog.info('Condition ''%s''', condition);

            try
                cndSet = ioProc.getConditionSet(outFilesPrefix, subject, condition);
                [cndFileFullPath, ~, cndFileName] = ioProc.getConditionFile(outFilesPrefix, subject, condition);

                EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_selectevent', ...
                    EEG,  'type', { condition }, 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');
                [ALLEEG EEG CURRENTSET] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_newset', ...
                    ALLEEG, EEG, 1, 'setname', cndSet, 'savenew', cndFileFullPath, 'gui', 'off');
                [ALLEEG EEG CURRENTSET] =  WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_newset', ...
                    ALLEEG, EEG, cnd+1, 'retrieve', 1, 'study', 0);
                EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);  
            catch me
                wtLog.mexcpt(me);
                wtProject.notifyErr([], 'Failed to process/save condition ''%s'' for subject ''%s''', condition, subject);
                wtLog.popStatus(2);
                return
            end      
        end  

        wtLog.popStatus();
    end

    wtLog.popStatus();
    wtProject.notifyInf([], 'EGI -> EEGLab import completed!');
end

        % === 
    %     if (ReRef==1 || ReRef==2) %If rereferencing is required restore Cz back
            
    %         ref=zeros(1,size(EEG.data,2),size(EEG.data,3)); %restore reference back (because cutted by pop_importegimat.m)
    %         EEG.data = cat(1,EEG.data,ref);
    %         EEG.nbchan = size(EEG.data,1);
    %         EEG = eeg_checkset(EEG);
            
    %         EEG=pop_chanedit(EEG,  'load',{ ChanLocFile, 'filetype', filetp},...
    %             'delete',1, 'delete',1, 'delete',1);
    %     end
        
    %     if ~isempty(CutChannels) %Cut some channels if required
    %         EEG = pop_select( EEG,'nochannel',CutChannels);
    %         EEG.nbchan = size(EEG.data,1);
    %     end
        
    %     if  ReRef==1 %Re-reference to average reference
            
    %         EEG = pop_reref( EEG, []);
            
    %     elseif ReRef==2 %Re-reference to average of some channels (e.g. linked mastoids)
            
    %         newref=[];
            
    %         for ch=1:length(newrefchan)
    %             actualchan=newrefchan(ch);
                
    %             labels={};
                
    %             %FIND channels to process
    %             labels=cat(1,labels,EEG.chanlocs(1,:).labels);
    %             labels=labels';
    %             chanindex=strfind(labels,char(actualchan));
    %             chann=find(~cellfun(@isempty,chanindex));
    %             chann=chann(1,1); %Avoid douplicate values (e.g. E100 to E109 when searching E10)
    %             newref=cat(1,newref,chann);           
    %         end
            
    %         EEG = pop_reref( EEG, newref ,'keepref','on');
            
    %     else %Do not rereference
    %         EEG=pop_chanedit(EEG,  'load',{ ChanLocFile, 'filetype', filetp},...
    %             'delete',1, 'delete',1, 'delete',1,'delete',129);
    %     end
        
    %     [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    %     EEG = eeg_checkset( EEG );
    %     EEG = pop_saveset( EEG,  'filename', SetFileName, 'filepath', SetFilePath);
    %     [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    %     eeglab redraw;
        
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     %Epoch the dataset: one dataset for each condition%
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     currectSubj = char (strcat (filename,subjects(i),'.set'));
    %     SetFilePath = char (strcat (OutPath,subjects(i),'/'));
        
    %     [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    %     EEG = pop_loadset( 'filename', currectSubj, 'filepath', SetFilePath);
    %     [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    %     EEG = eeg_checkset( EEG );
        
    %     for j=1:condN        
    %         Cond = char (conditions(j));
    %         SetFileName = char (strcat (filename,subjects(i),'_',conditions(j)));
    %         SetNewFile = char (strcat(SetFilePath,SetFileName,'.set'));        
    %         EEG = pop_selectevent( EEG,  'type', {Cond}, 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');
    %         [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', SetFileName, 'savenew', SetNewFile, 'gui', 'off');
    %         [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, j+1, 'retrieve',1, 'study',0);
    %         EEG = eeg_checkset( EEG );        
    %     end    
    % end


    % if interactive
    %     allfields = load ('-mat',fullfile(PROJECTPATH,exportvar{1},filenames{1}));
    %     allfields = fieldnames(allfields);    
    %     for index = 1:length(allfields)        
    %         if ~isempty(allfields{index}(1:findstr(allfields{index}, 'Segment')+6))
    %             allfields{index} = allfields{index}(1:findstr(allfields{index}, 'Segment')-2);
    %         else
    %             allfields{index} = 'ThisIsNotACondition';
    %         end        
    %     end    
    %     allfields = unique(allfields);
    %     k=1;
    %     while k<=length(allfields)
    %         if strcmp(allfields{k},'ThisIsNotACondition')
    %             allfields(k)=[];
    %         end
    %         k=k+1;
    %     end    
    %     if length(allfields)>1        
    %         % Prompt the user to select the conditions to import from a list
    %         condlist = listdlg('PromptString','Select conditions:','SelectionMode','multiple','ListString',allfields);        
    %         if isempty(condlist)
    %             return %quit on cancel button
    %         end        
    %         allfields = allfields(condlist);        
    %     end
        
    %     % Save the conditions config file in the Config folder
    %     pop_cfgfile = fullfile(PROJECTPATH,'Config','cond.m');
    %     fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    %     fprintf(fid, 'conditions = { ');
    %     for i=1:length(allfields)
    %         fprintf(fid, ' ''%s'' ',char(allfields(i)));
    %     end    
    %     fprintf(fid, ' };\r');
    %     fprintf(fid, 'condiff = {};');
    %     fclose(fid);
        
    %     cd ('Config');
    %     cond;
    %     cd (PROJECTPATH);
    %     condN = size(conditions,2);    
    % else    
    %     condN = size(conditions,2);    
    % end

%     if exist('PROJECTPATH','var')
%         temp = char(exportvar);
%         InPath = fullfile (PROJECTPATH,temp);
%         OutPath = PROJECTPATH;
%     else
%         InPath = char(exportvar);
%         OutPath = '../';
%     end

%     for i = 1:nSubjects    
%         subjDir = char (strcat (subjects(i)));
%         alreadyexistdir=strcat(OutPath,subjDir);
%         if ~exist(alreadyexistdir,'dir')
%             mkdir (OutPath, subjDir);
%         end    
%         if exist('filenames','var')
%             currectSubj = char (fullfile(InPath,filenames(i)));
%         else
%             currectSubj = char (strcat (InPath,subjects(i),'export.mat'));
%         end    
%         tempfile = char (strcat (InPath,'temp.mat'));    
%         if exist('PROJECTPATH','var') && i==1 %do it only once
%             wtoolspath = which('wtEGIToEEGLab.m');
%             slashes = findstr(wtoolspath,sla); % FIX!!!
%             chanpath = strcat(wtoolspath(1:slashes(end-1)),'chans_splines');
%             cd (chanpath);
%             % Set channels config file (*.sfp file)
%             [ChanLocFile, pathname, filterindex]=uigetfile({ '*.sfp' },'Select channels location file','MultiSelect','off');        
%             if ~pathname
%                 cd (PROJECTPATH);
%                 return %quit on cancel button
%             end
            
%             chanloc = { strcat(pathname,ChanLocFile) };
%             filetyp = { 'autodetect' };
            
%             % Create channels array from the chan config file (*.sfp file) used
%             % to set channels to re-ref (eventually) and channels to cut
%             [a b c d]=textread(chanloc{1},'%s %s %s %s','delimiter', '\t');
%             labels=a(4:end);
%             labels=labels';
            
%             %Save the channels location file in the Config folder
%             pop_cfgfile = fullfile(PROJECTPATH,'Config','chan.m');
%             fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
%             fprintf(fid, 'chanloc = { ''%s'' };\r',ChanLocFile);
%             fprintf(fid, 'filetyp = { ''autodetect'' };\r');
            
%             %Save the spline file in the Config folder
%             [SplineFile, pathname, filterindex]=uigetfile({ '*.spl' },'Select spline file','MultiSelect','off');
            
%             if ~pathname
%                 cd (PROJECTPATH);
%                 return %quit on cancel button
%             end
            
%             fprintf(fid, 'splnfile = { ''%s'' };\r',SplineFile);
%             cd (PROJECTPATH);
            
%             parameters    = { { 'style' 'text' 'string' 'Do you want to re-reference? (Ok = yes)' } };
            
%             geometry = { [1] };
            
%             [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Re-referencing');
%             if strcmp(strhalt,'retuninginputui')
%                 parameters    = { { 'style' 'text' 'string' 'Click Ok to re-reference to average reference,' } ...
%                     { 'style' 'text' 'string' 'click Cancel to select new reference electrodes' } };
                
%                 geometry = { [1] [1] };
%                 [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Select channels');
                
%                 if strcmp(strhalt,'retuninginputui')
%                     %Save the re-ref info (re-ref to avr) and no new reference channels in the Config folder
%                     fprintf(fid, 'ReRef = %i;\r',1);
%                     fprintf(fid, 'newrefchan = {};\r');
%                 else
%                     %Save the re-ref info (re-ref to new channels) in the Config folder
%                     fprintf(fid, 'ReRef = %i;\r',2);
%                     chanlist = listdlg('PromptString','Select channels:','SelectionMode','multiple','ListString',labels);
                    
%                     if isempty(chanlist)
%                         return %quit on cancel button
%                     end
                    
%                     newrefchan = labels(chanlist);
%                     %Save the new reference channels in the Config folder
%                     fprintf(fid, 'newrefchan = { ');
%                     for k=1:length(newrefchan)
%                         fprintf(fid, ' ''%s'' ',char(newrefchan(k)));
%                     end
%                     fprintf(fid, ' };\r');
                    
%                 end
                
%             else
%                 %Save the re-ref info (no re-ref needed) in the Config folder
%                 fprintf(fid, 'ReRef = %i;\r',0);
%             end
            
%             parameters    = { { 'style' 'text' 'string' 'Do you need to cut some channels? (Ok = yes)' } };
            
%             geometry = { [1] };
            
%             [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Cut channels');
%             if strcmp(strhalt,'retuninginputui')
%                 chanlist = listdlg('PromptString','Select channels:','SelectionMode','multiple','ListString',labels);
                
%                 if isempty(chanlist)
%                     return %quit on cancel button
%                 end
                
%                 CutChannels = labels(chanlist);
%                 %Save the the channels to cut info in the Config folder
%                 fprintf(fid, 'CutChannels = { ');
%                 for k=1:length(CutChannels)
%                     if k<length(CutChannels)
%                         fprintf(fid, ' ''%s'', ',char(CutChannels(k)));
%                     else
%                         fprintf(fid, ' ''%s'' ',char(CutChannels(k)));
%                     end
%                 end            
%                 fprintf(fid, ' };');
%                 fclose(fid);            
%             else            
%                 fprintf(fid, 'CutChannels = {};');
%                 fclose(fid);
                
%             end
%             chan;
%             ChanLocFile = char (strcat (pathname,chanloc));
%             filetp = char (filetyp);
%         else        
%             if i==1
%                 ChanLocFile = char (strcat (OutPath,'cfg/',chanloc));
%                 filetp = char (filetyp);
%             end
%         end

%         SetFileName = char (strcat (filename,subjects(i),'.set'));
%         SetFilePath = char (strcat (OutPath,subjects(i),'/'));
        
%         if i == 1 %READ sampling rate, trigger latency and set max trial ID to process (only once, for the first subject)
%             load(currectSubj, 'ECI_TCPIP_55513');
            
%             samplingrate = 0;
%             warning off all
            
%             try
%                 load(currectSubj, 'samplingRate'); %Netstation 4.4.x
%                 samplingrate = samplingRate;
%             end
            
%             try
%                 load(currectSubj, 'EEGSamplingRate'); %Netstation 5.x.x
%                 samplingrate = EEGSamplingRate;
%             end
            
%             warning on all
            
%             %Older version of Netstation
%             if ~samplingrate
                
%                 %Load previously called parameters if existing
%                 pop_cfgfile = fullfile(PROJECTPATH,'Config','samplrate.m');
%                 if exist(pop_cfgfile,'file')
%                     samplrate;
%                     defaultanswer=defaultanswer;
%                 else
%                     defaultanswer={''};
%                 end
                
%                 parameters    = { ...
%                     { 'style' 'text' 'string' 'Sampling rate (Hz):' } ...
%                     { 'style' 'edit' 'string' defaultanswer{1,1} } ...
%                     { 'style' 'text' 'string' 'Enter the recording sampling rate' } };
                
%                 geometry = { [1 0.5] [1] };
%                 [answer userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters, 'title', 'Set trigger' );
                
%                 %Quit on cancel button
%                 if ~strcmp(strhalt,'retuninginputui')
%                     return;
%                 end
                
%                 samplingrate = str2num(answer{1,1});
                
%                 %Save the user input parameters in the Config folder
%                 fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
%                 fprintf(fid, 'defaultanswer={''%s''};',...
%                     num2str(samplingrate));
%                 fclose(fid);
                
%             end
            
%             %Load previously called parameters if existing
%             pop_cfgfile = fullfile(PROJECTPATH,'Config','trigger.m');
%             if exist(pop_cfgfile,'file')
%                 trigger;
%                 defaultanswer=defaultanswer;
%             else
%                 defaultanswer={''};
%             end
            
%             parameters    = { ...
%                 { 'style' 'text' 'string' 'Trigger latency (ms):' } ...
%                 { 'style' 'edit' 'string' defaultanswer{1,1} } ...
%                 { 'style' 'text' 'string' 'Enter nothing to time lock to the onset of the stimulus,' } ...
%                 { 'style' 'text' 'string' 'enter a positive value to time lock to any point from' } ...
%                 { 'style' 'text' 'string' 'the begin of the segment.' } };
            
%             geometry = { [1 0.5] [1] [1] [1] };
%             [answer userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters, 'title', 'Set trigger' );
            
%             %Quit on cancel button
%             if ~strcmp(strhalt,'retuninginputui')
%                 return;
%             end
            
%             triglat = str2num(answer{1,1});
            
%             %Save the user input parameters in the Config folder
%             fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
%             fprintf(fid, 'defaultanswer={''%s''};',...
%                 num2str(triglat));
%             fclose(fid);
            
%             %Read trigger latency from the exported .mat file (automatic time
%             %lock to the stimulus onset).
%             if isempty(triglat)
%                 triglat = cell2mat(ECI_TCPIP_55513(4,1))*(1000/samplingrate); %Transform trigger latency in ms
%             end
            
%             %SET defaultaswer0
%             defaultanswer0={ '', '' };
%             answersN=length(defaultanswer0);
            
%             %Load previously called parameters if existing
%             pop_cfgfile = fullfile(PROJECTPATH,'Config','minmaxtrialid.m');
            
%             if exist(pop_cfgfile,'file')
%                 minmaxtrialid;
%                 try
%                     defaultanswer=defaultanswer;
%                     defaultanswer{1,answersN};
%                 catch
%                     fprintf('\n');
%                     fprintf(2, 'The minmaxtrialid.m file in the Config folder was created by a previous version\n');
%                     fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
%                     fprintf('\n');
%                     defaultanswer=defaultanswer0;
%                 end
%             else
%                 defaultanswer=defaultanswer0;
%             end
            
%             parameters    = { ...
%                 { 'style' 'text' 'string' 'Min Trial ID:' } ...
%                 { 'style' 'edit' 'string' defaultanswer{1,1} } ...
%                 { 'style' 'text' 'string' 'Max Trial ID:' } ...
%                 { 'style' 'edit' 'string' defaultanswer{1,2} } ...
%                 { 'style' 'text' 'string' 'Enter nothing to process all available trials.' } ...
%                 { 'style' 'text' 'string' 'Enter only min or Max to process trials above/below a trial ID.' } ...
%                 { 'style' 'text' 'string' 'Enter min/max positive integers to set the min/max trial' } ...
%                 { 'style' 'text' 'string' 'ID to process.' } };
            
%             geometry = { [1 0.5] [1 0.5] [1] [1] [1] [1] };
%             [answer userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters, 'title', 'Set min/Max Trial ID' );
            
%             %Quit on cancel button
%             if ~strcmp(strhalt,'retuninginputui')
%                 return;
%             end
            
%             mintrid=str2num(answer{1,1});
%             maxtrid=str2num(answer{1,2});
            
%             %Save the user input parameters in the Config folder
%             fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
%             fprintf(fid, 'defaultanswer={''%s'' ''%s''};',...
%                 num2str(mintrid),num2str(maxtrid));
%             fclose(fid);
            
%             %SET trials to process (all vs. user defined interval)
%             if isempty(mintrid) && isempty(maxtrid)
%                 alltrials = 1; %Process all available trials
%                 mintrid = NaN;
%                 maxtrid = NaN;
%             elseif isempty(maxtrid) % = min trial id is an integer
%                 alltrials = 0;
%                 maxtrid = 1000000; %The trial ID will pass the test mintrid<=ID<=maxtrid below
%             elseif isempty(mintrid) % = max trial id is an integer
%                 alltrials = 0;
%                 mintrid = 0; %The trial ID will pass the test mintrid<=ID<=maxtrid below
%             else
%                 alltrials = 0;
%             end
            
%         end

%         try
%             [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;        
%         catch        
%             fprintf(2,'\nPlease, start EEGLAB first!!!\n');
%             fprintf('\n');
%             return        
%         end
        
%         try
%             eeg_getversion; %introduced in EEGLAB v9.0.0.0b
            
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             %Import the subject in EEGLAB version 9 or higher: no adjustements needed%
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             EEG = pop_importegimat(currectSubj, samplingrate, triglat);
            
%         catch
            
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             %Rename trials in continous way to avoid stop importing in EEGLAB old versions%
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
%             c = []; %Inizialization necessary when using with All();
            
%             tmpdata = load('-mat', currectSubj);
%             allfields = fieldnames(tmpdata);
%             allfields2 = fieldnames(tmpdata);
%             t=1;
            
%             index = 1;
            
%             while length(allfields)
                
%                 if index > length(allfields)
%                     break
%                 end
                
%                 segmentFlag = 0;
                
%                 %Test wheter the field is a segment
%                 fieldname=allfields{index}(1:findstr(allfields{index}, 'Segment')+6);
%                 if ~isempty(fieldname)
%                     segmentFlag = 1; %Segment found = the string 'Segment' is in the field lable                
%                     segN=allfields{index}(length(fieldname)+1:end);                
%                     if (str2double(segN) >= mintrid && str2double(segN) <= maxtrid) || alltrials                    
%                         allfields{index} = fieldname; %Cut original segment number                   
%                     else                    
%                         segmentFlag = 0;
%                         allfields(index)=[];
%                         allfields2(index)=[];
%                         index = index - 1;                    
%                     end                
%                 end            
%                 if index == 1 && segmentFlag
%                     allfields{index}=char(strcat(allfields{index},num2str(t))); %Replace segment number with progressive number t
%                     t=t+1;
%                 elseif segmentFlag                
%                     %If index >1 compare field label with previous one
%                     a=cellstr(allfields{index-1}(1:findstr(allfields{index-1}, 'Segment')-2));  %Previous label
%                     b=cellstr(allfields{index}(1:findstr(allfields{index}, 'Segment')-2));      %Present label                
%                     if segmentFlag && strcmp(a,b) %Field labels are equal = same condition
%                         allfields{index}=char(strcat(allfields{index},num2str(t))); %Replace segment number with progressive number t
%                         t=t+1;
%                     elseif segmentFlag %Field labels are not equal = the field is a segment of the next condition
%                         t=1;
%                         allfields{index}=char(strcat(allfields{index},num2str(t))); %Replace segment number with progressive number t
%                         t=t+1;
%                     elseif ~segmentFlag %The field is not a segment
%                         %allfields{index}=char(strcat(allfields{index})); %Replace field label with itself
%                         t=1;
%                     end                
%                 end            
%                 index = index + 1;            
%             end
            
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             %Adjust allfields and allfields2 to include only the selected conditions%
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
%             allfields3 = [];
%             allfields4 = [];
            
%             for k = 1:length(conditions)            
%                 for index = 1:length(allfields)                
%                     if (~isempty(findstr(allfields{index},conditions{k})) ||...
%                             strcmp(allfields{index},'samplingRate') ||...
%                             strcmp(allfields{index},'ECI_TCPIP_55513'))
                        
%                         allfields3{index} = allfields{index};                    
%                     end                
%                     if (~isempty(findstr(allfields2{index},conditions{k})) ||...
%                             strcmp(allfields2{index},'samplingRate') ||...
%                             strcmp(allfields2{index},'ECI_TCPIP_55513'))
                        
%                         allfields4{index} = allfields2{index};                    
%                     end                
%                 end            
%             end
            
%             allfields3 = allfields3';
%             allfields4 = allfields4';
            
%             delcond = find(cellfun(@isempty,allfields3));
%             allfields3(delcond) = [];
%             allfields = allfields3;
            
%             delcond = find(cellfun(@isempty,allfields4));
%             allfields4(delcond) = [];
%             allfields2 = allfields4;
            
%             for index = 1:length(allfields)
%                 c.(char(allfields(index)))=tmpdata.(char(allfields2(index)));
%             end
            
%             save (tempfile, '-struct', 'c');
            
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             %Import the subject in EEGLAB verion 8 or lower%
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             EEG = pop_importegimat(tempfile, samplingrate, triglat);        
%             delete (tempfile);        
%         end

%         % START ==============================
%         [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', subjects, 'gui', 'off');
        
%         if (ReRef==1 || ReRef==2) %If rereferencing is required restore Cz back
            
%             ref=zeros(1,size(EEG.data,2),size(EEG.data,3)); %restore reference back (because cutted by pop_importegimat.m)
%             EEG.data = cat(1,EEG.data,ref);
%             EEG.nbchan = size(EEG.data,1);
%             EEG = eeg_checkset(EEG);
            
%             EEG=pop_chanedit(EEG,  'load',{ ChanLocFile, 'filetype', filetp},...
%                 'delete',1, 'delete',1, 'delete',1);
%         end
        
%         if ~isempty(CutChannels) %Cut some channels if required
%             EEG = pop_select( EEG,'nochannel',CutChannels);
%             EEG.nbchan = size(EEG.data,1);
%         end
        
%         if  ReRef==1 %Re-reference to average reference
            
%             EEG = pop_reref( EEG, []);
            
%         elseif ReRef==2 %Re-reference to average of some channels (e.g. linked mastoids)
            
%             newref=[];
            
%             for ch=1:length(newrefchan)
%                 actualchan=newrefchan(ch);
                
%                 labels={};
                
%                 %FIND channels to process
%                 labels=cat(1,labels,EEG.chanlocs(1,:).labels);
%                 labels=labels';
%                 chanindex=strfind(labels,char(actualchan));
%                 chann=find(~cellfun(@isempty,chanindex));
%                 chann=chann(1,1); %Avoid douplicate values (e.g. E100 to E109 when searching E10)
%                 newref=cat(1,newref,chann);           
%             end
            
%             EEG = pop_reref( EEG, newref ,'keepref','on');
            
%         else %Do not rereference
%             EEG=pop_chanedit(EEG,  'load',{ ChanLocFile, 'filetype', filetp},...
%                 'delete',1, 'delete',1, 'delete',1,'delete',129);
%         end
        
%         [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%         EEG = eeg_checkset( EEG );
%         EEG = pop_saveset( EEG,  'filename', SetFileName, 'filepath', SetFilePath);
%         [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%         eeglab redraw;
        
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         %Epoch the dataset: one dataset for each condition%
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         currectSubj = char (strcat (filename,subjects(i),'.set'));
%         SetFilePath = char (strcat (OutPath,subjects(i),'/'));
        
%         [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
%         EEG = pop_loadset( 'filename', currectSubj, 'filepath', SetFilePath);
%         [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
%         EEG = eeg_checkset( EEG );
        
%         for j=1:condN        
%             Cond = char (conditions(j));
%             SetFileName = char (strcat (filename,subjects(i),'_',conditions(j)));
%             SetNewFile = char (strcat(SetFilePath,SetFileName,'.set'));        
%             EEG = pop_selectevent( EEG,  'type',{Cond}, 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');
%             [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', SetFileName, 'savenew', SetNewFile, 'gui', 'off');
%             [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, j+1, 'retrieve',1, 'study',0);
%             EEG = eeg_checkset( EEG );        
%         end    
%         eeglab redraw;    
%     end

%     rehash;

%     fprintf('\nDone!!!\n');
%     fprintf('\n');
% end

% % ==========

function fileName = getImportFileForSubject(ioProc, subject)
    [~, ~, fileName ] = ioProc.getImportFileForSubject(subject);
end

function [success, sbjFileNames] = selectUpdateSubjects() 
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    subjectsParams = wtProject.Config.Subjects;
    subjects = {};
    sbjFileNames = {};

    if subjectsParams.exist()
        if ~WTUtils.eeglabYesNoDlg('Re-import subjects?', ['The subject configuration file already exists!\n' ...
                'Do you want to import the subjects again?']);
            return;
        end            
    end     
    
    [subjects, sbjFileNames] = WTImportGUI.importedSubjectsSelect();
    if isempty(subjects) 
        wtLog.warn('No subjects to import selected');
        return
    end

    subjectsParams = copy(subjectsParams);
    subjectsParams.SubjectsList = subjects;

    if ~subjectsParams.persist()
        wtProject.notifyErr([], 'Failed to save subjects to import params');
        return
    end

    wtProject.Config.Subjects = subjectsParams;
    success = true;
end

function success = selectUpdateConditions(anImportedFile) 
    wtProject = WTProject();
    wtLog = WTLog();
    ioProc = wtProject.Config.IOProc;

    [success, conditions, ~] = ioProc.getConditionsFromImport(anImportedFile);
    if ~success
        wtLog.err('Failed to get conditions from imported file ''%s''', anImportedFile);
        return
    end

    success = false;
    conditions = WTUtils.stringsSelectDlg('Select conditions', conditions, false, true);
    if isempty(conditions) 
        wtLog.warn('No conditions selected');
        return
    end

    conditionsPrms = copy(wtProject.Config.Conditions);
    conditionsPrms.ConditionsList = conditions;
    conditionsPrms.ConditionsDiff = {};

    if ~conditionsPrms.persist() 
        wtProject.notifyErr([], 'Failed to save import conditions params');
        return
    end

    wtProject.Config.Conditions = conditionsPrms;
    success = true;
end

function chansLabels = getChannelsLabels(chanLocFile)
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;
    chansLabels = {};

    [success, channelsLoc] = ioProc.readChannelsLocations(chanLocFile);
    if ~success 
        wtProject.notifyErr([], 'Failed to read channels location from ''%s''', chanLocFile); 
        return
    end

    chansLabels = cellfun(@(x)(x.Label), channelsLoc, 'UniformOutput', false);
    % The following applies to GSN-HydroCel-129.sfp (not sure if Biosemi_35Ch.sfp should be filtered in any way...)
    chansLabels = chansLabels(~cellfun(@isempty, regexp(chansLabels, '^(?!Fid).+$', 'match')));
end 

function success = selectUpdateChannels()
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    ioProc = wtProject.Config.IOProc;

    channelsPrms = copy(wtProject.Config.Channels);

    selectionFlt = fullfile(ioProc.ImportDir, ioProc.ChannelsLocationFileTypeFlt);
    [chanLocFile, chnLocDir, ~] = WTUtils.uiGetFiles(selectionFlt, ...
        'Select channels location file', 'MultiSelect', 'off', WTLayout.getToolsSplinesDir());
    if isempty(chanLocFile) 
        wtLog.warn('No channel location file selected');
        return
    end

    selectionFlt = fullfile(ioProc.ImportDir, ioProc.SplineFileTypeFlt);
    [splineFile, splineDir, ~] = WTUtils.uiGetFiles(selectionFlt, ...
        'Select spline file', 'MultiSelect', 'off', WTLayout.getToolsSplinesDir());
    if isempty(splineFile) 
        wtLog.warn('No spline file selected');
        return
    end

    channelsPrms.ChannelsLocationFile = chanLocFile{1};
    channelsPrms.ChannelsLocationFileType = 'autodetect';
    channelsPrms.SplineFile = splineFile{1};
    channelsLabels = {};
    
    if ~WTUtils.eeglabYesNoDlg('Cutting channels', 'Would you like to cut some channels?')
        channelsPrms.CutChannels = {};
    else
        channelsLabels = getChannelsLabels(channelsPrms.ChannelsLocationFile);
        if isempty(channelsLabels)
            wtProject.notifyErr([], 'No channels found in ''%s''', channelsPrms.ChannelsLocationFile);
            return
        end
        cutChannels = {};
        while isempty(cutChannels)
            [cutChannels, selected] = WTUtils.stringsSelectDlg('Select channels\nto cut:', channelsLabels, false, true);
            if isempty(cutChannels)
                if WTUtils.eeglabYesNoDlg('Confirm', 'No channels to cut selected: proceed?')
                    break;
                end
            elseif length(channelsLabels) == length(cutChannels)
                wtProject.notifyWrn([], 'You can''t cut all the channels!');
                cutChannels = {};
            else
                channelsPrms.CutChannels = cutChannels;
                channelsLabels = channelsLabels(setdiff(1:end,selected));
            end
        end
    end

    if ~WTUtils.eeglabYesNoDlg('Re-referencing channels', 'Would you like to re-reference?')
        channelsPrms.ReReference = channelsPrms.ReReferenceNone;
    else
        choices = { 'Average reference', 'New reference electrodes' };
        doneWithSelection = false;

        while ~doneWithSelection
            [~, selected] = WTUtils.stringsSelectDlg('Select re-reference', choices, true, true, 'ListSize', [220, 100]);
            if isempty(selected)
                if WTUtils.eeglabYesNoDlg('Confirm', 'No re-referencing selected: proceed?')
                    channelsPrms.ReReference = channelsPrms.ReReferenceNone;
                    doneWithSelection = true;
                end
            elseif selected == 1
                channelsPrms.ReReference = channelsPrms.ReReferenceWithAverage;
                channelsPrms.NewChannelsReference = {};
                doneWithSelection = true;
            else
                if isempty(channelsLabels)
                    channelsLabels = getChannelsLabels(channelsPrms.ChannelsLocationFile);
                    if isempty(channelsLabels)
                        wtProject.notifyErr([], 'No channels found in ''%s''', channelsPrms.ChannelsLocationFile);
                        return
                    end
                end 
                while ~doneWithSelection
                    [refChannels, selected] = WTUtils.stringsSelectDlg('Select reference channels\n(cut channels are excluded):', channelsLabels, false, true);
                    if isempty(refChannels)
                        if WTUtils.eeglabYesNoDlg('Confirm', 'No channels for re-referencing selected: proceed?')
                            channelsPrms.ReReference = channelsPrms.ReReferenceNone;
                            doneWithSelection = true;
                        end
                    else
                        channelsPrms.ReReference = channelsPrms.ReReferenceWithChannels;
                        channelsPrms.NewChannelsReference = refChannels;
                        doneWithSelection = true;
                    end
                end
            end
        end
    end 

    if ~channelsPrms.persist()
        wtProject.notifyErr([], 'Failed to save channels parameters!');
        return
    end

    wtProject.Config.Channels = channelsPrms;
    success = true;
end

function success = setSamplingRate(subjFileName)
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    ioProc = wtProject.Config.IOProc;
 
    [success, samplingRate] = ioProc.loadImport(subjFileName, 'samplingRate'); % Netstation 4.4.x
    if ~success  
        [success, samplingRate] = ioProc.loadImport(subjFileName, 'EEGSamplingRate'); % Netstation 5.x.x
    end

    samplingPrms = copy(wtProject.Config.Sampling);

    if success && samplingRate > 0
        samplingPrms.SamplingRate = samplingRate;
    elseif ~WTConvertGUI.defineSamplingRate(samplingPrms)
        return
    end
    
    if ~samplingPrms.persist()
        wtProject.notifyErr([], 'Failed to save sampling params');
        return
    end

    wtProject.Config.Sampling = samplingPrms;
    success = true;
end

function success = setTriggerLatency()
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    egi2eeglPrms = copy(wtProject.Config.EGIToEEGLab);

    if ~WTConvertGUI.defineTriggerLatency(egi2eeglPrms)
        return
    end
    
    if ~egi2eeglPrms.persist()
        wtProject.notifyErr([], 'Failed to save trigger latency params');
        return
    end

    wtProject.Config.EGIToEEGLab = egi2eeglPrms;
    success = true;
end

function [success, egi2eeglPrms] = autoSetTriggerLatency(subjFileName)
    success = false;
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;
    egi2eeglPrms = copy(wtProject.Config.EGIToEEGLab);
    samplingPrms = wtProject.Config.Sampling;

    if egi2eeglPrms.TriggerLatency > 0
        success = true;
        return
    end
    % Set trigger latency from the exported .mat file (automatic time lock to the stimulus onset).
    [success, eciTCPIP] = ioProc.loadImport(subjFileName, 'ECI_TCPIP_55513');
    if ~success 
        wtProject.notifyErr([], 'Failed to read ECI_TCPIP_55513 from %s', subjFileName);
        return
    end
    egi2eeglPrms.TriggerLatency = cell2mat(eciTCPIP(4,1))*(1000/samplingPrms.SamplingRate);
end

function success = setMinMaxTrialId()
    success = false;
    wtProject = WTProject();
    wtLog = WTLog();
    minMaxTrialIdPrms = copy(wtProject.Config.MinMaxTrialId);

    if ~WTConvertGUI.defineTrialsRangeId(minMaxTrialIdPrms)
        return
    end
    
    if ~minMaxTrialIdPrms.persist()
        wtProject.notifyErr([], 'Failed to save min/max trial id params');
        return
    end

    wtProject.Config.MinMaxTrialId = minMaxTrialIdPrms;
    success = true;
end

function [success, dataOut] = filterAndRenameDataFields(subjFileName)
    success = false;
    wtProject = WTProject();
    dataOut = struct();

    [success, data] = ioProc.loadImport(subjFileName);
    if ~success 
        wtProject.notifyErr([], 'Failed to read subject data from %s', subjFileName);
        return
    end

    ioProc = wtProject.IOProc;
    selectedConditions = wtProject.Config.ConditionsList;
    minMaxTrialIdPrms = wtProject.Config.MinMaxTrialId;
    minMaxTrialIdPrms = minMaxTrialIdPrms.interpret();

    dataOut = struct();
    allTrials = minMaxTrialIdPrms.allTrials();
    minTrial = minMaxTrialIdPrms.MinTrialId;
    maxTrial = minMaxTrialIdPrms.MaxTrialId;

    data = orderfields(data);
    dataFields = fieldnames(data);
    % find the <condition>_Segment<#> fields
    reResult = regexp(dataFields, ioProc.EGIConditionSegmentFldRe, 'once', 'tokens');
    selected = ~cellfun(@isempty, reResult); 
    selectedIdxs = find(selected);
    % extract conditions name
    matches = reResult(selection);
    cndSeg = cat(1, matches{:});  % {{'cnd'}, {'seg'}}
    conditions = unique(cndSeg(:,1));
    % create a counters for each condition
    counters = cell2struct(repmat({zeros(1)},1,length(conditions)), conditions, 2);
    
    for i = 1:length(selectedIdxs)
        fldIdx = idxs(i)
        cndName = reResult{fldIdx}{1};
        if ~any(strcmp(cndName, selectedConditions)) % ignore unselected conditions
            continue
        end
        segNum = str2double(reResult{fldIdx}{2});
        if ~allTrials && (segNum < minTrial || segNum > maxTrial) % ignore trials out of rangre
            % not sure why when allTrials we should rename fields...
            continue
        end
        cndName = reResult{fldIdx}{1};
        newSegNum = getfield(counters, fldName)+1;
        setfield(counters, cndName, newSegNum);
        newFieldName = [cndName '_Segment' num2str(newSegNum)];
        setfield(dataOut, newFieldName, getfield(data, dataFields{fldIdx}));
    end

    invariantFields = char(dataFields(~selected));
    dataOut.(invariantFields) = data.(invariantFields);
end


% Restore reference back (as if EEG was loaded with pop_importegimat.m, it was cut)
function EEG = restoreCzChannel(EEG, channelsPrms) 
    WTLog().info('Restoring Cz channel to apply re-referencing...');
    ref = zeros(1, size(EEG.data, 2), size(EEG.data, 3)); 
    EEG.data = cat(1, EEG.data, ref);
    EEG.nbchan = size(EEG.data, 1);
    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_chanedit', EEG,  'load', ...
        { channelsPrms.ChannelsLocationFile, 'filetype', channelsPrms.ChannelsLocationFileType }, ...
        'delete', 1, 'delete', 1, 'delete', 1);
end