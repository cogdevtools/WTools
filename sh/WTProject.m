classdef WTProject < handle

    properties (Constant, Access=private)
        configSubDir = 'pop_cfg'
        importSubDir = 'Export'
        waveletsSubDir = 'Wavelets'
        importFile = 'exported.m'
        prefixFile = 'filenm.m'
        subjGrandFile = 'subjgrand.m'
        subjectsFile = 'subj.m'
        conditionsFile = 'cond.m'
    end

    properties (Access=private)
        rootDir
    end

    methods (Access=private)
        function obj = WTProject()
            obj.rootDir = '';
        end
    end

    methods (Static)

        function set = setRootDir(rootDir, shouldExist)
            obj = instance();
            set = true;
            if nargin < 2
                obj.rootDir = rootDir;
            elseif (shouldExist && ~isfolder(rootDir)) || ...
                (~shouldExist && ~isfolder(rootDir) && ~isfile(rootDir))
                obj.rootDir = rootDir;
            else
                set = false;
            end
        end

        function resetRootDir() 
            obj = instance();
            obj.rootDir = '';
        end

        function set = isRootDirSet()      
            obj = instance();
            set = ~isempty(obj.rootDir); 
        end

        function d = getRootDir()
            obj = instance();
            d = obj.rootDir;
        end

        function d = getCfgDir() 
            obj = instance();
            d = fullfile(obj.rootDir, obj.configSubDir);
        end

        function d = getImportDir() 
            obj = instance();
            d = fullfile(obj.rootDir, obj.importSubDir);
        end

        function d = getWaveletsDir() 
            obj = instance();
            d = fullfile(obj.rootDir, obj.waveletsSubDir);
        end

        function name = getProjectName()
            obj = instance(); 
            name = WTUtils.getPathTrail(obj.rootDir);
        end

        function success = newProject()
            success = false; 
            obj = instance();
            if isempty(obj.rootDir)
                WTLog.err('Project root directoey is undefined');
                return 
            end
            if isfolder(obj.rootDir) || isfile(obj.rootDir)
                WTLog.err('Project root direectory is an existing path: ''%s''', obj.rootDir);
                return
            end
            if ~mkdir(obj.rootDir) || ... 
               ~mkdir(obj.rootDir, obj.configSubDir) || ...
               ~mkdir(obj.rootDir, obj.importSubDir)
               WTLog.err('Failed to create project root & tree: ''%s''', obj.rootDir);
               return
            end
            dst = fullfile(obj.rootDir, obj.configSubDir, obj.importFile);
            txt = sprintf('exportvar = { ''%s'' };', fullfile('.','Export'));
            if ~WTUtils.writeTxtFile(dst, txt)
                WTLog.err('Failed to create ''%s''', dst)
                return
            end
            dst = fullfile(obj.rootDir, obj.configSubDir, obj.prefixFile);
            txt = sprintf('filename = { ''%s_'' };', obj.getProjectName());
            if ~WTUtils.writeTxtFile(dst, txt)
                WTLog.err('Failed to create ''%s''', dst)
                return
            end
            success = true;
        end

        function success = openProject() 
            success = false; 
            obj = instance();
            if isempty(obj.rootDir)
                WTLog.err('Project root directory is undefined');
                return 
            end
            if ~isfolder(obj.rootDir)
                WTLog.err('Project root is not a directory or doesn''exist: ''%s''', obj.rootDir);
                return
            end
            [cfgDir, dirExist] = WTProject.dirCheck(false, obj.configSubDir);
            if ~dirExist 
                WTLog.err('The project cofiguration directory is missing: ''%s'' ', cfgDir);
                return
            end
            [importFile, fileExist] = WTProject.fileCheck(false, obj.configSubDir, obj.importFile);
            if ~fileExist 
                WTLog.err('A project configuration file is missing: ''%s'' ', importFile);
                return
            end
            [prefixFile, fileExist] = WTProject.fileCheck(false, obj.configSubDir, obj.prefixFile);
            if ~fileExist 
                WTLog.err('A project configuration file is missing: ''%s'' ', prefixFile);
                return
            end
            success = true;
        end

        function [pathout, dirExist] = dirCheck(shouldExist, subpath, varargin)
            pathout = fullfile(WTProject.getRootDir(), subpath, varargin{:});
            dirExist = isfolder(pathout);
            if shouldExist && ~dirExist 
                WTLog.excpt('WTProject:NotExistigPath', '"%s" is not a valid Project directory path', pathout, type);
            end
        end
        
        function [pathout, fileExist] = fileCheck(shouldExist, subpath, varargin)
            pathout = fullfile(WTProject.getRootDir(), subpath, varargin{:});
            fileExist = isfile(pathout);
            if shouldExist && ~fileExist 
                WTLog.excpt('WTProject:NotExistigPath', '"%s" is not a valid Project file path', pathout, type);
            end
        end

        function [success, varargout] = readCfgFile(cfgFile, varargin) 
            fname = fullfile(WTProject.configSubDir, cfgFile);
            varargout = cell(nargout-1, 1);
            [success, varargout{:}] = WTUtils.readModuleFile(fname, varargin{:});
            if success 
                return
            end
            if nargin == 1
                WTLog.err('File ''%s'' not found', fname)
            else
                WTLog.err('File ''%s'' not found or missing some content field(s): %s', fname, join(varargin{:},','))
            end
        end

        function [success, varargout] = readFilePrefix(varargin) 
            varargout = cell(nargout-1, 1);
            [success, varargout{:}] = WTProject.readCfgFile(WTProject.prefixFile, varargin{:});
        end

        function [success, varargout] = readSubjectsGrand(varargin) 
            varargout = cell(nargout-1, 1);
            [success, varargout{:}] = WTProject.readCfgFile(WTProject.subjGrandFile, varargin{:});
        end

        function [success, varargout] = readSubjects(varargin) 
            varargout = cell(nargout-1, 1);
            [success, varargout{:}] = WTProject.readCfgFile(WTProject.subjectsFile, varargin{:});
        end

        function [success, varargout] = readConditions(varargin) 
            varargout = cell(nargout-1, 1);
            [success, varargout{:}] = WTProject.readCfgFile(WTProject.conditionsFile, varargin{:});
        end

        function close()
            instance();
            munlock('instance');
        end
    end
end

function obj = instance()
    mlock;
    persistent uniqueInstance
    if nargout == 0 
        uniqueInstance = {};
        return
    end
    if isempty(uniqueInstance)
        obj = WTProject();
        uniqueInstance = obj;
    else
        obj = uniqueInstance;
    end
end