function WT=baseline_chop(subjects,tMin,tMax,bsMin,bsMax,logtransform,nobaseline,varargin)
%baseline_chop.m
%Created by Eugenio Parise
%CDC CEU 2010 - 2011
%Function to baseline correct and chop ERPWAVELABv1.1 compatible data files.
%To set this script to process the whole final sample of subjects in a study,
%edit 'subj.m' in the 'cfg' folder and digit baseline_chop([],...); ([]=empty).
%Add 'evok' as last argument to compute baseline correction of evoked
%oscillations (of course, if they have been previously computed).
%
%Usage:
%
%average(subject,timewindow begin,timewindow end,baseline begin,baseline end,higher...
%frequency,lower frequency,log-transformation,no baseline correction);
%
%baseline_chop('01',-200,1200,-200,0,0,0);
%baseline_chop([],-200,1200,-200,0,1,0);
%baseline_chop([],-200,1200,[],[],0,1,'evok');

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
    addpath(strcat(PROJECTPATH,'/pop_cfg'));
    filenm;
    if exist('subjgrand.m','file') && exist('tf_cmor_cfg.m','file')
        subjgrand;
        condgrand;
    else
        fprintf(2,'\nPlease, perform wavelet transformation first!!!\n');
        fprintf('\n');
        return
    end
catch
    if exist('../cfg','dir')
        addpath('../cfg');
        filenm;
        condgrand;
    else
        fprintf(2,'\nProject not found!!!\n');
        fprintf('\n');
        return
    end

    if isempty(subjects)
        subj;
    elseif ischar(subjects)
        subjects={subjects};
    elseif ~iscell(subjects)
        fprintf(2,'\nPlease, enter a subject number in the right format, e.g. baseline_chop(''01'',...);, to process\n');
        fprintf(2,'an individual subject, or edit ''subj.m'' in the ''cfg'' folder and enter baseline_chop([],...);,\n');
        fprintf(2,'to process the whole sample.\n');
        fprintf('\n');
        return
    end
    
end

if ~nargin
    
    if length(subjects)>1
        
        %Select subjects interactively via GUI
        [subjlist, ok] = listdlg('PromptString','Select subjects:','SelectionMode','multiple','ListString',subjects);
        
        if ~ok
            return %quit on cancel button
        end
        
        subjects = subjects(subjlist);
        
    end
    
    if length(conditions)>1
        
        %Select conditions interactively via GUI
        [condlist, ok] = listdlg('PromptString','Select conditions:','SelectionMode','multiple','ListString',conditions);
        
        if ~ok
            return %quit on cancel button
        end
        
        conditions = conditions(condlist);
        
    end
    
    %FLAG to tell check_evok_log.m that the caller workspace is
    %baseline_chop.m
    baseline_chop_flag=1;
    
    %CHECK if the data have been already log-transformed and check Evok
    [enable_uV logFlag last_tfcmor]=check_evok_log(PROJECTPATH);
    
    %SET defaultanswer0
    defaultanswer0={[],[],[],[],0,0,last_tfcmor};
    
    mandatoryanswersN=length(defaultanswer0);
    
    %Load previously called parameters if existing
    pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'baseline_chop_cfg.m');
    if exist(pop_cfgfile,'file')
        try
            baseline_chop_cfg;
            defaultanswer=defaultanswer;
            defaultanswer{1,mandatoryanswersN};
            defaultanswer{1,mandatoryanswersN}=last_tfcmor;
        catch
            fprintf('\n');
            fprintf(2, 'The baseline_chop_cfg.m file in the pop_cfg folder was created by a previos verion\n');
            fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
            fprintf('\n');
            defaultanswer=defaultanswer0;
        end
    else
        defaultanswer=defaultanswer0;
    end
    
    %Set baseline limits' boxes on or off (default on)
    if defaultanswer{1,6}
        enableBs='off';
    else
        enableBs='on';
    end
    
    cb_enableBs   = [ ...
        'set(findobj(gcbf, ''userdata'', ''NoBC''),' ...
        '''enable'',' ...
        'fastif(get(gcbo, ''value''), ''off'', ''on''));' ];
    
    parameters    = { ...
        { 'style' 'text'       'string' 'Chop Ends:              Left' } ...
        { 'style' 'edit'       'string' defaultanswer{1,1} } ...
        { 'style' 'text'       'string' 'Right' } ...
        { 'style' 'edit'       'string' defaultanswer{1,2} } ...
        { 'style' 'text'       'string' 'Correct Baseline:    From' } ...
        { 'style' 'edit'       'string' defaultanswer{1,3} 'userdata' 'NoBC' 'enable' enableBs } ...
        { 'style' 'text'       'string' 'To' } ...
        { 'style' 'edit'       'string' defaultanswer{1,4} 'userdata' 'NoBC' 'enable' enableBs } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'text'       'string' '' } ...
        { 'style' 'checkbox'   'value' defaultanswer{1,5}   'string' 'Log10-Transform' 'enable' enable_uV } ...
        { 'style' 'checkbox'   'value' defaultanswer{1,6}   'string' 'No Baseline Correction', 'callback', cb_enableBs } ...
        { 'style' 'checkbox'   'value' defaultanswer{1,7}   'string' 'Evoked Oscillations' } };
        %{ 'style' 'text'       'string' '' } };
    
    geometry = { [1 0.5 0.5 0.5] [1 0.5 0.5 0.5] [1 1 1 1] [1.5 1.5 1.5] };
    
    answer = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Set baseline and edges chopping parameters');
    
    if isempty(answer)
        return %quit on cancel button
    end
    
    tMin=str2num(answer{1,1});
    tMax=str2num(answer{1,2});
    bsMin=str2num(answer{1,3});
    bsMax=str2num(answer{1,4});
    logtransform=answer{1,5};
    nobaseline=answer{1,6};
    if nobaseline
        bsMin=[];
        bsMax=[];
    end
    evok=answer{1,7};
    if evok
        varargin='evok';
    end
    
end

%Check the input is correct
if tMin > tMax
    fprintf(2,'\nThe time window is  not valid!!!\n');
    fprintf('\n');
    return
end
if ~nobaseline && (isempty(bsMin) || isempty(bsMax))
    fprintf(2,'\nThe baseline window is not valid!!!\n');
    fprintf('\n');
    return
elseif bsMin > bsMax
    fprintf(2,'\nThe baseline window is not valid!!!\n');
    fprintf('\n');
    return
end

if exist('PROJECTPATH','var')
    CommonPath = strcat (PROJECTPATH,'/Wavelets/');
else
    CommonPath = strcat ('../Wavelets/');
end

if length(varargin)==1
    varargin=varargin{1};
end

if isempty(varargin)
    
    measure=strcat('-avWT.mat');
    
elseif strcmp(varargin,'evok')
    
    measure=strcat('-evWT.mat');
    
elseif ~strcmp(varargin,'evok')
    
    fprintf(2,'\nThe measure %s is not present in the subjects folders!!!\n',varargin);
    fprintf(2,'If you want to compute baseline correction of evoked oscillations, please type ''evok'' as last argument.\n');
    fprintf(2,'Type nothing after the tMax argument if you want to compute baseline correction');
    fprintf(2,'of total-induced oscillations.\n');
    fprintf('\n');
    return
    
end

%load the first dataset to take information from the matrixs 'Fa' and 'tim'
%(see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
firstSubj = strcat (CommonPath,conditions(1),'/',subjects(1),'_',conditions(1),measure);
load (char(firstSubj));

timeRes = tim(2) - tim(1); %find time resolution

%Adjust time limits according to the data
if tMin<min(tim)
    fprintf(2,'\n%i ms is out of boundaries!!!',tMin);
    fprintf(2,'\nPlease choose a value >= %i ms\n',min(tim));
    fprintf('\n');
    return
else
    tMin=tMin-mod(tMin,timeRes);
    while ~any(tim==tMin)
        tMin=tMin+1;
    end
end
if tMax>max(tim)
    fprintf(2,'\n%i ms is out of boundaries!!!',tMax);
    fprintf(2,'\nPlease choose a value <= %i ms\n',max(tim));
    fprintf('\n');
    return
else
    tMax=tMax-mod(tMax,timeRes);
    while ~any(tim==tMax)
        tMax=tMax+1;
    end
end

if ~nobaseline %Baseline correction has been requested
    
    if bsMin<tMin
        fprintf(2,'\n%i ms is out of boundaries!!!',bsMin);
        fprintf(2,'\nPlease choose a value >= %i ms\n',tMin);
        fprintf('\n');
        return
    else
        bsMin=bsMin-mod(bsMin,timeRes);
        while ~any(tim==bsMin)
            bsMin=bsMin+1;
        end
    end
    if bsMax>tMax
        fprintf(2,'\n%i ms is out of boundaries!!!',bsMax);
        fprintf(2,'\nPlease choose a value <= %i ms\n',tMax);
        fprintf('\n');
        return
    else
        bsMax=bsMax-mod(bsMax,timeRes);
        while ~any(tim==bsMax)
            bsMax=bsMax+1;
        end
    end
    
end

%Save the user input parameters in the pop_cfg folder
if ~nargin
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'defaultanswer={ ''%s'' ''%s'' ''%s'' ''%s'' %i %i %i };',...
        num2str(tMin),num2str(tMax),num2str(bsMin),num2str(bsMax),logtransform,nobaseline,evok);
    fclose(fid);
    
    rehash;
    
end

%SET parameters
Latencies=tMin:timeRes:tMax;
latN=size(Latencies,2);
Frequencies=Fa;
frN=size(Frequencies,2);

fprintf('\n');
fprintf('Baseline correction and edges chopping.\n');
fprintf('Please wait...\n');
fprintf('\n');

%%%%%%%%%%%%%%%%%%%
e1=find(tim==tMin);
e2=find(tim==tMax);

f1=min(Fa);
f2=max(Fa);

if logtransform
    %warning('off','last'); %Prevent "Warning: Log of zero"
    fprintf(2,'Data will be log-transformed before baseline correction!!!\n');
    fprintf('\n');
end

if nobaseline
    fprintf(2,'No baseline correction will be performed!!!\n');
    fprintf('\n');
else
    b1=find(tim==bsMin);
    b2=find(tim==bsMax);
end

subjN = size(subjects,2);
condN = size(conditions,2);

for s = 1:subjN
    
    for cn = 1:condN

        fprintf('Processing: %s\n', char(strcat(subjects(s),'_',conditions(cn),measure)));
        
        currectSubj = strcat (CommonPath,conditions(cn),'/',subjects(s),'_',conditions(cn),measure);
        load (char(currectSubj));
        
        if ~logtransform %No log transformation requested
            awt=WT(:,1:length(Fa),:);            
        else %Log transform (10-based) the data before baseline correction            
            awt=log10(WT(:,1:length(Fa),:));            
        end
        
        if nobaseline %No baseline correction has been requested            
            subjmatrix = awt(:,:,e1:e2);            
        else            
            bv=mean(awt(:,:,b1:b2),3);            
            %New baseline correction: 4-5 times faster than the code above.
            base=repmat(bv,[1,1,length(e1:e2)]);           
            subjmatrix = awt(:,:,e1:e2) - base;           
        end
        
        %In agreement to ERPWAVELAB file structure:
        WT=subjmatrix;
        tim=Latencies;
        Fa=Frequencies;
        
        %Save the file in the subject folder and...
        OutFileName = char (strcat(subjects(s),'_',conditions(cn),'_bc',measure));
        if exist('PROJECTPATH','var')
            outPath = strcat (PROJECTPATH,'/',char(subjects(s)),'/',OutFileName);
        else
            outPath = strcat ('../',char(subjects(s)),'/',OutFileName);
        end
        save (outPath, 'WT', 'chanlocs', 'Fa', 'Fs', 'nepoch', 'tim', 'wavetyp');
        
        %... inform the user
        fprintf('File %s successfully saved in subject %s folder!!!\n',OutFileName,char(subjects(s)));
        fprintf('\n');
        
    end
    
end

end