% wtEEPToEEGLab.m
% Created by Eugenio Parise
% CDC CEU 2011
% Function to import ANT EEProbe files in EEGLAB. After importing the
% original one EEGLAB file, the script will segmented such file
% into multiple EEGLAB datasets: one for each experimental condition.
% To set this script to process the whole final sample of subjects in a study,
% edit 'subj.m' in the 'cfg' folder and digit wtEEPToEEGLab([],...) (empty value) at
% the console prompt.
% 
% Usage:
% 
% wtEEPToEEGLab(subjects,epochlimits,hpf,lpf)
% wtEEPToEEGLab('02',[-200 1000],0.3,65)
% wtEEPToEEGLab([],[-200 1000],0.3,65)

function wtEEPToEEGLab()
    wtProject = WTProject();
    wtLog = WTLog();
    wtLog.pushStatus().ctxOn('EEPToEEGLab');

    if ~wtProject.checkIsOpen()
        wtLog.popStatus();
        return
    end

    interactive = wtProject.Interactive;
    system = WTIOProcessor.SystemEEP;

    if interactive  
        [success, sbjFileNames] = wtSelectUpdateSubjects(system);
        if ~success
            wtLog.popStatus();
            return
        end  
        if ~wtSelectUpdateConditions(system, sbjFileNames{1}) || ...
            ~wtSelectUpdateChannels(system) || ... 
            ~setEpochsLimitsAndFreqFilter()
            wtLog.popStatus();
            return
        end
    else
        if ~wtProject.Config.Subjects.validate()
            wtProject.notifyErr('Subjects params are not valid');
            wtLog.popStatus();
            return
        end
        if ~wtProject.Config.EEPToEEGLab.validate()
            wtProject.notifyErr('EEP to EEGLab conversinos params are not valid');
            wtLog.popStatus();
            return
        end
    end

    ioProc = wtProject.Config.IOProc;
    subjectsPrms = wtProject.Config.Subjects;
    subjects = subjectsPrms.SubjectsList;
    subjectFileNames = subjectsPrms.FilesList;
    nSubjects = length(subjects);
    conditionsPrms = wtProject.Config.Conditions;
    EEPToEEGLabPrms = wtProject.Config.EEPToEEGLab;
    conditions = conditionsPrms.ConditionsList;
    nConditions = length(conditions);
    channelsPrms = wtProject.Config.Channels;
    outFilesPrefix = wtProject.Config.Prefix.FilesPrefix;
    epochLimits = EEPToEEGLabPrms.EpochLimits / 1000;
    
    if nSubjects == 0 
        wtLog.warn('No subjects to process');
        wtLog.popStatus();
        return 
    end

    if ~wtSetSampleRate(system, subjectFileNames{1})
        return
    end

    for sbj = 1:nSubjects 
        subject = subjects{sbj};
        subjFileName = subjectFileNames{sbj}; 
        wtLog.info('Processing import file %s', subjFileName);

        [success, ALLEEG, ~, ~] =  WTUtils.eeglabRun(WTLog.LevelDbg, true);
        if ~success 
            wtProject.notifyErr([], 'Failed to run eeglab');  
            wtLog.popStatus();      
            return
        end

        [success, EEG] = ioProc.loadImport(system, subjFileName);
        if ~success 
            wtProject.notifyErr([], 'Failed to load import: ''%s''', ioProc.getImportFile(subjFileName));
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

        if ~isempty(channelsPrms.CutChannels)
            wtLog.info('Cutting channels: %s', char(join(channelsPrms.CutChannels, ',')));
            [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_select', EEG, 'nochannel', channelsPrms.CutChannels);
            if ~success 
                wtProject.notifyErr([], 'Failed cut channels');
                wtLog.popStatus();
                return   
            end
            EEG.nbchan = size(EEG.data, 1);
        end

        % Apply HighPass and LowPass filters separately. This is a workaround because sometimes MATLAB 
        % does not find a good solution for BandPass filter.
        if ~isnan(EEPToEEGLabPrms.HighPassFilter)
            [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_eegfilt', ...
                EEG, EEPToEEGLabPrms.HighPassFilter, [], [], 0);
            if ~success 
                wtProject.notifyErr([], 'Failed to apply high pass filter');
                wtLog.popStatus();
                return   
            end
        end

        if ~isnan(EEPToEEGLabPrms.LowPassFilter)
            [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_eegfilt', ...
                EEG, [], EEPToEEGLabPrms.LowPassFilter, [], 0);
            if ~success 
                wtProject.notifyErr([], 'Failed to apply low pass filter');
                wtLog.popStatus();
                return   
            end
        end

        try 
            switch channelsPrms.ReReference
                case channelsPrms.ReReferenceWithAverage
                    wtLog.info('Re-referencing with average...');
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_reref', EEG, []);
                case channelsPrms.ReReferenceWithChannels
                    wtLog.info('Re-referencing with channels...');
                    chansIntersect = intersect(channelsPrms.CutChannels, channelsPrms.NewChannelsReference);
                    if ~isempty(chansIntersect)
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
                    % This was done before the "switch" in the original code: not sure why: I guess we'll discover it during usage...
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_chanedit', EEG, 'load', ...
                        { channelsPrms.ChannelsLocationFile, 'filetype', channelsPrms.ChannelsLocationFileType });
            end
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to perform channels re-referencing for subject ''%s''', subject);
            wtLog.popStatus();
            return
        end

        % Apply original rejection performed in EEProbe
        try 
            rejectionFile = WTIOProcessor.getEEPRejectionFile(ioProc.getImportFile(subjFileName));
            rejection = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'read_eep_rej', rejectionFile);
            rejection = rejection./(1000/EEG.srate);
            if rejection(1,1) == 0
                rejection(1,1) = 1;
            end
            EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_eegrej', EEP, rejection);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to apply original rejection performed in EEProbe for subject ''%s''', subject);
            wtLog.popStatus();
            return
        end

        [success, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_epoch', EEG, {}, epochLimits, 'epochinfo', 'yes');
        if ~success
            wtProject.notifyErr([], 'Failed to apply epoch limits for subject ''%s''', subject);
            wtLog.popStatus();
            return
        end

        try 
            % Not sure that the instruction below is useful as repeated just after writeProcessedImport...
            [ALLEEG, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);

            [success, ~, EEG] = ioProc.writeProcessedImport(outFilesPrefix, subject, EEG);
            if ~success
                wtProject.notifyErr([], 'Failed to save processed import for subject ''%s''', subject);
                wtLog.popStatus();
                return
            end

            [ALLEEG, EEG] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, CURRENTSET);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to store EEGLAB data set for ''%s''', subject);
            wtLog.popStatus();
            return
        end
        
        [success, EEG] = ioProc.loadProcessedImport(outFilesPrefix, subject);
        if ~success 
            wtProject.notifyErr([], 'Failed to load processed import for subject ''%s''', subject);
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
                [cndFileFullPath, ~, ~] = ioProc.getConditionFile(outFilesPrefix, subject, condition);

                EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_selectevent', ...
                    EEG,  'type', { condition }, 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');
                [ALLEEG, EEG, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_newset', ...
                    ALLEEG, EEG, 1, 'setname', cndSet, 'savenew', cndFileFullPath, 'gui', 'off');
                [ALLEEG, EEG, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_newset', ...
                    ALLEEG, EEG, cnd+1, 'retrieve', 1, 'study', 0);
                EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);  
            catch me
                wtLog.except(me);
                wtProject.notifyErr([], 'Failed to process/save condition ''%s'' for subject ''%s''', condition, subject);
                wtLog.popStatus(2);
                return
            end      
        end  

        wtLog.popStatus();
    end

    wtLog.popStatus();
    wtProject.notifyInf([], 'EEP -> EEGLab import completed!');
end

function success = setEpochsLimitsAndFreqFilter()
    success = false;
    wtProject = WTProject();
    EEPToEEGLabPrms = copy(wtProject.Config.EEPToEEGLab);

    if ~WTConvertGUI.defineEpochLimitsAndFreqFilter(EEPToEEGLabPrms)
        return
    end

    if ~EEPToEEGLabPrms.persist()
        wtProject.notifyErr([], 'Failed to save epocch limits and freqency filter params');
        return
    end

    wtProject.Config.EEPToEEGLab = EEPToEEGLabPrms;
    success = true;
end

% -------------------------------------------

% function wtEEPToEEGLab_(subjects,epochlimits,hpf,lpf)

% if ~ispc    
%     fprintf(2,'\nImporting ANT .cnt files only works under Microsoft� Windows!!!\n');
%     fprintf('\n');
%     return    
% end

% if ~exist('inputgui.m','file')    
%     fprintf(2,'\nPlease, start EEGLAB first!!!\n');
%     fprintf('\n');
%     return    
% end

% sla='\';

% try
%     if ~nargin
%         try
%             PROJECTPATH=evalin('base','PROJECTPATH');
%             cd (PROJECTPATH);
%             addpath(strcat(PROJECTPATH,sla,'Config'));
%             if exist('filenm.m','file') && exist('exported.m','file')
%                 filenm;
%                 exported;
%             else
%                 fprintf(2,'\nPlease, create a new project or open an existing one.\n');
%                 fprintf('\n');
%                 return
%             end
%         catch
%             fprintf(2,'\nPlease, create a new project or open an existing one.\n');
%             fprintf('\n');
%             return
%         end
%     end
% catch
%     addpath('../cfg');
%     filenm;
%     exported;
%     chan;
%     cond;
% end

% if ~nargin    
%     if ~exist('PROJECTPATH','var')
%         subj;
%     else        
%         % Select subjects interactively via GUI
%         if exist(strcat(PROJECTPATH,sla,'Config',sla,'subj.m'),'file')
            
%             parameters = { ...
%                 { 'style' 'text' 'string' 'The subject configuration file already exists!' } ...
%                 { 'style' 'text' 'string' 'Do you want to import the subjects again?' } ...
%                 { 'style' 'text' 'string' 'Ok = Yes      Cancel = No' } };
            
%             geometry = { [1] [1] [1] };
%             [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Re-import subjects?');
            
%             if ~strcmp(strhalt,'retuninginputui')
%                 return;
%             end            
%         end
        
%         subjects = { ...
%             '01' '02' '03' '04' '05' '06' '07' '08' '09' '10' '11' '12' '13' '14' '15' ...
%             '16' '17' '18' '19' '20' '21' '22' '23' '24' '25' '26' '27' '28' '29' '30' ...
%             '31' '32' '33' '34' '35' '36' '37' '38' '39' '40' '41' '42' '43' '44' '45' ...
%             '46' '47' '48' '49' '50' '51' '52' '53' '54' '55' '56' '57' '58' '59' '60' ...
%             '61' '62' '63' '64' '65' '66' '67' '68' '69' '70' '71' '72' '73' '74' '75' ...
%             '76' '77' '78' '79' '80' '81' '82' '83' '84' '85' '86' '87' '88' '89' '90' ...
%             '91' '92' '93' '94' '95' '96' '97' '98' '99' '100' '101' '102' '103' '104' '105' ...
%             '106' '107' '108' '109' '110' '111' '112' '113' '114' '115' '116' '117' '118' '119' '120' };
        
%         cd ('Import');
%         [filenames, pathname, filterindex]=uigetfile({ '*.cnt' },'Select files to import','MultiSelect','on');
%         cd ('..');
        
%         if ~pathname
%             return %quit on cancel button
%         end
        
%         if ischar(filenames)
%             filenames = {filenames};
%         end

%         subtoimport = zeros(1,length(filenames));
        
%         for i=1:length(filenames)
%             subtoimport(i) = WTUtils.str2nums(filenames{1,i}(findstr(filenames{1,i},'_')+1:findstr(filenames{1,i},'.')-1));
%         end
%         subjects = subjects(subtoimport);
        
%         % Save the subjects config file in the Config folder
%         pop_cfgfile = strcat(PROJECTPATH,sla,'Config',sla,'subj.m');
%         fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
%         fprintf(fid, 'subjects = { ');
%         for i=1:length(subjects)
%             fprintf(fid, ' ''%s'' ',char(subjects(i)));
%         end
%         fprintf(fid, ' }; ');
%         fclose(fid);
%     end    
% elseif isempty(subjects)
%     subj;    
% elseif ischar(subjects)
%     subjects={subjects};
% elseif ~iscell(subjects)
%     fprintf(2,'\nPlease, enter a subject number in the right format (e.g. wtEEPToEEGLab(''01'');) to process\n');
%     fprintf(2,'an individual subject, or edit ''subj.m'' in the ''cfg'' folder and enter nothing,\n');
%     fprintf(2,'(i.e. wtEEPToEEGLab();), to process the whole sample.\n');
%     fprintf('\n');
%     return
% end

% subjN = size(subjects,2);

% if exist('PROJECTPATH','var')
%     temp=char(exportvar);
%     InPath = strcat (PROJECTPATH,temp,sla);
%     OutPath = strcat (PROJECTPATH,sla);
% else
%     InPath = strcat (exportvar);
%     OutPath = strcat ('../');
% end

% for i = 1:subjN
%     subjDir = char (strcat (subjects(i)));
%     alreadyexistdir=strcat(OutPath,subjDir);
%     if ~exist(alreadyexistdir,'dir')
%         mkdir (OutPath, subjDir);
%     end
%     if ~nargin && exist('PROJECTPATH','var')
%         currectSubj = char (strcat (InPath,sla,filenames(i)));
%     else
%         currectSubj = char (strcat (InPath,sla,filename,subjects(i),'.cnt'));
%     end    
%     if exist('PROJECTPATH','var') && i==1 %do it only once
%         wtoolspath = which('wtEEPToEEGLab.m');
%         slashes = findstr(wtoolspath,sla);
%         chanpath = strcat(wtoolspath(1:slashes(end-1)),'chans_splines');
%         cd (chanpath);
%         % Set channels config file (*.sfp file)
%         [ChanLocFile, pathname, filterindex]=uigetfile({ '*.ced' },'Select channels location file','MultiSelect','off');        
%         if ~pathname
%             cd (PROJECTPATH);
%             return %quit on cancel button
%         end        
%         chanloc = { strcat(pathname,ChanLocFile) };
%         filetyp = { 'autodetect' };  
        
%         % Create channels array from the chan config file (*.sfp file) used
%         % to set channels to re-ref (eventually) and channels to cut
%         [a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12]=textread(chanloc{1},...
%             '%s %s %s %s %s %s %s %s %s %s %s %s','delimiter', '\t');
%         labels=(cat(1,a2(2:end),{'VEOG';'HEOG';'DIGI'}))';
%         clear a1 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12;
        
%         % Save the channels location file in the Config folder
%         pop_cfgfile = strcat(PROJECTPATH,sla,'Config',sla,'chan.m');
%         fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
%         fprintf(fid, 'chanloc = { ''%s'' };\r',ChanLocFile);
%         fprintf(fid, 'filetyp = { ''autodetect'' };\r');
        
%         % Save the spline file in the Config folder
%         [SplineFile, pathname, filterindex]=uigetfile({ '*.spl' },'Select spline file','MultiSelect','off');
        
%         if ~pathname
%             cd (PROJECTPATH);
%             return %quit on cancel button
%         end
        
%         fprintf(fid, 'splnfile = { ''%s'' };\r',SplineFile);
%         cd (PROJECTPATH);
        
%         parameters    = { { 'style' 'text' 'string' 'Do you want to re-reference? (Ok = yes)' } };
        
%         geometry = { [1] };
        
%         [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Re-referencing');
%         if strcmp(strhalt,'retuninginputui')
%             parameters    = { { 'style' 'text' 'string' 'Click Ok to re-reference to average reference,' } ...
%                 { 'style' 'text' 'string' 'click Cancel to select new reference electrodes' } };
            
%             geometry = { [1] [1] };
%             [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Select channels');
            
%             if strcmp(strhalt,'retuninginputui')
%                 % Save the re-ref info (re-ref to avr) and no new reference channels in the Config folder
%                 fprintf(fid, 'ReRef = %i;\r',1);
%                 fprintf(fid, 'newrefchan = {};\r');
%             else
%                 % Save the re-ref info (re-ref to new channels) in the Config folder
%                 fprintf(fid, 'ReRef = %i;\r',2);
%                 chanlist = listdlg('PromptString','Select channels:','SelectionMode','multiple','ListString',labels);
                
%                 if isempty(chanlist)
%                     return %quit on cancel button
%                 end
                
%                 newrefchan = labels(chanlist);
%                 % Save the new reference channels in the Config folder
%                 fprintf(fid, 'newrefchan = { ');
%                 for k=1:length(newrefchan)
%                     fprintf(fid, ' ''%s'' ',char(newrefchan(k)));
%                 end
%                 fprintf(fid, ' };\r');                
%             end            
%         else
%             % Save the re-ref info (no re-ref needed) in the Config folder
%             fprintf(fid, 'ReRef = %i;\r',0);
%         end
        
%         parameters    = { { 'style' 'text' 'string' 'Do you need to cut some channels? (Ok = yes)' } };
        
%         geometry = { [1] };
        
%         [outparam userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Cut channels');
%         if strcmp(strhalt,'retuninginputui')
%             chanlist = listdlg('PromptString','Select channels:','SelectionMode','multiple','ListString',labels);
            
%             if isempty(chanlist)
%                 return %quit on cancel button
%             end
            
%             CutChannels = labels(chanlist);
%             % Save the the channels to cut info in the Config folder
%             fprintf(fid, 'CutChannels = { ');
%             for k=1:length(CutChannels)
%                 if k<length(CutChannels)
%                     fprintf(fid, ' ''%s'', ',char(CutChannels(k)));
%                 else
%                     fprintf(fid, ' ''%s'' ',char(CutChannels(k)));
%                 end
%             end            
%             fprintf(fid, ' };');
%             fclose(fid);            
%         else            
%             fprintf(fid, 'CutChannels = {};');            
%         end
%         chan;
%         ChanLocFile = char (strcat (pathname,chanloc));
%         filetp = char (filetyp);
%     else        
%         if i==1
%             ChanLocFile = char (strcat (OutPath,'cfg/',chanloc));
%             filetp = char (filetyp);
%         end
%     end
    
%     SetFileName = char (strcat (filename,subjects(i),'.set'));
%     SetFilePath = char (strcat (OutPath,subjects(i),'/'));

%     try
%         [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
%     catch
%         fprintf(2,'\nPlease, start EEGLAB first!!!\n');
%         fprintf('\n');
%         return
%     end

%     EEG = pop_loadeep(currectSubj, 'triggerfile', 'on');
    
%     % Select conditions interactively via GUI
%     if exist('PROJECTPATH','var') && i==1 %do it only once        
%         allfields={};
%         allfields=(sort(unique(cat(1,allfields,EEG.event(1,:).type))))';        
%         if length(allfields)>1            
%             % Prompt the user to select the conditions to import from a list
%             condlist = listdlg('PromptString','Select conditions:','SelectionMode','multiple','ListString',allfields);            
%             if isempty(condlist)
%                 return %quit on cancel button
%             end            
%             allfields = allfields(condlist);            
%             for k=1:length(allfields)
%                 allfields{1,k}=num2str(WTUtils.str2nums(allfields{1,k}));
%             end            
%         end
        
%         % Save the conditions config file in the Config folder
%         pop_cfgfile = strcat(PROJECTPATH,sla,'Config',sla,'cond.m');
%         fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
%         fprintf(fid, 'conditions = { ');
%         for k=1:length(allfields)
%             fprintf(fid, ' ''%s'' ',strtrim(char(allfields(k))));
%         end
%         fprintf(fid, ' };\r');
%         fprintf(fid, 'condiff = {};');
%         fclose(fid);
        
%         cd ('Config');
%         cond;
%         cd (PROJECTPATH);
%         condN = size(conditions,2);        
%     else        
%         condN = size(conditions,2);        
%     end

%     [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', subjects, 'gui', 'off');

%     if ~isempty(CutChannels) %Cut some channels if required
%         EEG = pop_select( EEG, 'nochannel',CutChannels);
%         EEG.nbchan = size(EEG.data,1);
%     end
    
%     % SET defaultanswer0
%     defaultanswer0={'[  ]',[],[]};
%     answersN=length(defaultanswer0);
    
%     if ~nargin && i==1
%         % Load previously called parameters if existing
%         pop_cfgfile = strcat(PROJECTPATH,sla,'Config',sla,'eep2eegl_cfg.m');
%         if exist(pop_cfgfile,'file')
%             eep2eegl_cfg;
%             try
%             defaultanswer=defaultanswer;
%             defaultanswer{1,answersN};
%             catch
%                 fprintf('\n');
%                 fprintf(2, 'The eep2eegl_cfg.m file in the Config folder was created by a previous version\n');
%                 fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
%                 fprintf('\n');
%                 defaultanswer=defaultanswer0;
%             end
%         else
%             defaultanswer=defaultanswer0;
%         end
        
%         parameters    = { ...
%             { 'style' 'text'       'string' 'Epochs limits' } ...
%             { 'style' 'edit'       'string' defaultanswer{1,1} } ...
%             { 'style' 'text'       'string' 'Highpass filter' } ...
%             { 'style' 'edit'       'string' defaultanswer{1,2} }...
%             { 'style' 'text'       'string' 'Lowpass filter' } ...
%             { 'style' 'edit'       'string' defaultanswer{1,3} } };
        
%         geometry = { [1 1] [1 1]  [1 1] };
        
%         answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set parameters');
        
%         if isempty(answer)
%             return %quit on cancel button
%         end
        
%         epochlimits=WTUtils.str2nums(answer{1,1});
%         hpf=WTUtils.str2nums(answer{1,2});
%         lpf=WTUtils.str2nums(answer{1,3});
        
%         % Save the user input parameters in the Config folder
%         fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
%         fprintf(fid, 'defaultanswer={''[%s]'' ''%s'' ''%s''};',...
%             num2str(epochlimits),num2str(hpf),num2str(lpf));
%         fclose(fid);
%     end
    
%     % APPLY HighPass and LowPass filters separately. This is a workaround
%     % because sometimes MATLAB does not find a good solution for BandPass
%     % filter.
%     if ~isempty(hpf)
%         EEG = pop_eegfilt( EEG, hpf, [], [], [0]);
%     end
%     if ~isempty(lpf)
%         EEG = pop_eegfilt( EEG, [], lpf, [], [0]);
%     end
    
%     % APPLY channels location
%     EEG=pop_chanedit(EEG,  'load',{ ChanLocFile, 'filetype', filetp});
    
%     % PERFORM re-referencing
%     if  ReRef==1
%         EEG = pop_reref( EEG, [] );
%     elseif ReRef==2
%         newref=[];
%         for ch=1:length(newrefchan)
%             actualchan=newrefchan(ch);

%             labels={};

%             % FIND channels to process
%             labels=cat(1,labels,EEG.chanlocs(1,:).labels);
%             labels=labels';
%             chanindex=strfind(labels,char(actualchan));
%             chann=find(~cellfun(@isempty,chanindex));
%             chann=chann(1,1); %Avoid douplicate values (e.g. E100 to E109 when searching E10)
%             newref=cat(1,newref,chann);
%         end
%         EEG = pop_reref( EEG, newref ,'keepref','on');
%     end
    
%     % APPLY original rejection performed in EEProbe
%     if ~nargin && exist('PROJECTPATH','var')
%         rej=read_eep_rej(char(strcat(InPath,sla,filenames{1,i}(1:end-4),'fr.rej')));
%     else
%         rej=read_eep_rej(char(strcat(InPath,filename,subjects(i),'fr.rej')));
%     end
%     rej=rej./(1000/EEG.srate);
%     if rej(1,1)==0
%         rej(1,1)=1;
%     end
%     EEG=eeg_eegrej(EEG,rej);

%     if i==1
%         epochlimits=epochlimits/1000;
%     end
    
%     % EPOCH the continuous EEG ...
%     EEG = pop_epoch( EEG, {  }, epochlimits, 'epochinfo', 'yes');
%     % ... and time lock it only to selected conditions
%     EEG = pop_epoch( EEG, conditions, epochlimits, 'epochinfo', 'yes');

%     [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%     EEG = eeg_checkset( EEG );
%     EEG = pop_saveset( EEG,  'filename', SetFileName, 'filepath', SetFilePath);
%     [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%     eeglab redraw;

%     % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Epoch the dataset: one dataset for each condition%
%     % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%         EEG = pop_selectevent( EEG,  'type',{Cond}, 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');
%         [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', SetFileName, 'savenew', SetNewFile, 'gui', 'off');
%         [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, j+1, 'retrieve',1, 'study',0);
%         EEG = eeg_checkset( EEG );
%     end
%     eeglab redraw;
% end

% rehash;

% fprintf('\nDone!!!\n');
% fprintf('\n');

% end