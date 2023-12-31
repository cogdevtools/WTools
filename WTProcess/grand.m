function grand(compSS,varargin)
%grand.m
%Created by Eugenio Parise
%CDC CEU 2010 - 2011
%Function to calculate the grand average matrix by condition from baseline
%corrected and chopped files (individual subjects files).
%This script is set to process the whole final sample of subjects of the study.
%Add 'evok' as argument to compute the grand average of evoked
%oscillations (of course, if they have been previously computed).
%
%Usage:
%
%grand(); to compute grand average of previously computed total-induced
%oscillations.
%grand('evok'); to compute grand average of previously computed evoked
%oscillations.
%

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
        
        %Ask the user whether new subjects have been added and processed to the
        %already existing project
        parameters = { ...
            { 'style' 'text'       'string' 'Have you added any new subject to the project?' } ...
            { 'style' 'text'       'string' '(Ok = Yes)' } };
        
        geometry = { [1] [1] };
        [answer userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Grand average');
        
        if strcmp(strhalt,'retuninginputui')
            if exist('subjects','var') %Necessary to make subjects working in the function workspace
                subjN = size(subjects,2);
            else
                subjgrand; %In case the user quit the subjrebuild module after calling it
            end
        else
            subjgrand;
        end        
        condgrand;
        condgrands=cat(2,conditions,condiff);        
    else
        assignin('caller','subjects',subjects);
        fprintf(2,'\nPlease, perform wavelet transformation first!!!\n');
        fprintf('\n');
        return
    end
    if ~exist('baseline_chop_cfg.m','file')
        assignin('caller','subjects',subjects);
        fprintf(2,'\nPlease, perform edges chopping and baseline correction first!!!\n');
        fprintf('\n');
        return
    end
catch
    if exist('../cfg','dir')
        addpath('../cfg');
        subjgrand;
        condgrand;
        condgrands=cat(2,conditions,condiff);
    else
        fprintf(2,'\nProject not found!!!\n');
        fprintf('\n');
        return
    end
end

subjN = size(subjects,2);
if subjN<2
    assignin('caller','subjects',subjects);
    fprintf(2,'\nOnly one subject entered!!!\n');
    fprintf('\n');
    return
end

if ~nargin
    
    %CHECK if the data have been already log-transformed and check Evok
    [logFlag, ~, last_bschop] = wtCheckEvokLog();
    enable_uV = WTUtils.ifThenElseSet(logFlag, 'off', 'on');

    %SET defaultanswer0
    defaultanswer0={1,1,0,last_bschop};
    mandatoryanswersN=length(defaultanswer0);
    
    %Load previously called parameters if existing
    pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'grand_cfg.m');
    if exist(pop_cfgfile,'file')
        grand_cfg;
        try
            defaultanswer=defaultanswer;
            defaultanswer{1,mandatoryanswersN};
            defaultanswer{1,mandatoryanswersN}=last_bschop;
        catch
            fprintf('\n');
            fprintf(2, 'The grand_cfg.m file in the pop_cfg folder was created by a previous version\n');
            fprintf(2, 'of WTools. It will be updated to the most recent version and overwritten.');
            fprintf('\n');
            defaultanswer=defaultanswer0;
        end
    else
        defaultanswer=defaultanswer0;
    end
    
    %Ask the user to select a subset of all transformed subjects
    parameters = { ...
        { 'style' 'checkbox'   'string' 'Use all transformed subjects?'         'value'   defaultanswer{1} } ...
        { 'style' 'checkbox'   'string' 'Compute SS matrix for SE plotting'     'value'   defaultanswer{2} } ...
        { 'style' 'checkbox'   'string' 'Log10-Transformed data'                'value'   logFlag 'enable' 'off' } ...
        { 'style' 'checkbox'   'string' 'Evoked Oscillations'                   'value'   defaultanswer{4} } };
    
    geometry = { [1] [1] [1] [1] };

    [answer userdat strhalt] = inputgui( 'geometry', geometry, 'uilist', parameters,'title', 'Grand average');
    
    if isempty(answer)
        %Assign the variable subjects to the caller workspace
        assignin('caller','subjects',subjects);
        return %quit on cancel button
    end
    
    allsubj=answer{1,1};
    compSS=answer{1,2};
    grandLog=answer{1,3};
    evok=answer{1,4};
    if evok
        varargin='evok';
    end
    
    %Save the user input parameters in the pop_cfg folder
    fid = fopen(pop_cfgfile, 'wt'); %Overwrite preexisting file with the same name
    fprintf(fid, 'defaultanswer={ %i %i %i %i };',...
        allsubj,compSS,grandLog,evok);
    fclose(fid);

    rehash;
    
    %Interactively select a subset of subjects if requested
    if ~allsubj        
        if length(subjects)>1           
            %Select subjects interactively via GUI
            [subjlist, ok] = listdlg('PromptString','Select subjects:','SelectionMode','multiple','ListString',subjects);            
            if ~ok
                assignin('caller','subjects',subjects);
                return %quit on cancel button
            end           
            subjects = subjects(subjlist);
            subjN = size(subjects,2);            
        end        
    end
    
    if length(condgrands)>1       
        %Select conditions interactively via GUI
        [condlist, ok] = listdlg('PromptString','Select conditions:','SelectionMode','multiple','ListString',condgrands);        
        if ~ok
            assignin('caller','subjects',subjects);
            return %quit on cancel button
        end        
        condgrands = condgrands(condlist);        
    end    
end

condN = size(condgrands,2);

if exist('PROJECTPATH','var')
    CommonPath = strcat (PROJECTPATH,'/');
    alreadyexistdir=strcat(CommonPath,'grand');
    if ~exist(alreadyexistdir,'dir')
        mkdir(PROJECTPATH,'grand');
    end
else
    CommonPath = strcat ('../');
    alreadyexistdir=strcat(CommonPath,'grand');
    if ~exist(alreadyexistdir,'dir')
        mkdir('../','grand');
    end
end

if length(varargin)==1
    varargin=varargin{1};
end

if isempty(varargin)    
    measure=strcat('_bc-avWT');    
elseif strcmp(varargin,'evok')    
    measure=strcat('_bc-evWT');    
elseif ~strcmp(varargin,'evok')    
    assignin('caller','subjects',subjects);
    fprintf(2,'\nThe measure %s is not present in the subjects folders!!!\n',varargin);
    fprintf(2,'If you want to compute the grand average of evoked oscillations, please type ''evok'' as argument.\n');
    fprintf(2,'Type nothing if you want to compute the grand average of total-induced oscillations.\n');
    fprintf('\n');
    return    
end

if compSS
    measureSS=strcat(measure,'.ss');
    measure=strcat(measure,'.mat');
else
    measure=strcat(measure,'.mat');
end

%load the first dataset to take information from the matrix 'WT'
%(see ERPWAVELAB file structure: http://erpwavelab.org/tutorial/index_files/Page496.htm)
firstSubj = strcat (CommonPath,subjects(1),'/',subjects(1),'_',condgrands(1),measure);
load (char(firstSubj));

fprintf('\n');
fprintf('Computing grand average.\n');
fprintf('Please wait...\n');
fprintf('\n');

%%%%%%%%%%%%%%%%%%%

if compSS %Compute SS matrix as well...
    
    for cn = 1:condN
        
        for s = 1:subjN            
            currectSubj = strcat (CommonPath,subjects(s),'/',subjects(s),'_',condgrands(cn),measure);            
            load (char(currectSubj));            
            %Concatenate all the subjects...
            if s==1
                SS = WT;
            else
                SS = cat(4,SS,WT);
            end            
        end
        
        %... calculate the average
        WT = mean(SS,4);
        
        %and in accordance to ERPWAVELAB file structure:
        nepoch=subjN;
        
        %Save the file in the grand folder and...
        OutFileName = char (strcat(condgrands(cn),measure));
        OutFileNameSS = char (strcat(condgrands(cn),measureSS));
        if exist('PROJECTPATH','var')
            outPath = strcat (PROJECTPATH,'/grand/',OutFileName);
            outPathSS = strcat (PROJECTPATH,'/grand/',OutFileNameSS);
        else
            outPath = strcat ('../grand/',OutFileName);
            outPathSS = strcat ('../grand/',OutFileNameSS);
        end
        save (outPath, 'WT', 'chanlocs', 'Fa', 'Fs', 'nepoch', 'tim', 'wavetyp');
        save (outPathSS, 'WT', 'SS', 'chanlocs', 'Fa', 'Fs', 'nepoch', 'tim', 'wavetyp');
        
        %... inform the user
        fprintf('Grand average and SS files for condition %s successfully saved in the grand folder!!!\n',char (strcat(condgrands(cn))));
        fprintf('\n');
        
    end
    
else %... compute WT matrix only.
    
    for cn = 1:condN
        
        %SET the grand average matrix
        grandmatrix = zeros(size(WT));
        
        for s = 1:subjN
            
            currectSubj = strcat (CommonPath,subjects(s),'/',subjects(s),'_',condgrands(cn),measure);
            
            load (char(currectSubj));
            
            %Sum all the subjects and...
            grandmatrix = grandmatrix+WT;
            
        end
        
        %... calculate the average
        grandmatrix = grandmatrix./subjN;
        %and in accordance to ERPWAVELAB file structure:
        WT=grandmatrix;
        nepoch=subjN;
        
        %Save the file in the grand folder and...
        OutFileName = char (strcat(condgrands(cn),measure));
        if exist('PROJECTPATH','var')
            outPath = strcat (PROJECTPATH,'/grand/',OutFileName);
        else
            outPath = strcat ('../grand/',OutFileName);
        end
        save (outPath, 'WT', 'chanlocs', 'Fa', 'Fs', 'nepoch', 'tim', 'wavetyp');
        
        %... inform the user
        fprintf('Grand average file for condition %s successfully saved in the grand folder!!!\n',char (strcat(condgrands(cn))));
        fprintf('\n');
        
    end
    
end

%Assign the variable subjects to the caller workspace
assignin('caller','subjects',subjects);