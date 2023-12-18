function rencond(subjects, varargin)

%rencond.m
%Created by Eugenio Parise
%CDC CEU 2011
%Function to rename the conditions of an exported netstation files in mat
%format before importing it into EEGLAB. Netstation files must be
%exported in .mat format, each trial in an individual array. Only
%good segments must be exported.
%To set this script to process the whole final sample of subjects in a study,
%edit 'subj.m' in the 'cfg' folder and and digit rencond([],...); ([]=empty).
%
%Usage:
%
%rencond(subject,OldCondName1,NewCondName1,OldCondName2,NewCondName2,... OldCondNameN, NewCondNameN);
%
%rencond('01','Gaze_averted','GA','Gaze_direct','GD');

addpath('../cfg');
exported;

if isempty(subjects)    
    subj;    
elseif ischar(subjects)    
    subjects={subjects};    
elseif ~iscell(subjects)    
    fprintf(2,'\nPlease, enter a subject number in the right format, e.g. rencong(''01'',...);, to process\n');
    fprintf(2,'an individual subject, or edit ''subj.m'' in the ''cfg'' folder and enter rencond([],...);,\n');
    fprintf(2,'to process the whole sample.\n');
    fprintf('\n');
    return    
end

subjN = size(subjects,2);
InOutPath = strcat (exportvar);

if rem(nargin,2)~=1    
    fprintf('\n');
    fprintf(2,'Rencond requires the subject(s) number + an even number of arguments,\n');
    fprintf(2,'at least 2: 1 old condition name and 1 new condition name!!!\n');
    fprintf('\n');
    return;    
end

fprintf('\n');
fprintf('Renaming conditions.\n');
fprintf('Please wait...\n');
fprintf('\n');

for S = 1:subjN
    currectSubj = char (strcat (InOutPath,subjects(S),' export.mat'));    
    tmpdata = load('-mat', currectSubj);
    c=0;
    
    for j=1:((nargin)/2)        
        oldname=varargin{j+c};
        newname=varargin{j+1+c};        
        allfields = fieldnames(tmpdata);
        namefound=0;
        k=1;
        
        while namefound==0           
            if findstr(char(allfields(k)), oldname)                
                estMaxChar=length(char(allfields(k)));
                begintrN=length(oldname)+length('_Segment')+1;                
                for i=1:9                    
                    if estMaxChar>length(char(allfields(k+i)))                        
                        estMaxChar=length(char(allfields(k+i)));                        
                    end                    
                end                
                namefound=1;                
            end            
            k=k+1;            
        end
        
        for i=1:length(allfields)            
            if findstr(char(allfields(i)), oldname)                
                estMaxChar=length(char(allfields(i)));
                trialN=cellstr(allfields{i}(begintrN:estMaxChar));
                NewVarName=char(strcat(newname, '_Segment_', trialN));
                VarValue=allfields{i};
                tmpdata.(char(NewVarName))=tmpdata.(char(VarValue));
                tmpdata=rmfield(tmpdata, VarValue);                
            end            
        end        
        c=c+1;        
    end    
    save (currectSubj, '-struct', 'tmpdata');    
end

fprintf('\n');
fprintf('Done!!!\n');
fprintf('\n');

end