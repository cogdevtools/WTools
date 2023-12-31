classdef WTIOProcessor < handle

    properties(Constant,Access=private)
        ConfigSubDir   = 'pop_cfg';
        ImportSubDir   = 'Export';
        WaveletsSubDir = 'Wavelets';
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

        ImportFileRe   = '^0\d+.+\.mat$'
    end

    properties(SetAccess=private,GetAccess=public)
        RootDir char
        ConfigDir char
        ImportDir char
        WaveletsDir char
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
            success = WTUtils.writeTxtFile(fName, 'wt', varargin{:});
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
            o.WaveletsDir = '';
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
            o.WaveletsDir = fullfile(o.RootDir, o.WaveletsSubDir);
            wtLog = WTLog();
            
            if mustExist
                if ~isfolder(o.RootDir)
                    wtLog.err('Root directory doesn''t exist or it''s not a directory: %s', o.RootDir);
                elseif ~isfolder(o.ConfigDir)
                    wtLog.err('Config directory doesn''t exist or it''s not a directory: %s', o.ConfigDir); 
                elseif ~isfolder(o.ImportDir)
                    wtLog.err('Import directory doesn''t exist or it''s not a directory: %s', o.Import); 
                else 
                    success = true;
                end
            elseif ~WTUtils.mkdir(o.RootDir) 
                wtLog.err('Failed to create root directory: %s', o.RootDir);
            elseif ~WTUtils.mkdir(o.ConfigDir)
                wtLog.err('Failed to create config directory: %s', o.ConfigDir);
            elseif ~WTUtils.mkdir(o.ImportDir)
                wtLog.err('Failed to create import directory: %s', o.ImportDir);
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

        function importDir = getImportDir(o) 
            importDir = fullfile(o.RootDir, o.ImportSubDir);
        end

        function isValid = isValidImportFile(o, fileName)
            matchIdx = regexp(fileName, o.ImportFileRe, 'ONCE');
            isValid = ~isempty(matchIdx);
        end

        function [fullPath, filePath, fileName] = getConditionFile(o, filePrefix, subject, condition)
            fileName = strcat(filePrefix, subject, '_', condition, '.set');
            filePath = fullfile(o.RootDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        function [success, EEG] = loadCondition(o, filePrefix, subject, condition, loadOnly)
            success = false;
            loadOnly = nargin > 4 && any(logical(loadOnly));
            [~, filePath, fileName] = o.getConditionFile(filePrefix, subject, condition);
    
            try
                if loadOnly
                    EEG = WTUtils.eeglabRun('pop_loadset', 'filename', fileName, 'filepath', filePath);
                else
                    [ALLEEG, ~, ~, ~] = WTUtils.eeglabRun();
                    EEG = WTUtils.eeglabRun('pop_loadset', 'filename', fileName, 'filepath', filePath);
                    [~, EEG, ~] = WTUtils.eeglabRun('eeg_store', ALLEEG, EEG, 0);
                    EEG = WTUtils.eeglabRun('eeg_checkset', EEG);
                end
                success = true;
            catch 
                EEG = [];
                return
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
            filePath = fullfile(o.RootDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeBaselineCorrection(o, subject, condition, wType, varargin)
            wtLog = WTLog();
            success = false;
            try
                [fullPath, filePath, fileName] = o.getBaselineCorrectionFile(subject, condition, wType);
                if isempty(fullPath)
                    wtLog.err('Failed to write baseline correction (type ''%s'', subject ''%s'', condition ''%s'')', wType, subject, condition);
                    return
                end
                argsName = [{filePath fileName} varargin];
                argsName = WTUtils.quoteMany(argsName{:});
                cmd = sprintf('WTUtils.saveTo(%s);', char(join(argsName, ',')));
                evalin('caller', cmd);
                success = true;
            catch me
                wtLog.mexcpt(me);
            end
            % cmd = sprintf('evalin(''caller'', ''%s'')', strrep(cmd, '''', ''''''));
            % success = wtLog.evalinLog(cmd);
        end

        function [success, varargout] = loadBaselineCorrection(o, subject, condition, wType, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getBaselineCorrectionFile(subject, condition, wType);
            if isempty(fullPath)
                WTLog().err('Failed to load baseline correction (type ''%s'', subject ''%s'', condition ''%s'')', wType, subject, condition);
                return
            end
            [success, varargout{:}] = WTUtils.loadFrom(fullPath);
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
            filePath = fullfile(o.RootDir,  o.WaveletsSubDir, condition);
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeWaveletsAnalysis(o, subject, condition, wType, varargin)
            wtLog = WTLog();
            success = false;
            try
                [fullPath, filePath, fileName]  = o.getWaveletAnalysisFile(subject, condition, wType);
                if isempty(fullPath)
                    wtLog.err('Failed to write wavelets analysis (type ''%s'', subject ''%s'', condition ''%s'')', wType, subject, condition);
                    return
                end
                argsName = [{filePath fileName} varargin];
                argsName = WTUtils.quoteMany(argsName{:});
                cmd = sprintf('WTUtils.saveTo(%s);', char(join(argsName, ',')));
                evalin('caller', cmd);
                success = true;
            catch me
                wtLog.mexcpt(me);
            end
            % cmd = sprintf('evalin(''caller'', ''%s'')', strrep(cmd, '''', ''''''));
            % success = wtLog.evalinLog(cmd);
        end

        function [success, varargout] = loadWaveletsAnalysis(o, subject, condition, wType, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getWaveletAnalysisFile(subject, condition, wType);
            if isempty(fullPath)
                WTLog().err('Failed to load wavelets analysis (type ''%s'', subject ''%s'', condition ''%s'')', wType, subject, condition);
                return
            end
            [success, varargout{:}] = WTUtils.loadFrom(fullPath);
        end

        function importFiles = getImportFiles(o) 
            dirContent = dir(fullfile(o.RootDir, o.ImportSubDir, '*.mat'));
            importFiles = cell(length(dirContent), 1);
            nFiles = 0;
            for i = 1:length(dirContent)
                if ~dirContent(i).isdir && regexp(dirContent(i).name, o.ImportFileRe) == 1
                    nFiles = nFiles + 1;
                    importFiles{nFiles} = dirContent(i).name;
                end
            end
            importFiles = importFiles(1:nFiles);
        end
    end

    methods(Static)
        % The names of the data files to import should start with the subject number, followed by space and a trailing part
        function subjectsNums = getSubjectNumberFromImport(varargin) 
            wtLog = WTLog();
            fileNames = varargin;
            subjectsNums = zeros(1, length(fileNames)); 
            crntSubjIdx = 0;

            for i = 1:nargin
                name = fileNames{1, i};

                if ~ischar(name) && ~isstring(name)
                    wtLog.warn('Argument %d is not a char array or a string: skipped', i);
                    continue
                end

                name = char(name);
                nameParts = split(name, ' ');
                subjNum = str2double(nameParts{1});

                if isempty(subjNum) || subjNum <= 0
                    wtLog.warn('Data file name should start with a integer > 0 followed by a space (skipped): ''%s''', name);
                    continue
                end

                crntSubjIdx = crntSubjIdx + 1;
                subjectsNums(crntSubjIdx) = subjNum;
            end
            subjectsNums = sort(subjectsNums(1:crntSubjIdx));
        end
    end
end
