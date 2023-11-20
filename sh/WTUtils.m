classdef WTUtils
    
    methods (Static)
        function [prefix, trail] = splitPath(path) 
            rsPath = strip(path, 'right', filesep);
            tokens = strsplit(rsPath, filesep, 'CollapseDelimiters', true);
            if nargout > 1
                trail = tokens{end};
            end
            tokens(end) = [];
            prefix = '';
            if ~isempty(tokens)
                prefix = join(tokens, filesep); % do not use fullfile as it ignores leading ''
                prefix = prefix{1};
            end
        end

        function trail = getPathTrail(path)
            [~, trail] = WTUtils.splitPath(path);
        end

        function prefix = getPathPrefix(path)
            prefix = WTUtils.splitPath(path);
        end

        function absPath = getAbsPath(path)
            if isfolder(path)
                d = dir(path);
                absPath = d(1).folder;
            elseif isfile(path)
                d = dir(path);
                absPath = fullfile(d(1).folder, d(1).name);
            else
                WTLog.excpt('WTUtils:NotExistingPath', 'Path ''%s'' does not exist', path)
            end
        end

        function name = getFileNamePart(fname)
            [~,name,~] = fileparts(fname);
        end

        function d = toolsScriptsDir() 
            fn = mfilename('fullpath');
            d = WTUtils.getPathPrefix(fn);
        end

        function d = toolsDir() 
            d = fullfile(WTUtils.toolsScriptsDir(fn),'..');
        end

        function response = fileExist(fnamePart, varargin)
            fname = fullfile(fnamePart, varargin{:});
            response = exist(fname, 'file');
        end

        function response = dirExist(fnamePart, varargin)
            dname = fullfile(fnamePart, varargin{:});
            response = exist(dname, 'dir');
        end

        function success = writeTxtFile(fname, mode, varargin)
            success = true;
            if nargin > 2
                file = fopen(fname, mode, 'UTF-8');
                if file >= 0 
                    text = join(varargin, '\n');
                    fprintf(file, strcat(text{1}, newline));
                    fclose(file);
                else
                    success = false;
                end
            end
        end

        function hlpDlg(title, fmt, varargin)
            text = sprintf(fmt, varargin{:});
            uiwait(helpdlg(text, strcat('[WTools] ', title)));
        end

        function errDlg(title, fmt, varargin)
            text = sprintf(fmt, varargin{:});
            uiwait(errordlg(text, strcat('[WTools] ', title)));
        end

        function wrnDlg(title, fmt, varargin)
            text = sprintf(fmt, varargin{:});
            uiwait(warndlg(text, strcat('[WTools] ', title)));
        end

        function msgBox(title, fmt, varargin)
            text = sprintf(fmt, varargin{:});
            uiwait(msgbox(text, strcat('[WTools] ', title)));
        end

        function msgBoxIf(cnd, title, fmt, varargin)
            if cnd 
                WTUtils.msgBox(title, fmt, varargin{:})
            end
        end

        function path = uigetdir(startPath, msg, varargin)
            if nargin > 1
                WTUtils.msgBoxIf(ismac, 'Path set', msg, varargin{:});
                path = uigetdir(startPath, msg, varargin{:});
            else 
                path = uigetdir(startPath);
            end
        end
        
        function found = eeglabDep(fname)
            found = false;
            
            if ~isempty(fname)
                found = WTUtils.fileExist(fname);  
                if found
                    return
                end
            end
            
            WTUtils.msgBox('', 'EEGLAB file ''%s'' is required.\nPlease set EEGLAB root directory...', fname);

            while ~found
                eeglabRoot = uigetdir(pwd, 'Set EEGLAB root directory');

                if eeglabRoot == 0 
                    if ~isempty(fname)
                        WTLog.err('eeglab''s file ''%s'' is needed, but user skipped to set eeglab root.', fname);
                    end
                    break
                end
                if ~isempty(fname)
                    pathlist = dir(fullfile(eeglabRoot, '**', fname)); 
                    filelist = pathlist(~[pathlist.isdir]); 
                    if size(filelist, 1) ~= 1 
                        WTUtils.errDlg('', '%s not found (or many found) in %s: retry...', fname, eeglabRoot);
                        continue;
                    end
                end
                try
                    WTLog.evalcLog(WTLog.LevelInf, 'EEGLAB', 'addpath(eeglabRoot)');
                    WTLog.evalcLog(WTLog.LevelInf,'EEGLAB', 'eeglab nogui');
                    found = true;
                catch
                end
            end
            if ~found 
                WTLog.err('Add manually eeglab''s root dir to matlab''s and run ''eeglab nogui''...');
            end
        end

        function varargout = inputgui(varargin)
            found = WTUtils.eeglabDep('inputgui.m');
            varargout = cell(nargout, 1);
            if ~found 
                WTLog.excpt('WTUtils:EEGLABDependency', 'Can''t find ''inputgui.m''')
            end
            [varargout{:}] = inputgui(varargin{:});
        end

        function msggui(title, fmt, varargin)
            title = sprintf('[WTools] %s', title);
            msg = sprintf(fmt, varargin{:});
            msg = strrep(msg, '\n', newline);
            prms = splitlines(msg)';
            geom = cell(length(prms),1);
            for i = 1:length(prms)
                prms{i} = {'style', 'text', 'string', prms{i}};
                geom{i} = 1;
            end
            WTUtils.inputgui( 'geometry', geom, 'uilist', prms, 'title', title);
        end

        % module: without trailing .m
        function [success, varargout] = readModule(dir, module, varargin) 
            if (nargin > 2 && nargout ~= (nargin - 1)) || (nargin == 2 && nargout ~= 2) || nargin < 2
                WTLog.excpt('WTUtils:BadArgument', 'Input/output args number mismatch');
            end
            success = true;
            WTWorkSpace.pushBase(true)
            cwd = pwd;
            try
                cd(dir);
                evalin('base', module);
                WTWorkSpace.pushBase()
                if nargin == 2 
                    varargout{1} = WTWorkSpace.popToStruct();
                else 
                    varargout = cell(nargout-1, 1);
                    [varargout{:}] = WTWorkSpace.popToVars(varargin{:});
                end
            catch me
                WTLog.mexcpt(me);
                varargout = cell(nargout-1, 1);
                success = false;
            end
            cd(cwd)
            WTWorkSpace.popToBase(true)
        end

        % fname: with trailing .m
        function [success, varargout] = readModuleFile(fname, varargin) 
            success = false;
            varargout = cell(nargout-1,1);
            if (nargin > 1 && nargin ~= nargout) || (nargin == 1 && nargout ~= 2) || nargin < 1
                WTLog.excpt('WTUtils:BadArgument', 'Input/output args number mismatch');
            elseif ~isfile(fname) 
                WTLog.err('Not a file or not existing: "%s"', fname);
            else
                [dir, module, ~] = fileparts(fname);
                [success, varargout{:}] = WTUtils.readModule(dir, module, varargin{:});
            end
        end

        function wtOpen()
            WTLog.info('Starting WTools...')
            wtDir = WTUtils.toolsScriptsDir();
            addpath(wtDir);
            if ~ispc
                icaSrc = fullfile(wtDir, 'icadefs.m');
                if WTUtils.fileExist(icaSrc)
                    icaDst = fullfile(wtDir, 'NotActive_icadefs.m'); 
                    success = movefile(icaSrc, icaDst);
                    if ~success 
                        WTLog.err('WTUtils', 'Failed to move icadefs.m')
                    end
                end
            end
        end

        function wtClose()
            WTLog.info('Closing WTools...')
            WTLog.close()
            WTProject.close()
            WTWorkSpace.close()
        end
    end
end