classdef IOProcessor < handle

    properties(Constant,Access=private)
        ConfigSubDir   = 'pop_cfg';
        ImportSubDir   = 'Export';
        WaveletsSubDir = 'Wavelets';

        WaveletsAnalisys         = ''
        WaveletsAnalisys_ITLC    = 'ITLC'
        WaveletsAnalisys_ITPC    = 'ITPC'
        WaveletsAnalisys_ERSP    = 'ERSP'
        WaveletsAnalisys_evWT    = 'evWT'
        WaveletsAnalisys_avWT    = 'avWT'
        WaveletsAnalisys_WTav    = 'WTav'
        WaveletsAnalisys_Induced = 'Induced'
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
                WTLog().err('Can''t read file ''%s''', fName)
            else
                WTLog().err('Can''t read file ''%s'' or some content field(s) are missing: %s', fName, join(varargin{:},','))
            end
        end

        function success = writeModule(dir, file, varargin) 
            fName = fullfile(dir, file);
            success = WTUtils.writeTxtFile(fName, 'wt', varargin{:});
            if ~success 
                WTLog().err('Failed to write file ''%s''', fName)
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
        function o = IOProcessor()
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
            elseif ~mkdir(o.RootDir) 
                wtLog.err('Failed to create root directory: %s', o.RootDir);
            elseif ~mkdir(o.ConfigDir)
                wtLog.err('Failed to create config directory: %s', o.ConfigDir);
            elseif ~mkdir(o.ImportDir)
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
            [success, varargout] = IOProcessor.readModule(o.ConfigDir, cfgFile, varargin{:});
        end

        function success = configWrite(o, cfgFile, varargin) 
            success = IOProcessor.writeModule(o.ConfigDir, cfgFile, varargin{:});
        end

        function [fName, fileExist] = configExist(o, shouldExist, cfgFile)
            [fName, fileExist] = IOProcessor.exist(shouldExist, o.ConfigDir, cfgFile);
        end

        function [filePath, fileName] = getSubjectConditionFile(o, filePrefix, subject, condition)
            fileName = strcat(filePrefix, subject,'_', condition, '.set');
            filePath = fullfile(o.RootDir, subject);
        end

        function [success, EEG] = readSubjectCondition(o, filePrefix, subject, condition)
            success = false;
            fileName = strcat(filePrefix, subject,'_', condition, '.set');
            filePath = fullfile(o.RootDir, subject);
    
            try
                [ALLEEG, EEG, ~, ~] = WTUtils.eeglabRun();
                EEG = WTUtils.eeglabRun('pop_loadset', 'filename', fileName, 'filepath', filePath);
                [~, EEG, ~] = WTUtils.eeglabRun('eeg_store', ALLEEG, EEG, 0);
                EEG = WTUtils.eeglabRun('eeg_checkset', EEG);
                success = true;
            catch 
                EEG = [];
                return
            end 
        end

        function [filePath, fileName] = getWaveletAnalysisFile(o, subject, condition, wType)
            fileName = strcat(subject, '_' , condition, '-', wType, '.mat');
            filePath = fullfile(o.RootDir,  o.WaveletsSubDir, condition);
        end

        function success = writeWaveletsAnalysis(o, subject, condition, wType, varargin)
            success = true;
            if nargin > 5
                switch wType
                    case IOProcessor.WaveletsAnalisys 
                    case IOProcessor.WaveletsAnalisys_ITLC
                    case IOProcessor.WaveletsAnalisys_ITPC 
                    case IOProcessor.WaveletsAnalisys_ERSP
                    case IOProcessor.WaveletsAnalisys_evWT
                    case IOProcessor.WaveletsAnalisys_avWT
                    case IOProcessor.WaveletsAnalisys_WTav
                    case IOProcessor.WaveletsAnalisys_Induced
                    otherwise
                        WTLog().err(['Failed to write wavelets analysis (subject ''%s'', condition ''%s''): ' ... 
                            'unknown type %s'], wType)
                        return
                end
                fileName = strcat(subject, '_' , condition, '-', wType, '.mat');
                filePath = fullfile(o.RootDir,  o.WaveletsSubDir, condition);
                success = WTUtils.saveTo(filePath, fileName, varargin{:});
            end
        end
    end
end
