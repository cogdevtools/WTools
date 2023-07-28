function difference(subjects,varargin)
%difference.m
%Created by Eugenio Parise
%CDC CEU 2010 - 2011
%Calculate the difference between two conditions (e.g. C1-C2 C3-C4);
%Store the resulting files in the subject folder.
%IMPORTANT! Define the condition you want to subtract by editing the variable 'condiff'
%in the file 'cond.m' ('cfg' folder).
%To set this script to process the whole final sample of subjects in a study,
%edit 'subj.m' in the 'cfg' folder and  digit difference([]) at the console prompt.
%Add 'evok' as last argument to compute conditions difference of evoked
%oscillations (of course, if they have been previously computed).
%
%Usage:
%
%difference('01');
%difference([]);
%%difference([],'evok');

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
        fprintf(2,'\nPlease, enter a subject number in the right format, e.g. difference(''01'');, to process\n');
        fprintf(2,'an individual subject, or edit ''subj.m'' in the ''cfg'' folder and enter [],\n');
        fprintf(2,'(i.e. difference([]);), to process the whole sample.\n');
        fprintf('\n');
        return
    end
    
end

try
    condgrand;
    if length(conditions)<2
        fprintf(2,'\nOnly one condition!!!\n');
        fprintf('\n');
        return
    end
catch
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
    
    %CHECK Evok
    [enable_uV logFlag last_tfcmor]=check_evok_log(sla, PROJECTPATH);
    
    %SET defaultanswer0
    defaultanswer0={1,1,1,0,last_tfcmor};    
    answersN=length(defaultanswer0);
    
    %Load previously called parameters if existing
    pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'difference_cfg.m');
    if exist(pop_cfgfile,'file')
        difference_cfg;
        try
        defaultanswer=defaultanswer;
        defaultanswer{1,answersN};
        defaultanswer{1,answersN}=last_tfcmor;
        catch
            fprintf('\n');
            fprintf(2, 'The difference_cfg.m file in the pop_cfg folder was created by a previous version\n');
            fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
            fprintf('\n');
            defaultanswer=defaultanswer0;
        end
    else
        defaultanswer=defaultanswer0;
    end
    
    %Assign conditions and condiff to the base workspace to prevent
    %errors of the gui
    assignin('base','conditions',conditions);
    assignin('base','condiff',condiff);
    
    cb_list1 = [ ...
        'tmpdat = get(gcbf, ''userdata'');' ...
        'tmpval1 = get(findobj(gcbf, ''tag'', ''list1''), ''value'');' ...
        'tmppos1 = conditions(tmpval1);' ];
    
    cb_list2 = [ ...
        'tmpdat = get(gcbf, ''userdata'');' ...
        'tmpval2 = get(findobj(gcbf, ''tag'', ''list2''), ''value'');' ...
        'tmppos2 = conditions(tmpval2);' ];
    
    cb_list3 = [ ...
        'tmpdat = get(gcbf, ''userdata'');' ...
        'tmpval3 = get(findobj(gcbf, ''tag'', ''list3''), ''value'');' ...
        'tmppos3 = condiff(tmpval3);' ];
    
    cb_pair = [ ...
        'if ~exist(''tmppos1'',''var''),' ...
        'tmppos1 = [];' ...
        'end;' ...
        'if ~exist(''tmppos2'',''var''),' ...
        'tmppos2 = [];' ...
        'end;' ...
        'if isempty(tmppos1) && isempty(tmppos2),' ...
        'if sum(ismember(condiff,strcat(conditions{1},''-'',conditions{1})))>0' ...
        'fprintf(2,''\nDifference already set!!!\n'');' ...
        'else;' ...
        'condiff=cat(2,condiff,strcat(conditions{1},''-'',conditions{1}));' ...
        'set(findobj(gcbf, ''tag'', ''list3''), ''string'', condiff);' ...
        'end;' ...
        'elseif ~isempty(tmppos1) && isempty(tmppos2),' ...
        'if sum(ismember(condiff,strcat(tmppos1{1},''-'',conditions{1})))>0' ...
        'fprintf(2,''\nDifference already set!!!\n'');' ...
        'else;' ...
        'condiff=cat(2,condiff,strcat(tmppos1{1},''-'',conditions{1}));' ...
        'set(findobj(gcbf, ''tag'', ''list3''), ''string'', condiff);' ...
        'end;' ...
        'elseif isempty(tmppos1) && ~isempty(tmppos2),' ...
        'if sum(ismember(condiff,strcat(conditions{1},''-'',tmppos2{1})))>0' ...
        'fprintf(2,''\nDifference already set!!!\n'');' ...
        'else;' ...
        'condiff=cat(2,condiff,strcat(conditions{1},''-'',tmppos2{1}));' ...
        'set(findobj(gcbf, ''tag'', ''list3''), ''string'', condiff);' ...
        'end;' ...
        'elseif ~isempty(tmppos1) && ~isempty(tmppos2),' ...
        'if sum(ismember(condiff,strcat(tmppos1{1},''-'',tmppos2{1})))>0' ...
        'fprintf(2,''\nDifference already set!!!\n'');' ...
        'else;' ...
        'condiff=cat(2,condiff,strcat(tmppos1{1},''-'',tmppos2{1}));' ...
        'set(findobj(gcbf, ''tag'', ''list3''), ''string'', condiff);' ...
        'end;' ...
        'end;' ];
    
    cb_del = [ ...
        'if isempty(condiff),' ...
        'fprintf(2,''\nNo difference to delete!!!\n'');' ...
        'else;' ...
        'tmpdat = get(gcbf, ''userdata'');' ...
        'tmpval3 = get(findobj(gcbf, ''tag'', ''list3''), ''value'');' ...
        'condiff(tmpval3)=[];' ...
        'set(findobj(gcbf, ''tag'', ''list3''), ''Value'', 1);' ...
        'set(findobj(gcbf, ''tag'', ''list3''), ''string'', condiff);' ...
        'end;' ];
    
    geometry = { [4 4 2 4] [4 4 2 4] };
    geomvert = [ min(max(length(conditions)), 10) 1 ];
    
    parameters = { ...
        { 'Style'   'listbox'    'tag'      'list1'             'string'        conditions  'value' defaultanswer{1,1} 'callback' cb_list1 }, ...
        { 'Style'   'listbox'    'tag'      'list2'             'string'        conditions  'value' defaultanswer{1,2} 'callback' cb_list2 }, ...
        { 'Style'   'pushbutton' 'string'   '=>'                'callback'      cb_pair } ...
        { 'Style'   'listbox'    'tag'      'list3'             'string'        condiff     'value' defaultanswer{1,3} 'callback' cb_list3 } ...
        { 'style'   'checkbox'   'string'   'Log10-Transformed data'            'value'   logFlag 'enable' 'off' } ...
        { 'style'   'checkbox'   'string'   'Evoked Oscillations'               'value'   defaultanswer{1,5} } ...
        { 'style'   'text'       'string'   '' } ...
        { 'Style'   'pushbutton' 'string'   'Delete difference' 'callback'      cb_del } };
    
    [answer userdat strhalt] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', parameters, 'title', 'Define differences to compute' );
    
    %import condiff from the base workspace
    condiff = evalin('base','condiff');
    
    evalin('base', 'clear condiff conditions cb_list1 cb_list2 cb_list3 cb_pair cb_del geometry geomvert parameters tmpdat tmppos1 tmppos2 tmppos3 tmpval1 tmpval2 tmpval3');
    
    if ~strcmp(strhalt,'retuninginputui') || isempty(answer) || isempty(condiff)
        return %quit on cancel button or no difference set
    end
    
    list1=answer{1,1};
    list2=answer{1,2};
    difflist=answer{1,3};
    diffLog=answer{1,4};
    evok=answer{1,5};
    if evok
        varargin='evok';
    end
    
    %On Ok press
    if strcmp(strhalt,'retuninginputui')
        
        %Save the condiff cell array in the pop_cfg folder
        pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'condgrand.m');
        fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
        fprintf(fid, 'conditions = { ');
        for i=1:length(conditions)
            fprintf(fid, ' ''%s'' ',char(conditions(i)));
        end
        fprintf(fid, ' };\r\n');
        fprintf(fid, 'condiff = { ');
        for i=1:length(condiff)
            fprintf(fid, ' ''%s'' ',char(condiff(i)));
        end
        fprintf(fid, ' }; ');
        fclose(fid);
        
        %Save the user input parameters in the pop_cfg folder
        pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'difference_cfg.m');
        fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
        fprintf(fid, 'defaultanswer={ %i %i %i %i %i };',...
            list1, list2, difflist, diffLog, evok);
        fclose(fid);
        
        rehash;
        
    end
    
end

subjN = length(subjects);
condN = length(conditions);
condiffN = length(condiff);

if exist('PROJECTPATH','var')
    CommonPath = strcat (PROJECTPATH,'/');
else
    CommonPath = strcat ('../');
end

condstosubtract = [];

%FIND the conditions to subtract and put them in condstosubtract array
for i=1:condiffN
    j=1;
    temp = zeros(1,2);
    while j<=condN
        [matchstart,matchend,tokenindices,matchstring] = regexp(condiff(i),conditions(j));
        if ~isempty(matchstring{1,1})
            
            minuspos=strfind(char(condiff(i)),'-');
            condpos=strfind(char(condiff(i)),char(matchstring{1,1}{1,1}));
            
            %condpos is 1 in length = 1 match found in the condition
            %difference array.
            if length(condpos)==1
                if ~(condpos(1)==1 || condpos(1)==minuspos+1) %fake match found
                    matchstring{1,1}=[];
                end
            end
            
            %condpos is 2 in length = 2 matchs found in the condition
            %difference array.
            if length(condpos)>1
                if condpos(1)==1 && condpos(2)==minuspos+1
                    %do nothing: the user want to subtract a condition from
                    %itself
                elseif condpos(1)~=1 && condpos(2)~=minuspos+1 %fake match found
                    matchstring{1,1}=[];
                elseif condpos(1)~=1
                    condpos=condpos(2); %this is the only true match
                    matchstring{1,1}={conditions(j)};
                elseif condpos(1)==1
                    condpos=condpos(1); %this is the only true match
                    matchstring{1,1}={conditions(j)};
                end
            end
            
        end
        
        %Both conditions not found in the difference string
        if isempty(matchstring{1,1}) && temp(1)==0 && temp(2)==0 && j==condN
            fprintf(2,'\nBoth conditions in the pair %s do not match any experimental condition!\n', char(condiff(i)));
            fprintf(2,'Please, edit cond.m in the cfg folder and revise your setting.\n');
            fprintf('\n');
            return
            
            %One condition found in the difference string
        elseif ~isempty(matchstring{1,1}) && length(matchstring{1,1})==1
            actualcond=strfind(conditions,char(matchstring{1,1}{1,1}));
            for k=1:length(actualcond)
                if ~isempty(actualcond{k}) && actualcond{k}>1
                    actualcond{k}=[];
                end
            end
            notemptyCells = ~cellfun(@isempty,actualcond);
            if minuspos<condpos
                temp(2)=find(notemptyCells==1);
            else
                temp(1)=find(notemptyCells==1);
            end
            if temp(1)~=0 && temp(2)~=0
                j=condN;
            end
            
            %Two equal conditions found in the difference string
        elseif ~isempty(matchstring{1,1}) && length(matchstring{1,1})==2
            actualcond=strfind(conditions,char(matchstring{1,1}{1,1}));
            for k=1:length(actualcond)
                if ~isempty(actualcond{k}) && actualcond{k}>1
                    actualcond{k}=[];
                end
            end
            notemptyCells = ~cellfun(@isempty,actualcond);
            temp(:)=find(notemptyCells==1);
            j=condN;
            fprintf(2,'\nWarning! Condition %s will be subtracted from itself!\n', char(conditions(temp(1))));
            fprintf(2,'Cosider to edit cond.m in the cfg folder and revise your setting.\n');
            fprintf('\n');
        end
        
        j=j+1;
        
    end
    
    %One condition not found in the difference string
    if temp(1)==0 || temp(2)==0
        fprintf(2,'\nOne condition in the pair %s does not match any experimental condition!\n', char(condiff(i)));
        fprintf(2,'Please, edit cond.m in the cfg folder and revise your setting.\n');
        fprintf('\n');
        return
    else
        condstosubtract=cat(2,condstosubtract,temp);
    end
    
end

condstosubtractN=length(condstosubtract);

fprintf('\n');
fprintf('Computing difference between conditions.\n');
fprintf('Please wait...\n');
fprintf('\n');

if length(varargin)==1
    varargin=varargin{1};
end

if isempty(varargin)    
    measure=strcat('_bc-avWT.mat');    
elseif strcmp(varargin,'evok')    
    measure=strcat('_bc-evWT.mat');    
elseif ~strcmp(varargin,'evok')    
    fprintf(2,'\nThe measure %s is not present in the subjects folders!!!\n',varargin);
    fprintf(2,'If you want to compute conditions difference of evoked oscillations, please type ''evok'' as last argument.\n');
    fprintf(2,'Type nothing after the subjects argument if you want to compute conditions difference');
    fprintf(2,'of total-induced oscillations.\n');
    fprintf('\n');
    return    
end

for s=1:subjN
    correction=0;
    for cn=1:condstosubtractN/2
        
        %load first datasets
        dataset = char(strcat (CommonPath,subjects(s),'/',subjects(s),'_',conditions(condstosubtract(cn+correction)),measure));
        load (dataset);
        
        %Store WT of the current dataset
        temp=WT;
        
        %load second datasets
        dataset = char(strcat (CommonPath,subjects(s),'/',subjects(s),'_',conditions(condstosubtract(cn+correction+1)),measure));
        load (dataset);
        
        %Calculate difference
        WT=temp-WT;
        
        %Save the difference in the grand folder
        C1=char(conditions(condstosubtract(cn+correction)));
        C2=char(conditions(condstosubtract(cn+correction+1)));
        OutFileName = char (strcat(subjects(s),'/',subjects(s),'_',C1,'-',C2,measure));
        outPath = char (strcat (CommonPath,OutFileName));
        save (outPath, 'WT', 'chanlocs', 'Fa', 'Fs', 'nepoch', 'tim', 'wavetyp');
        
        correction=correction+1;
        
        %... inform the user
        fprintf('Difference %s-%s successfully saved in subject %s folder!!!\n',C1,C2,char(subjects(s)));
        fprintf('\n');
        
    end
end