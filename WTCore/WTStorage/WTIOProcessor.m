classdef WTIOProcessor < handle

    properties(Constant,Access=private)
        LogSubDir       = 'Logs'
        ConfigSubDir    = 'Config';
        ImportSubDir    = 'Import';
        WaveletsSubDir  = 'Wavelets';
        AnalysisSubDir  = 'Analysis';
        GrandAvgSubDir  = 'GrandAvg';
        TemporarySubDir = 'Tmp';
    end

    properties(Constant, Hidden)
        WaveletsAnalisys         = ''
        WaveletsAnalisys_ITLC    = 'ITLC'
        WaveletsAnalisys_ITPC    = 'ITPC'
        WaveletsAnalisys_ERSP    = 'ERSP'
        WaveletsAnalisys_evWT    = 'evWT'
        WaveletsAnalisys_avWT    = 'avWT'
        WaveletsAnalisys_WTav    = 'WTav'
        WaveletsAnalisys_Induced = 'Induced'

        SystemEGI    = 'EGI'
        SystemEEP    = 'EEP'
        SystemEEGLab = 'EEGLab'
        SystemBRV    = 'BRV'

        SplineFileTypeFlt = '*.spl'
        GrandAvgFileExt = '.mat'
        PerSbjGrandAvgFileExt = '.ss'
        SubjAnalysisSubDirRe  = sprintf('^(?<subject>\\d+)%s*$', WTUtils.ifThenElse(ispc, '\\','/'));
        EGIConditionSegmentFldRe = '^(?<condition>.+)_Segment(?<segment>\d+)$'
        BaselineCorrectedFileNameRe = ['^((?<subject>\d+)_)?(?<condition>[^_]+)_bc-(?<measure>.+)(?:\' ...
            WTIOProcessor.GrandAvgFileExt '|\' WTIOProcessor.PerSbjGrandAvgFileExt ')$'] 
    end

    properties(SetAccess=private,GetAccess=public)
        RootDir char
        LogDir char
        ConfigDir char
        ImportDir char
        AnalysisDir char
        GrandAvgDir char
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
                WTLog().err('Can''t read file ''%s'' or some content field(s) are missing: %s', fName, char(join(varargin,',')));
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
                WTException.notExistingPath('"%s" is not a valid file path', fName).throw();
            end
        end

        function [subjects, sbjFiles] = getSbjsFromImportFiles(fileNameFmtRe, varargin)
            match = regexp(varargin, fileNameFmtRe, 'once', 'names');
            result = ~cellfun(@isempty, match);
            sbjFiles = varargin(result);
            subjects = cellfun(@(x){x.subject}, match(result));
        end

        function re = getSystemImportFileNameFmtRe(system) 
            switch system
                case WTIOProcessor.SystemEEP
                    re = '^.+_(?<subject>\d+)\.cnt$';
                case WTIOProcessor.SystemEEGLab
                    re = '^([^0-9]|\d+[^0-9]+)*(?<subject>\d+)\.set$';
                case WTIOProcessor.SystemEGI
                    re = '^(?<subject>\d+) .*\.mat$';
                case WTIOProcessor.SystemBRV
                    re = '^(?<subject>\d+) .*\.mat$';
                otherwise
                    WTException.badArg('Unknown system: %s', WTUtils.ifThenElse(ischar(system), system, '?')).throw();
            end
        end
    end

    methods(Static,Access=public)
        function systems = getSystemTypes() 
            systems = { ...
                WTIOProcessor.SystemEGI, ...
                WTIOProcessor.SystemEEP, ...
                WTIOProcessor.SystemBRV, ...
                WTIOProcessor.SystemEEGLab};
        end

        function filePath = getEEGLabRawFile(subjectFilePath)
            [dir, name, ~] = fileparts(subjectFilePath);
            filePath = fullfile(dir, [name '.fdt']);
        end  

        function filePath = getEEPRejectionFile(subjectFilePath)
            [dir, name, ~] = fileparts(subjectFilePath);
            filePath = fullfile(dir, [name 'fr.rej']);
        end  

        function extension = getSystemImportFileExtension(system)           
            switch system
                case WTIOProcessor.SystemEEP
                    extension = 'cnt';
                case WTIOProcessor.SystemEEGLab
                    extension = 'set';
                case WTIOProcessor.SystemEGI
                    extension = 'mat';
                case WTIOProcessor.SystemBRV
                    extension = 'mat';
                otherwise
                    WTException.badArg('Unknown system: %s', WTUtils.ifThenElse(ischar(system), system, '?')).throw();
            end
        end

        function [wType, extension] = getGrandAverageFileTypeAndExtension(perSubject, evokedOscillation)
            wType = WTUtils.ifThenElse(evokedOscillation, ...
                WTIOProcessor.WaveletsAnalisys_evWT, WTIOProcessor.WaveletsAnalisys_avWT);
            extension = WTUtils.ifThenElse(any(logical(perSubject)), ...
                WTIOProcessor.PerSbjGrandAvgFileExt,  WTIOProcessor.GrandAvgFileExt);
        end

        function fileNames = getSystemExtraImportFiles(system, subjectFilePath)           
            switch system
                case WTIOProcessor.SystemEEP
                    fileNames = { WTIOProcessor.getEEPRejectionFile(subjectFilePath) };
                case WTIOProcessor.SystemEEGLab
                    fileNames = { WTIOProcessor.getEEGLabRawFile(subjectFilePath) };
                case WTIOProcessor.SystemEGI
                    fileNames = {};
                case WTIOProcessor.SystemBRV
                    fileNames = {};
                otherwise
                    WTException.badArg('Unknown system: %s', WTUtils.ifThenElse(ischar(system), system, '?')).throw();
            end
        end

        function extension = getSystemChansLocationFileExtension(system) 
            switch system
                case WTIOProcessor.SystemEEP
                    extension = 'ced';
                case WTIOProcessor.SystemEEGLab
                    extension = 'sfp';
                case WTIOProcessor.SystemEGI
                    extension = 'sfp';
                case WTIOProcessor.SystemBRV
                    extension = 'sfp';
                otherwise
                    WTException.badArg('Unknown system: %s', WTUtils.ifThenElse(ischar(system), system, '?')).throw();
            end
        end

        function [subject, condition, wType] = splitBaselineCorrectedFileName(fileName)
            subject = [];
            condition = [];
            wType = [];
            match =regexp(fileName, WTIOProcessor.BaselineCorrectedFileNameRe, 'once', 'names');
            if isempty(match)
                return
            end
            if isfield(match, 'subject')
                subject = match.subject;
            end
            condition = match.condition;
            wType = match.measure;
        end

        function [conditions, emptyConditionFiles] = getConditionsFromBaselineCorrectedFileNames(fileNames)
            conditions = cell(1, length(fileNames));
            emptyConditionFiles = {};
            for i = 1:length(fileNames) 
                [~, condition] = WTIOProcessor.splitBaselineCorrectedFileName(fileNames{i});
                if isempty(condition)
                    emptyConditionFiles = [emptyConditionFiles fileNames(i)];
                    continue
                end
                conditions{i} = condition;
            end
        end

        function [success, chansLocations] = readChannelsLocations(system, fileName)
            success = false;
            chansLocations = {};

            try
                fullPath = fullfile(WTLayout.getDevicesDir(), fileName);

                if strcmp(system, WTIOProcessor.SystemEGI) || ...
                   strcmp(system, WTIOProcessor.SystemEEGLab) || ...
                   strcmp(system, WTIOProcessor.SystemBRV)
                    [l, x, y, z] = textread(fullPath,'%s %n %n %n','delimiter', '\t');
                elseif strcmp(system, WTIOProcessor.SystemEEP)
                    [~, l, ~, ~, x, y, z, ~, ~, ~, ~, ~] = textread(fullPath, ...
                        '%s %s %s %s %n %n %n %s %s %s %s %s', 'delimiter', '\t', 'headerlines', 1);
                    l = cat(1,l, {'VEOG';'HEOG';'DIGI'});
                else
                    WTException.badArg('Unknown system: %s', WTUtils.ifThenElse(ischar(system), system, '?')).throw();
                end

                chansLocations = cell(1, length(l));
                for i = 1:length(l)
                    chansLocations{i} = struct('Label', l{i}, 'Location', [x(i) y(i) z(i)]);
                end
                success = true;
            catch me
                WTLog().except(me);
                return
            end
        end        
    end

    methods(Access=private)
        function default(o)
            o.RootDir = '';
            o.LogDir = '';
            o.ConfigDir = '';
            o.ImportDir = '';
            o.AnalysisDir = '';
            o.GrandAvgDir = '';
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
            o.LogDir = fullfile(o.RootDir, o.LogSubDir);
            o.ConfigDir = fullfile(o.RootDir, o.ConfigSubDir);
            o.ImportDir = fullfile(o.RootDir, o.ImportSubDir);
            o.AnalysisDir = fullfile(o.RootDir, o.AnalysisSubDir);
            o.GrandAvgDir = fullfile(o.AnalysisDir, o.GrandAvgSubDir);
            o.TemporaryDir = fullfile(o.RootDir, o.TemporarySubDir);
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

        function [fullPath, filePath] = getLogFile(o, prefix)
            time = char(datetime('now','TimeZone','local','Format', 'yyyyMMdd.HHmmss'));
            fileName = sprintf('%s.%s.log', prefix, time);
            filePath = o.LogDir;
            fullPath = fullfile(filePath, fileName);
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
                filePath = [filePath extension];
            end
        end  

        % In this case fileName can be either scalar or a cell array of strings
        function [subjects, sbjFiles] = getSubjectsFromImportFiles(o, system, varargin)
            fileNameFmtRe = WTIOProcessor.getSystemImportFileNameFmtRe(system);
            [subjects, sbjFiles] = WTIOProcessor.getSbjsFromImportFiles(fileNameFmtRe, varargin{:});
        end

        function [subjFiles, subjects] = enumImportFiles(o, system) 
            fileNameFmtRe =  WTIOProcessor.getSystemImportFileNameFmtRe(system);
            extensionFlt = ['*.' WTIOProcessor.getSystemImportFileExtension(system)];
            dirContent = dir(fullfile(o.ImportDir, extensionFlt));
            subjFiles = cell(length(dirContent), 1);
            subjects = cell(length(dirContent), 1);
            nValid = 0;

            for i = 1:length(dirContent)
                if dirContent(i).isdir
                    continue
                end
                subject = WTIOProcessor.getSbjsFromImportFiles(fileNameFmtRe, dirContent(i).name);
                if ~isempty(subject)
                    nValid = nValid + 1;
                    subjFiles{nValid} = dirContent(i).name;
                    subjects{nValid} = subject;
                end
            end

            if nValid > 0
                subjFiles = subjFiles(1:nValid);
                subjects = subjects{1:nValid};
            end
        end

        function [success, sbjDir] = makeAnalysisSubjectDir(o, subject)
            sbjDir = fullfile(o.AnalysisDir, subject);
            success = WTUtils.mkdir(sbjDir);
        end

        function [fullPath, filePath] = getImportFile(o, fileName)
            filePath = o.ImportDir;
            fullPath = fullfile(filePath, fileName);
        end

        function [success, varargout] = loadImport(o, system, fileName, varargin)
            varargout = cell(1, nargout-1);
            [fullPath, filePath] = o.getImportFile(fileName);
           
            switch system
                case WTIOProcessor.SystemEGI
                    [success, varargout{:}] = WTUtils.loadFrom(fullPath, '-mat', varargin{:});
                case WTIOProcessor.SystemEEGLab
                    [success, varargout{:}] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                case WTIOProcessor.SystemEEP
                    [success, varargout{:}] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_loadeep', fullPath, 'triggerfile', 'on');
                case WTIOProcessor.SystemBRV
                    [success, varargout{:}] = WTUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_loadbva', fullPath);
                otherwise
                    WTException.badArg('Unknown system: %s', WTUtils.ifThenElse(ischar(system), system, '?')).throw();
            end
        end

        function [success, conditions, data] = getConditionsFromImport(o, system, fileName)
            conditions = {};
            [success, data] = o.loadImport(system, fileName);
            if ~success 
                return
            end
            switch system
                case WTIOProcessor.SystemEGI
                    fieldNames = fieldnames(data);
                    result = regexp(fieldNames, o.EGIConditionSegmentFldRe, 'once', 'tokens');
                    match = result(~cellfun(@isempty, result));
                    cndSeg = cat(1, match{:});
                    conditions = unique(cndSeg(:,1));
                    success = ~isempty(conditions);
                case WTIOProcessor.SystemEEGLab
                    conditions = sort(unique({ data.event.type }));
                case WTIOProcessor.SystemEEP
                    WTException.unsupported('Unsupported system: %s', system).throw();
                case WTIOProcessor.SystemBRV
                    conditions = sort(unique({ data.event.type }));
                otherwise
                    WTException.badArg('Unknown system: %s', WTUtils.ifThenElse(ischar(system), system, '?')).throw();
            end
        end

        function [fullPath, filePath, fileName] = getProcessedImportFile(o, filePrefix, subject)
            fileName = strcat(filePrefix, '_', subject, '.set');
            filePath = fullfile(o.AnalysisDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        function [success, EEG, ALLEEG] = loadProcessedImport(o, filePrefix, subject, updateALLEEG)
            success = false;
            ALLEEG = [];
            EEG = [];
            
            try
                updateALLEEG = nargin < 4 || any(logical(updateALLEEG));
                [~, filePath, fileName] = o.getProcessedImportFile(filePrefix, subject);

                if ~updateALLEEG
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                else
                    [ALLEEG, ~, ~, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, false);
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                    [ALLEEG, EEG, ~] = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, 0);
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
                end
                success = true;
            catch 
                WTLog().except(me);
            end 

            if ~success 
                WTLog().err('Failed to load processed import related to subject ''%s''', subject);
            end
        end

        function [success, fullPath, EEG] = writeProcessedImport(o, filePrefix, subject,  EEG)
            success = false;        
            try
                [fullPath, filePath, fileName] = o.getProcessedImportFile(filePrefix, subject);
                success = WTUtils.mkdir(filePath);
                if ~success
                    WTLog().err('Failed to make dir ''%s''', filePath);
                else
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
                    EEG = WTUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_saveset', EEG,  'filename', fileName, 'filepath', filePath);
                    success = true;
                end
            catch me
                WTLog().except(me);
            end
        end

        function setName = getConditionSet(~, filePrefix, subject, condition)
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
            catch me
                WTLog().except(me)
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
                WTLog().except(me);
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
            extension = WTUtils.ifThenElse(any(logical(perSubject)), ...
                WTIOProcessor.PerSbjGrandAvgFileExt,  WTIOProcessor.GrandAvgFileExt);
            fileName = strcat(condition, '_bc-', wType, extension);
            filePath = o.GrandAvgDir;
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeGrandAverage(o, condition, wType, perSubject, varargin)
            success = false;
            fullPath = [];
           
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
                WTLog().except(me);
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
                WTLog().except(me);
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
                WTLog().except(me);
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

        function subject = getSubjectFromPath(o, path) 
            [analysisDir, subjectSubDir] = WTUtils.splitPath(path, 1);
            analysisAbsPath = WTUtils.getAbsPath(analysisDir);
            subject = [];
            if ~strcmp(analysisAbsPath, o.AnalysisDir) 
                return
            end
            match = regexp(subjectSubDir, o.SubjAnalysisSubDirRe, 'once', 'names');
            if isempty(match)
                return
            end
            subject = match.subject;
        end

        function is = isGrandAvgDir(o, path)
            [analysisDir, grandAvgSubDir] = WTUtils.splitPath(path, 1);
            analysisAbsPath = WTUtils.getAbsPath(analysisDir);
            is = strcmp(analysisAbsPath, o.AnalysisDir) && ...
                 strcmp(grandAvgSubDir, o.GrandAvgSubDir);
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