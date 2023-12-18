function subtractch(subjects)

%subtractch.m
%Created by Eugenio Parise
%Lancaster University 2016
%Hidden function that computes subtraction between raw data of 2 channels and computes EOG
%The EOG is stored in a new channel
%EOG channel location: E126
%Note: this is ok with infants' 124 electrodes nets, but not with adults 128 electrodes nets
%WARNING: This script modifies EEGLAB .set files!

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
    PROJECTPATH=evalin('base','PROJECTPATH');
    addpath(strcat(PROJECTPATH,sla,'pop_cfg'));
    filenm;
    if exist('subj.m','file')
        subj;
        cond;
    else
        fprintf(2,'\nFile-list of imported subjects not found!!!');
        fprintf(2,'\nPlease, import the subjects first.\n');
        fprintf('\n');
        return
    end
catch
    if exist('../cfg','dir')
        addpath('../cfg');
        filenm;
        cond;
    else
        fprintf(2,'\nProject not found!!!\n');
        fprintf('\n');
        return
    end
end

if nargin
    if isempty(subjects)
        subj;
    elseif ischar(subjects)
        subjects={subjects};
    elseif ~iscell(subjects)
        fprintf(2,'\nPlease, enter a subject number in the right format (e.g. wtPerformCWT(''01'',...);) to process\n');
        fprintf(2,'an individual subject, or edit ''subj.m'' in the ''cfg'' folder and enter empty value,\n');
        fprintf(2,'(i.e. wtPerformCWT([],...);), to process the whole sample.\n');
        fprintf('\n');
        return
    end
end

if ~nargin
    
    if length(subjects)>1
        
        %Select subjects interactively via GUI
        [subjlist, ok] = listdlg('PromptString','Select subjects to transform:','SelectionMode','multiple','ListString',subjects);
        
        if ~ok
            return %quit on cancel button
        end
        
        subjects = subjects(subjlist);
        
    end
    
    if length(conditions)>1
        
        %Select conditions interactively via GUI
        [condlist, ok] = listdlg('PromptString','Select conditions to transform:','SelectionMode','multiple','ListString',conditions,'ListSize',[180 300]);
        
        if ~ok
            return %quit on cancel button
        end
        
        conditions = conditions(condlist);
        
    end
        
    %Load first subject to get EEG.chanlocs
    if exist('PROJECTPATH','var')
        CommonPath = strcat (PROJECTPATH,'/');
    else
        CommonPath = strcat ('../');
    end
    currectSubj = char (strcat (filename,subjects(1),'_',conditions(1),'.set'));
    InPath = char (strcat (CommonPath,subjects(1),'/'));
    EEG = pop_loadset( 'filename', currectSubj, 'filepath', InPath);
    
end

subjN=length(subjects);
condN = size(conditions,2);

%FIND channels to process from gui
chanlocs=EEG.chanlocs;
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

if chanN ~= 2
    
    fprintf('\nPlease select 2 channels!\n');
    fprintf('\n');
    
    return
end

newchlabel=strcat('E',num2str(chan(1)),'-','E',num2str(chan(2)));

for i = 1:subjN
    for j = 1:condN
        
        currectSubj = char (strcat (filename,subjects(i),'_',conditions(j),'.set'));
        InPath = char (strcat (CommonPath,subjects(i),'/'));
        
        try
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        catch
            fprintf(2,'\nPlease, start EEGLAB first!!!\n');
            fprintf('\n');
            return
        end
        
        EEG = pop_loadset( 'filename', currectSubj, 'filepath', InPath);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        EEG = eeg_checkset( EEG );
        
        EOG=EEG.data(chan(1),:,:)-EEG.data(chan(2),:,:); %Create EOG
        EEG.data=[EEG.data;EOG]; %Append EOG
        EEG.nbchan=EEG.nbchan+1; %Fix channels N
        %Add EOG channel location
        EEG.chanlocs(1,end+1).labels=newchlabel;
        EEG.chanlocs(1,end).theta=29.3795;
        EEG.chanlocs(1,end).radius=0.7253;
        EEG.chanlocs(1,end).X=6.6492;
        EEG.chanlocs(1,end).Y=-3.7435;
        EEG.chanlocs(1,end).Z=-6.5302;
        EEG.chanlocs(1,end).sph_theta=-29.3795;
        EEG.chanlocs(1,end).sph_phi=-40.5569;
        EEG.chanlocs(1,end).sph_radius=10.0434;
        EEG.chanlocs(1,end).type='';
        EEG.chanlocs(1,end).urchan=128;
        EEG.chanlocs(1,end).ref='average';
        
        Cond = char (conditions(j));
        SetFileName = char (strcat (filename,subjects(i),'_',conditions(j)));
        SetNewFile = char (strcat(InPath,SetFileName,'.set'));
        
        EEG = pop_selectevent( EEG,  'type',{Cond}, 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', SetFileName, 'savenew', SetNewFile, 'gui', 'off');
        
    end
    
    eeglab redraw;
    
end

fprintf('\nDone!!!\n');
fprintf('\n');

end