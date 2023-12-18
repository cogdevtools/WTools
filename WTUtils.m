classdef WTUtils
    
    methods (Static)
        function value = ifThenElse(condition, thenValue, elseValue)
            if logical(condition)
                value = thenValue;
            else
                value = elseValue;
            end
        end

        function quoted = singleQuote(str) 
            quoted = sprintf('''%s''', char(str));
        end

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
                WTLog().excpt('WTUtils:NotExistingPath', 'Path ''%s'' does not exist', path)
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
                file = fopen(fname, mode, 'native', 'UTF-8');
                if file >= 0 
                    text = join(varargin, '\n');
                    fprintf(file, strcat(text{1}, newline));
                    fclose(file);
                else
                    success = false;
                end
            end
        end

        function success = saveTo(dir, fileName, varargin)
            success = false;
            wtLog = WTLog();
            if ~WTUtils.dirExist(dir) && ~mkdir(dir)
                wtLog.err('Failed to make dir ''%s''', dir);
                return
            end
            targetFile = fullfile(dir, fileName);
            try
                args = [targetFile varargin];
                args = cellfun(@WTUtils.singleQuote, args, 'UniformOutput', false);
                cmd = sprintf('save(%s)', char(join(args, ',')));
                evalin('caller', cmd);
                success = true;
            catch me
                wtLog.mexcpt(me)
                wtLog.err('Failed to save workspace (%s) into file ''%s''', char(join(varargin)), targetFile);
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

        function retDir = uiGetDir(startPath, msg, varargin)
            if nargin > 1
                WTUtils.msgBoxIf(ismac, 'Directory path set', msg, varargin{:});
                retDir = uigetdir(startPath, msg, varargin{:});
            else 
                retDir = uigetdir(startPath);
            end
        end
        
        function retFile = uiGetFile(startPath, msg, varargin)
            if nargin > 1
                WTUtils.msgBoxIf(ismac, 'File path set', msg, varargin{:});
                retFile = uigetfile(startPath, msg, varargin{:});
            else 
                retFile = uigetfile(startPath);
            end
        end

        function found = eeglabDep(fname)
            found = false;

            if isempty(fname)
                fname = 'eeglab.m';
            end
            
            found = WTUtils.fileExist(fname);  
            if found
                return
            end
            
            WTUtils.msgBox('', 'EEGLAB file ''%s'' is required.\nPlease set EEGLAB root directory...', fname);
            wtLog = WTLog();

            while ~found
                eeglabRoot = uigetdir(pwd, 'Set EEGLAB root directory');
                
                if eeglabRoot == 0 
                    wtLog.err('eeglab''s file ''%s'' is needed, but user skipped to set eeglab root directory.', fname);
                    break
                end

                pathlist = dir(fullfile(eeglabRoot, '**', fname)); 
                filelist = pathlist(~[pathlist.isdir]); 
                if size(filelist, 1) ~= 1 
                    WTUtils.errDlg('', '%s not found (or many found) in %s: retry...', fname, eeglabRoot);
                    continue;
                end

                try
                    wtLog.evalcLog(WTLog.LevelInf, 'EEGLAB', 'addpath(eeglabRoot)');
                    wtLog.evalcLog(WTLog.LevelInf, 'EEGLAB', 'eeglab nogui');
                    found = true;
                catch
                end
            end
            if ~found 
                wtLog.err('Try to add manually eeglab''s root dir to matlab''s and run ''eeglab nogui''...');
            end
        end

        function varargout = eeglabRun(varargin) 
            varargout = cell(1, nargout-1);
            wtLog = WTLog();
            try
                if nargin == 0 
                    varargin = {'eeglab'};
                end
                eeglabFunc = varargin{1};
                if length(varargin) == 1
                    [varargout{:}] = wtLog.evalcLog(wtLog.LevelInf, 'EEGLAB', eeglabFunc);
                else
                    cmdStr = sprintf('%s(varargin{2:length(varargin)})', eeglabFunc);
                    [varargout{:}] = wtLog.evalcLog(wtLog.LevelInf, 'EEGLAB', cmdStr);
                end
            catch me
                wtLog.err('Failed to run eeglab command...');
                wtLog.mexcpt(me, true);
            end
        end

        function [success, varargout] = eeglabSafeRun(varargin) 
            varargout = cell(1, nargout-1);
            try
                [varargout{:}] = WTUtils.eeglabRun(varargin{:});
                success = true;
            catch
                success = false;
            end
        end

        function varargout = eeglabInputGui(varargin)
            if ~WTUtils.eeglabDep('inputgui.m') 
                WTLog().excpt('WTUtils:EEGLABDependency', 'Can''t find ''inputgui.m''');
            end
            varargout = cell(1, nargout-1);
            [varargout{:}] = WTUtils().eeglabRun('inputgui', varargin{:});
        end

        function eeglabMsgGui(title, fmt, varargin)
            tit = sprintf('[WTools] %s', title);
            msg = sprintf(fmt, varargin{:});
            msg = strrep(msg, '\n', newline);
            prms = splitlines(msg)';
            geom = cell(length(prms),1);
            for i = 1:length(prms)
                prms{i} = {'style', 'text', 'string', prms{i}};
                geom{i} = 1;
            end
            try
                WTUtils.eeglabInputGui('geometry', geom, 'uilist', prms, 'title', tit);
            catch
                WTLog().err('Failed to display on GUI the following msg:\n\nTitle: %s\nMessage: %s', title, msg);
            end
        end

        % module: without trailing .m
        function [success, varargout] = readModule(dir, module, varargin) 
            if (nargin > 2 && nargout ~= (nargin - 1)) || (nargin == 2 && nargout ~= 2) || nargin < 2
                WTLog().excpt('WTUtils:BadArgument', 'Input/output args number mismatch');
            end
            success = true;
            ws = WTWorkspace();
            ws.pushBase(true)
            cwd = pwd;
            try
                cd(dir);
                evalin('base', module);
                ws.pushBase()
                if nargin == 2 
                    varargout{1} = ws.popToStruct();
                else 
                    varargout = cell(nargout-1, 1);
                    [varargout{:}] = ws.popToVars(varargin{:});
                end
            catch me
                WTLog().mexcpt(me);
                varargout = cell(nargout-1, 1);
                success = false;
            end
            cd(cwd)
            ws.popToBase(true)
        end

        % fname: with trailing .m
        function [success, varargout] = readModuleFile(fname, varargin) 
            success = false;
            varargout = cell(nargout-1,1);
            if (nargin > 1 && nargin ~= nargout) || (nargin == 1 && nargout ~= 2) || nargin < 1
                WTLog().excpt('WTUtils:BadArgument', 'Input/output args number mismatch');
            elseif ~isfile(fname) 
                WTLog().err('Not a file or not existing: "%s"', fname);
            else
                [dir, module, ~] = fileparts(fname);
                [success, varargout{:}] = WTUtils.readModule(dir, module, varargin{:});
            end
        end
    end
end