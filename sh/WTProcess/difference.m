% difference.m
% Created by Eugenio Parise
% CDC CEU 2010 - 2011
% Calculate the difference between two conditions (e.g. C1-C2 C3-C4);
% Store the resulting files in the subject folder.
% IMPORTANT! Define the condition you want to subtract by editing the variable 'condiff'
% in the file 'cond.m' ('cfg' folder).
% To set this script to process the whole final sample of subjects in a study,
% edit 'subj.m' in the 'cfg' folder and  digit difference([]) at the console prompt.
% Add evoked = true  as last argument to compute conditions difference of evoked
% oscillations (of course, if they have been previously computed).
%
% Usage:
%
% difference('01');
% difference([]);
% %difference([], true);

function difference(subjects, evoked)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.Config.SubjectsGrand.exist() || ...
       ~wtProject.Config.WaveletTransform.exist()
        WTUtils.eeglabMsgGui('Info', 'Please, perform the wavelet transformation first!');
        return
    end

    % TODO: 1) clarify why we get subjects from wtProject.Config.Subjects and not from wtProject.Config.SubjectsGrand?
    %       2) do we really need subjects and evoked parameters in the function?  
    if nargin == 0 || isempty(subjects) 
        subjects = wtProject.Config.Subjects.SubjectsList;
    elseif ischar(subjects)
        subjects = {subjects};
    elseif ~WTValidations.isALinearCellArrayOfNonEmptyString(subjects)
        wtLog.err('Bad argument format: subjects must be a string or must be a linear cell array of non empty strings');
        WTUtils.eeglabMsgGui('Warning', 'Subjects must be a string or linear cell array of non empty strings!');
        return
    end
    
    if length(wtProject.Config.ConditionsGrand.ConditionsList) < 2
        wtLog.warn('There is only one condition, so no conditions diff can be performd!')
        WTUtils.eeglabMsgGui('Info', 'There only one condition, so no conditions diff can be performd!')
        return
    end

    if nargin == 0
        subjects = wtStrCellsSelectGUI(subjects, 'Select subjects for difference:');
        if isempty(subjects)
            return
        end
        if ~setDifferencePrms(wtLog, wtProject)
            return
        end
    end

    condsGrandPrms = wtProject.Config.ConditionsGrand;
    differencePrms = wtProject.Config.Difference;
    evoked = (nargin > 1 && logical(evoked)) || (nargin < 1 && differencePrms.EvokedOscillations);
    conditions = condsGrandPrms.ConditionsList;
    condiff = condsGrandPrms.ConditionsDiff;
    subjN = length(subjects);
    condN = length(conditions);
    condiffN = length(condiff);

    if wtProject.IsOpen
        CommonPath = wtProject.Config.getRootDir();
    else
        CommonPath = '..';
    end

    condsToSubtract = [];

    % Find the conditions to subtract and put them in condsToSubtract array
    for i = 1:condiffN
        j = 1;
        temp = zeros(1,2);
        while j<= condN
            [~,~,~,matchstring] = regexp(condiff(i),conditions(j));

            if ~isempty(matchstring{1,1})
                minuspos = strfind(char(condiff(i)),'-');
                condpos = strfind(char(condiff(i)),char(matchstring{1,1}{1,1}));
                
                % condpos is 1 in length = 1 match found in the condition difference array.
                if length(condpos)==1
                    if ~(condpos(1)==1 || condpos(1)==minuspos+1) % fake match found
                        matchstring{1,1} = [];
                    end
                end
                
                % condpos is 2 in length = 2 matchs found in the condition difference array.
                if length(condpos) > 1
                    if condpos(1) == 1 && condpos(2) == minuspos+1
                        % do nothing: the user want to subtract a condition from itself
                    elseif condpos(1) ~= 1 && condpos(2) ~= minuspos+1 % fake match found
                        matchstring{1,1} = [];
                    elseif condpos(1) ~= 1
                        condpos=condpos(2); % this is the only true match
                        matchstring{1,1} = {conditions(j)};
                    elseif condpos(1) == 1
                        condpos=condpos(1); % this is the only true match
                        matchstring{1,1} = {conditions(j)};
                    end
                end
                
            end
            
            % Both conditions not found in the difference string
            if isempty(matchstring{1,1}) && temp(1) == 0 && temp(2) == 0 && j == condN
                wtLog.err(['Both conditions in the pair %s do not match any experimental condition!\n' ...
                    'Edit %s in the configuration folder and correct your setting'], ...
                    condiff{i}, condsGrandPrms.getFileName());
                return
            % One condition found in the difference string
            elseif ~isempty(matchstring{1,1}) && length(matchstring{1,1}) == 1
                actualcond = strfind(conditions,char(matchstring{1,1}{1,1}));
                for k = 1:length(actualcond)
                    if ~isempty(actualcond{k}) && actualcond{k}>1
                        actualcond{k}=[];
                    end
                end
                notemptyCells = ~cellfun(@isempty, actualcond);
                if minuspos<condpos
                    temp(2) = find(notemptyCells==1);
                else
                    temp(1) = find(notemptyCells==1);
                end
                if temp(1) ~= 0 && temp(2) ~= 0
                    j = condN;
                end    
            % Two equal conditions found in the difference string
            elseif ~isempty(matchstring{1,1}) && length(matchstring{1,1}) == 2
                actualcond = strfind(conditions,char(matchstring{1,1}{1,1}));
                for k = 1:length(actualcond)
                    if ~isempty(actualcond{k}) && actualcond{k} > 1
                        actualcond{k} = [];
                    end
                end
                notemptyCells = ~cellfun(@isempty,actualcond);
                temp(:) = find(notemptyCells==1);
                j = condN;

                wtLog.warn(['Condition %s will be subtracted from itself!\n' ...
                    'Consider to edit %s in the configuration folder and correct your setting.'], ...
                    conditions{temp(1)}, condsGrandPrms.getFileName())
            end
            
            j = j+1;
        end
        
        % One condition not found in the difference string
        if temp(1) == 0 || temp(2) == 0
            wtLog.err(['One condition in the pair %s do not match any experimental condition!\n' ...
                'Edit %s in the configuration folder and correct your setting'], condiff{i}, condsGrandPrms.getFileName());
            return
        else
            condsToSubtract = cat(2,condsToSubtract,temp);
        end
    end

    condstosubtractN = length(condsToSubtract);
    wtLog.info('Computing difference between conditions...');
    wtLog.ctxOn()

    if ~evoked
        measure = '_bc-avWT.mat';    
    else 
        measure = '_bc-evWT.mat';     
    end

    for s = 1:subjN
        correction = 0;

        for cn = 1:condstosubtractN/2
            % load first datasets
            C1 = conditions{condsToSubtract(cn+correction)};
            fileName = strcat(subjects{s}, '_', C1, measure);
            dataset = fullfile(CommonPath, subjects{s}, fileName);
            load(dataset);
            
            % Store WT of the current dataset
            temp = WT;
            
            % load second datasets
            C2 = conditions{condsToSubtract(cn+correction+1)};
            fileName = strcat(subjects{s}, '_', C2, measure);
            dataset = fullfile(CommonPath, subjects{s}, fileName);
            load(dataset);
            
            % Calculate difference
            WT = temp - WT;
            
            % Save the difference in the grand folder
            OutFileName = strcat(subjects{s}, '_', C1, '-', C2, measure);

            if ~WTUtils.saveTo(fullfile(CommonPath, subjects{s}), OutFileName, ...
                'WT', 'chanlocs', 'Fa', 'Fs', 'nepoch', 'tim', 'wavetyp')
                wtLog.err('Can''t save the difference between conditions (%s, %s) for subject %s!', C1, C2, subjects{s})
            else
                wtLog.info('Difference (%s - %s) saved in subject %s folder.', C1, C2, subjects{s});  
            end
            correction = correction + 1;        
        end
    end

    wtLog.ctxOff()
    wtLog.info('Difference computation completed.');
end

function success = setDifferencePrms(wtLog, wtProject)   
    success = false;  
    condsGrandPrms = copy(wtProject.Config.ConditionsGrand);
    differencePrms = copy(wtProject.Config.Difference);
    [~, logFlag, last_tfcmor] = wtCheckEvokLog();

    if ~wtDifferenceGUI(differencePrms, condsGrandPrms, logFlag, last_tfcmor)
        return
    end
    if condsGrandPrms.persist() 
        wtProject.Config.ConditionsGrand = condsGrandPrms;
    else
        wtLog.err('Failed to save conditions grand params');
        return
    end
    if differencePrms.persist()
        wtProject.Config.Difference = differencePrms;
    else
        wtLog.err('Failed to save difference params');
        return
    end
    success = true;
end