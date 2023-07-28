function [diffConsistency, grandConsistency] = check_diff_grand(filenames, condiff, subj, logFlag)

%check_diff_grand.m
%Created by Eugenio Parise
%CDC CEU 2012
%Function that controls whether data are up to date and ready for grandaverage (i.e. n>1) 

diffConsistency=1;
grandConsistency=1;

%CHECK if difference files are up to date
if any(ismember(filenames,condiff))
    
    difference_cfg;
    
    if ~(defaultanswer{1,4}==logFlag)
        fprintf('\n');
        fprintf(2, 'The difference files are not up to date!!!\n');
        fprintf(2, 'Please, run Difference again before plotting.');
        fprintf('\n');
        diffConsistency=0;
    end
    
end

%CHECK if grand average files are up to date
if strcmp(subj,'grand')
    
    grand_cfg;
    
    if ~(defaultanswer{1,3}==logFlag)
        fprintf('\n');
        fprintf(2, 'The grand average files are not up to date!!!\n');
        fprintf(2, 'Please, run Grand Average again before plotting.');
        fprintf('\n');
        grandConsistency=0;
    end
    
end