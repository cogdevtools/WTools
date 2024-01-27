classdef WTIOProcessor < handle

    properties(Constant,Access=private)
        ConfigSubDir   = 'Config';
        ImportSubDir   = 'Import';
        WaveletsSubDir = 'Wavelets';
        AnalysisSubDir = 'Analysis';
        GrandAvgSubDir = 'GrandAvg';
        TempSubDir     = 'Tmp';
    end

    properties(Constant)
        WaveletsAnalisys         = ''
        WaveletsAnalisys_ITLC    = 'ITLC'
        WaveletsAnalisys_ITPC    = 'ITPC'
        WaveletsAnalisys_ERSP    = 'ERSP'
        WaveletsAnalisys_evWT    = 'evWT'
        WaveletsAnalisys_avWT    = 'avWT'
        WaveletsAnalisys_WTav    = 'WTav'
        WaveletsAnalisys_Induced = 'Induced'

        ChannelsLocationFileTypeFlt = '*.sfp'
        SplineFileTypeFlt = '*.spl'

        ImportFileRe = '^(?<subject>\d+) export\.mat$'
        SubjAnalysisSubDirRe  = '^\d+$'
        EGIConditionSegmentFldRe = '^(?<condition>.+)_Segment(?<segment>\d+)$'
    end

    properties(SetAccess=private,GetAccess=public)
        RootDir char
        ConfigDir char
        ImportDir char
        AnalysisDir char
        TemporaryDir char
    end

    methods(Static,Access=private)
        function [success, varargout] = readModule(dir, file, varargin) 
            fName = fullfile(dir, file);
            varargout = cell(nargout-1, 1);
            [success, varargout{:}] = WTUtils.readModuleFile(fName, varargin{:});

            if success 
                return
            elseif nargin == 1
                WTLog().err('Can''t read file ''%s''', fName);
            else
                WTLog().err('Can''t read file ''%s'' or some content field(s) are missing: %s', fName, join(varargin{:},','));
            end
        end

        function success = writeModule(dir, file, varargin) 
            fName = fullfile(dir, file);
            success = WTUtils.writeTxtFile(dir, file, 'wt', varargin{:});
            if ~success 
                WTLog().err('Failed to write file ''%s''', fName);
            end
        end

        function [fName, fileExist] = exist(shouldExist, dir, file)
            fName = fullfile(dir, file);
            fileExist = isfile(fName);
            if shouldExist && ~fileExist 
                WTLog().excpt('WTConfig:NotExistingPath', '"%s" is not a valid file path', fName);
            end
        end
    end

    methods(Access=private)
        function default(o)
            o.RootDir = '';
            o.ConfigDir = '';
            o.ImportDir = '';
            o.AnalysisDir = '';
            o.TemporaryDir = '';
        end
    end

    methods
        function o = WTIOProcessor()
            o.default()
        end

        function success = setRootDir(o, rootDir, mustExist) 
            success = false;
            o.RootDir = WTUtils.getAbsPath(rootDir);
            o.ConfigDir = fullfile(o.RootDir, o.ConfigSubDir);
            o.ImportDir = fullfile(o.RootDir, o.ImportSubDir);
            o.AnalysisDir = fullfile(o.RootDir, o.AnalysisSubDir);
            o.TemporaryDir = fullfile(o.RootDir, o.TempSubDir);
            wtLog = WTLog();
            
            if mustExist
                if ~isfolder(o.RootDir)
                    wtLog.err('Root directory doesn''t exist or it''s not a directory: %s', o.RootDir);
                elseif ~isfolder(o.ConfigDir)
                    wtLog.err('Config directory doesn''t exist or it''s not a directory: %s', o.ConfigDir); 
                elseif ~isfolder(o.ImportDir)
                    wtLog.err('Import directory doesn''t exist or it''s not a directory: %s', o.ImportDir); 
                elseif ~isfolder(o.AnalysisDir)
                    wtLog.err('Analysis directory doesn''t exist or it''s not a directory: %s', o.AnalysisDir); 
                else 
                    success = true;
                end
            elseif ~WTUtils.mkdir(o.RootDir) 
                wtLog.err('Failed to create root directory: %s', o.RootDir);
            elseif ~WTUtils.mkdir(o.ConfigDir)
                wtLog.err('Failed to create config directory: %s', o.ConfigDir);
            elseif ~WTUtils.mkdir(o.ImportDir)
                wtLog.err('Failed to create import directory: %s', o.ImportDir);
            elseif ~WTUtils.mkdir(o.AnalysisDir)
                wtLog.err('Failed to create analysis directory: %s', o.AnalysisDir);
            else
                success = true;
            end
            if ~success
                o.default()
            end
        end

        function defined = rootDirDefined(o) 
            defined = ~isempty(o.RootDir);
        end

        function configFile = getConfigFile(o, fName) 
            configFile = fullfile(o.ConfigDir, fName);
        end
        
        function [success, varargout] = configRead(o, cfgFile, varargin) 
            varargout = cell(nargout-1, 1);
            [success, varargout{:}] = WTIOProcessor.readModule(o.ConfigDir, cfgFile, varargin{:});
        end

        function success = configWrite(o, cfgFile, varargin) 
            success = WTIOProcessor.writeModule(o.ConfigDir, cfgFile, varargin{:});
        end

        function [fName, fileExist] = configExist(o, shouldExist, cfgFile)
            [fName, fileExist] = WTIOProcessor.exist(shouldExist, o.ConfigDir, cfgFile);
        end


        function [fullPath, filePath] = getTemporaryFile(o, fileName, extension)
            filePath = o.TemporaryDir;
            if nargin < 2 || isempty(fileName)
                fullPath = tempname(filePath);
            else
                fullPath = fullfile(filePath, fileName);
            end
            if nargin > 2 
                fullpath = [fullpath extension];
            end
        end

        function [success, chansLocations] = readChannelsLocations(o, fileName)
            success = false;
            chansLocations = {};
            try
                fullPath = fullfile(WTLayout.getToolsSplinesDir(), fileName);
                [l x y z] = textread(fullPath,'%s %n %n %n','delimiter', '\t');
                for i = 1:length(l)
                    chn = struct('Label', l{i}, 'Location', [x(i) y(i) z(i)]);
                    chansLocations = [chansLocations {chn}];
                end
                success = true;
            catch me
                WTLog().mexcpt(me);
                return
            end
        end

        % In this case fileName can be either scalar or a cell array of strings
        function [subjects, sbjFiles] = getSubjectsFromImportFiles(o, varargin)
            subjects = {};
            sbjFiles = {};
            match = regexp(varargin, o.ImportFileRe, 'once', 'names');
            for i = 1:length(match)
                if ~isempty(match{i})
                    sbjFiles = [sbjFiles varargin(i)];
                    subjects = [subjects {match{i}.subject}];
                end
            end
        end

        function [subjFiles, subjects] = enumImportFiles(o) 
            dirContent = dir(fullfile(o.ImportDir, '*.mat'));
            subjFiles = cell(length(dirContent), 1);;
            subjects = cell(length(dirContent), 1);
            nValid = 0;

            for i = 1:length(dirContent)
                if dirContent(i).isdir
                    continue
                end
                subject = o.getSubjectsFromImportFiles(dirContent(i).name);
                if ~isempty(subject)
                    nValid = nValid + 1;
                    subjFiles{nValid} = dirContent(i).name;
                    subjects{nValid} = subject;
                end
            end

            subjFiles = subjFiles(1:nValid);
            subjects = subjects{1:nValid};
        end

        function [success, sbjDir] = makeAnalysisSubjectDir(o, subject)
            sbjDir = fullfile(o.AnalysisDir, subject);
            success = WTUtils.mkdir(sbjDir);
        end

        function [fullPath, filePath, fileName] = getImportFileForSubject(o, subject)
            filePath = o.ImportDir;
            fileName = strcat(subject, ' export.mat');
            fullPath = fullfile(filePath, fileName);
        end

        function [fullPath, filePath] = getImportFile(o, fileName)
            filePath = o.ImportDir;
            fullPath = fullfile(filePath, fileName);
        end

        function [success, varargout] = loadImport(o, fileName, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getImportFile(fileName);
            [success, varargout{:}] = WTUtils.loadFrom(fullPath, '-mat', varargin{:});
        end

        function [success, conditions, data] = getConditionsFromImport(o, fileName)
            conditions = {};
            [success, data] = o.loadImport(fileName);
            if ~success 
                return
            end
            fieldNames = fieldnames(data);
            result = regexp(fieldNames, o.EGIConditionSegmentFldRe, 'once', 'tokens');
            match = result(~cellfun(@isempty, result));
            cndSeg = cat(1, match{:});
            conditions = unique(cndSeg(:,1));
            success = length(conditions) > 0;
        end

        function [fullPath, filePath, fileName] = getProcessedImportFile(o, filePrefix, subject)
            fileName = strcat(filePrefix, '_', subject, '.set');
            filePath = fullfile(o.AnalysisDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        function [success, EEG] = loadProcessedImport(o, filePrefix, subject, updateALLEEG)
            success = false;
            EEG = [];
            
            try
                updateALLEEG = nargin < 4 || any(logical(updateALLEEG));
                [~, filePath, fileName] = o.getProcessedImportFile(filePrefix, subject);

                if ~updateALLEEG
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                else
                    [ALLEEG, ~, ~, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, false);
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                    [~, EEG, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, 0);
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
                end
                success = true;
            catch 
                WTLog().mexcpt(me);
            end 

            if ~success 
                WTLog().err('Failed to load processed import related to subject ''%s''', subject);
            end
        end

        function [success, fullPath, EEG] = writeProcessedImport(o, filePrefix, subject,  EEG)
            success = false;
            EEG = [];
            
            try
                [fullPath, filePath, fileName] = o.getProcessedImportFile(filePrefix, subject);
                success = WTUtils.mkdir(filePath);
                if ~success
                    WTLog().err('Failed to make dir ''%s''', filePath);
                else
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_saveset', EEG,  'filename', fileName, 'filepath', filePath);
                    success = true
                end
            catch me
                WTLog().mexcpt(me);
            end
        end

        function setName = getConditionSet(o, filePrefix, subject, condition)
            setName = strcat(filePrefix, '_', subject, '_', condition);
        end

        function [fullPath, filePath, fileName] = getConditionFile(o, filePrefix, subject, condition)
            fileName = strcat(o.getConditionSet(filePrefix, subject, condition), '.set');
            filePath = fullfile(o.AnalysisDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        function [success, EEG] = loadCondition(o, filePrefix, subject, condition, updateALLEEG)
            success = false;
            EEG = [];
            
            try
                updateALLEEG = nargin < 5 || any(logical(updateALLEEG));
                [~, filePath, fileName] = o.getConditionFile(filePrefix, subject, condition);

                if ~updateALLEEG
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                else
                    [ALLEEG, ~, ~, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, false);
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                    [~, EEG, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, 0);
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
                end
                success = true;
            catch 
                WTLog().mexcpt(me)
            end 
        end

        function [fullPath, filePath, fileName] = getBaselineCorrectionFile(o, subject, condition, wType)
            switch wType
                case WTIOProcessor.WaveletsAnalisys_evWT
                case WTIOProcessor.WaveletsAnalisys_avWT
                otherwise
                    fullPath = [];
                    filePath = [];
                    fileName = [];
                    WTLog().err('Unknown file type %s', wType);
                    return
            end
            fileName = strcat(subject, '_', condition, '_bc-', wType, '.mat');
            filePath = fullfile(o.AnalysisDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeBaselineCorrection(o, subject, condition, wType, varargin)
            success = false;
            fullPath = [];
           
            try
                [fullPath, filePath, fileName] = o.getBaselineCorrectionFile(subject, condition, wType);
                if ~isempty(fullPath)
                    argsName = [{filePath fileName} varargin];
                    argsName = WTUtils.quoteMany(argsName{:});
                    cmd = sprintf('WTUtils.saveTo(%s);', char(join(argsName, ',')));
                    evalin('caller', cmd);
                    success = true;
                end
            catch me
                WTLog().mexcpt(me);
            end
        end

        function [success, varargout] = loadBaselineCorrection(o, subject, condition, wType, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getBaselineCorrectionFile(subject, condition, wType);
            if ~isempty(fullPath)
                [success, varargout{:}] = WTUtils.loadFrom(fullPath, '-mat', varargin{:});
            end
        end

        function [fullPath, filePath, fileName] = getGrandAverageFile(o, condition, wType, perSubject)
            switch wType
                case WTIOProcessor.WaveletsAnalisys_evWT
                case WTIOProcessor.WaveletsAnalisys_avWT
                otherwise
                    fullPath = [];
                    filePath = [];
                    fileName = [];
                    WTLog().err('Unknown file type %s', wType);
                    return
            end
            extension = '.mat';
            if any(logical(perSubject)) 
                extension = '.ss';
            end
            fileName = strcat(condition, '_bc-', wType, extension);
            filePath = fullfile(o.AnalysisDir, o.GrandAvgSubDir);
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeGrandAverage(o, condition, wType, perSubject, varargin)
            success = false;
            fulltPath = [];
           
            try
                [fullPath, filePath, fileName] = o.getGrandAverageFile(condition, wType, perSubject);
                if ~isempty(fullPath)
                    argsName = [{filePath fileName} varargin];
                    argsName = WTUtils.quoteMany(argsName{:});
                    cmd = sprintf('WTUtils.saveTo(%s);', char(join(argsName, ',')));
                    evalin('caller', cmd);
                    success = true;
                end
            catch me
                WTLog().mexcpt(me);
            end
        end

        function [success, varargout] = loadGrandAverage(o, condition, wType, perSubject, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getGrandAverageFile(condition, wType, perSubject);
            if ~isempty(fullPath)
                [success, varargout{:}] = WTUtils.loadFrom(fullPath, '-mat', varargin{:});
            end
        end

        function [fullPath, filePath, fileName] = getDifferenceFile(o, subject, condA, condB, wType)
            switch wType
                case WTIOProcessor.WaveletsAnalisys_evWT
                case WTIOProcessor.WaveletsAnalisys_avWT
                otherwise
                    fullPath = [];
                    filePath = [];
                    fileName = [];
                    WTLog().err('Unknown file type %s', wType);
                    return
            end
            fileName = strcat(subject, '_', condA, '-', condB, '_bc-', wType, '.mat');
            filePath = fullfile(o.AnalysisDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeDifference(o, subject, condA, condB, wType, varargin)
            success = false;
            fullPath = [];
            try
                [fullPath, filePath, fileName] = o.getDifferenceFile(subject, condA, condB, wType);
                if ~isempty(fullPath)
                    argsName = [{filePath fileName} varargin];
                    argsName = WTUtils.quoteMany(argsName{:});
                    cmd = sprintf('WTUtils.saveTo(%s);', char(join(argsName, ',')));
                    evalin('caller', cmd);
                    success = true;
                end
            catch me
                WTLog().mexcpt(me);
            end
        end

        function [success, varargout] = loadDifference(o, subject, condA, condB, wType, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getDifferenceFile(subject, condA, condB, wType);
            if ~isempty(fullPath)
                [success, varargout{:}] = WTUtils.loadFrom(fullPath, '-mat', varargin{:});
            end
        end

        function [fullPath, filePath, fileName] = getWaveletAnalysisFile(o, subject, condition, wType)
            fullPath = [];
            filePath = [];
            fileName = [];

            switch wType
                case WTIOProcessor.WaveletsAnalisys
                    fileName = strcat(subject, '_' , condition, '.mat'); 
                case WTIOProcessor.WaveletsAnalisys_ITLC
                case WTIOProcessor.WaveletsAnalisys_ITPC 
                case WTIOProcessor.WaveletsAnalisys_ERSP
                case WTIOProcessor.WaveletsAnalisys_evWT
                case WTIOProcessor.WaveletsAnalisys_avWT
                case WTIOProcessor.WaveletsAnalisys_WTav
                case WTIOProcessor.WaveletsAnalisys_Induced
                otherwise
                    WTLog().err('Unknown file type %s', wType);
                    return
            end
            if isempty(fileName)
                fileName = strcat(subject, '_' , condition, '-', wType, '.mat');
            end
            filePath = fullfile(o.AnalysisDir, subject, o.WaveletsSubDir, condition);
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeWaveletsAnalysis(o, subject, condition, wType, varargin)
            success = false;
            fullPath = [];
            try
                [fullPath, filePath, fileName] = o.getWaveletAnalysisFile(subject, condition, wType);
                if ~isempty(fullPath)
                    argsName = [{filePath fileName} varargin];
                    argsName = WTUtils.quoteMany(argsName{:});
                    cmd = sprintf('WTUtils.saveTo(%s);', char(join(argsName, ',')));
                    evalin('caller', cmd);
                    success = true;
                end
            catch me
                WTLog().mexcpt(me);
            end
        end

        function [success, varargout] = loadWaveletsAnalysis(o, subject, condition, wType, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getWaveletAnalysisFile(subject, condition, wType);
            if ~isempty(fullPath)
                [success, varargout{:}] = WTUtils.loadFrom(fullPath, '-mat', varargin{:});
            end
        end

        function subjects = getAnalysedSubjects(o)
            dirContent = dir(fullfile(o.AnalysisDir, '*'));
            subjects = cell(length(dirContent), 1);
            nValid = 0;

            for i = 1:length(dirContent)
                if ~dirContent(i).isdir
                    continue
                end
                if ~isempty(regexp(dirContent(i).name, o.SubjAnalysisSubDirRe, 'once')) 
                    nValid = nValid + 1;
                    subjects{nValid} = dirContent(i).name;
                end
            end

            subjects = subjects{1:nValid};
        end 
    end
end
