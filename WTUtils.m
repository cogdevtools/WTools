classdef WTUtils

    methods (Static, Access=private)
        function [interpreter, msg] = setDlgMsg(fontSize, fmt, varargin)
            interpreter = struct('Interpreter', 'tex', 'WindowStyle', 'modal');
            fontSizeFmt = sprintf('\\\\fontsize{%d}', fontSize);
            msg = sprintf([fontSizeFmt fmt], varargin{:});
        end
    end

    methods (Static)
        function is = isa(obj, metaClass)
            if ~isa(metaClass, 'meta.class')
                wtLog.excpt('BadValueType','Not a meta class');
            end
            is = isa(obj, metaClass.Name);
        end

        function mustBeA(obj, metaClass)
            is = WTUtils.isa(obj, metaClass);
            if ~is
                wtLog.excpt('BadValueType','Bad value type: expected ''%s'', got ''%s''', ...
                    metaClass.Name, class(obj));
            end
        end

        function varargout = execFunctions(varargin) 
            varargout = cell(nargin/2, 1);
            for i = 1:2:nargin
                func = varargin{i};
                args = varargin{i+1};
                nOutArgs = nargout(func);
                if nOutArgs > 0
                    varargout{ceil(i/2)} = func(args{:});
                else
                    func(args{:});
                end
            end
        end

        function value = ifThenElseSet(condition, thenValue, elseValue)
            if any(logical(condition))
                value = thenValue;
            elseif nargin > 2
                value = elseValue;
            else 
                value = {};
            end
        end
        
        function [varargout] = ifThenElseDo(condition, thenDo, thenPrms, elseDo, elsePrms)
            if any(logical(condition))
                nOutArgs = nargout(thenDo);
                if nOutArgs > 0
                    [varargout{1:nOutArgs}] = thenDo(thenPrms{:});
                else
                    thenDo(thenPrms{:});
                end
            elseif nargin > 3
                nOutArgs = nargout(thenDo);
                if nOutArgs > 0
                    [varargout{1:nOutArgs}] = elseDo(elsePrms{:});
                else 
                    elseDo(elsePrms{:});
                end
            else
                varargout = {};
            end
        end

        function cells = argsName(varargin) 
            cells = cellfun(@inputname, num2cell(1:nargin), 'UniformOutput', false);
        end

        function quoted = quote(str) 
            quoted = sprintf('''%s''', char(str));
        end


        function cells = quoteMany(varargin)
            cells = cellfun(@WTUtils.quote, varargin, 'UniformOutput', false);
        end

        function [prefix, tail, split] = splitPath(path, stripTrailingSep) 
            if nargin > 1 && stripTrailingSep
                rsPath = strip(path, 'right', filesep);
                tokens = strsplit(rsPath, filesep, 'CollapseDelimiters', true);
            else
                tokens = strsplit(path, filesep, 'CollapseDelimiters', true);
            end
            if nargout > 1
                tail = tokens{end};
            end
            tokens(end) = [];
            prefix = '';
            split = ~isempty(tokens);
            if split
                prefix = char(join(tokens, filesep)); % do not use fullfile as it ignores leading ''
            end
        end

        function tail = getPathTail(path)
            [~, tail] = WTUtils.splitPath(path);
        end

        function prefix = getPathPrefix(path)
            prefix = WTUtils.splitPath(path);
        end

        function [absPath, success] = getExistingAbsPath(path, noException)
            success = true;
            absPath = [];
            if isfolder(path)
                d = dir(path);
                absPath = d(1).folder;
            elseif isfile(path)
                d = dir(path);
                absPath = fullfile(d(1).folder, d(1).name);
            elseif nargin < 2 || ~noException 
                WTLog().excpt('WTUtils:NotExistingPath', 'Path ''%s'' does not exist', path);
            else
                success = false;
            end
        end

        function absPath = getAbsPath(path)
            absPath = [];
            if isempty(path)
                return
            end
            tails = {};
            while true
                [absPath, success] = WTUtils.getExistingAbsPath(path, true);
                if success
                    absPath = fullfile(absPath, tails{:});
                    break
                end
                [path, tail, split] = WTUtils.splitPath(path, false);
                if ~isempty(tail)
                    tails = [tails tail];
                end
                if isempty(path)
                    if split
                        absPath = [filesep fullfile(tails{:})];
                    else
                        absPath = fullfile(pwd, tails{:});
                    end
                    break
                end 
            end
        end

        % As mkdir but suppress the warning on existing directories
        function status = mkdir(dirName)
            [status, ~] = mkdir(dirName);
        end

        function name = getFileNamePart(fname)
            [~,name,~] = fileparts(fname);
        end

        function response = fileExist(fnamePart, varargin)
            fname = fullfile(fnamePart, varargin{:});
            response = exist(fname, 'file');
        end

        function response = dirExist(fnamePart, varargin)
            dname = fullfile(fnamePart, varargin{:});
            response = exist(dname, 'dir');
        end

        function success = writeTxtFile(dirName, fileName, mode, varargin)
            success = false;
            fullName = [];
            try
                if nargin < 4
                    varargin = {''};
                end
                if ~WTUtils.dirExist(dirName) && ~mkdir(dirName)
                    wtLog.err('Failed to make dir ''%s''', dirName);
                    return
                end
                fullName = fullfile(dirName, fileName);
                file = fopen(fullName, mode, 'native', 'UTF-8');
                if file >= 0 
                    text = join(varargin, '\n');
                    fprintf(file, strcat(text{1}, newline));
                    fclose(file);
                    success = true;
                end
            catch me
                wtLog.mexcpt(me);
            end
            if ~success 
                wtLog.err('Failed to write text to file ''%s''', WTUtils.ifThenElseSet(isempty(fullName), '<?>', fullName))
            end
        end

        % varargin must be strings
        function success = saveTo(dirName, fileName, varargin)
            success = false;
            targetFile = [];
            wtLog = WTLog();
            try
                if isempty(dirName)
                    [dirName, fileName] = WTUtils.splitPath(fileName);
                end
                if ~WTUtils.dirExist(dirName) && ~mkdir(dirName)
                    wtLog.err('Failed to make dir ''%s''', dirName);
                    return
                end
                targetFile = fullfile(dirName, fileName);
                args = [targetFile varargin];
                args = WTUtils.quoteMany(args{:});
                cmd = sprintf('save(%s)', char(join(args, ',')));
                evalin('caller', cmd);
                success = true;
            catch me
                wtLog.mexcpt(me);
                wtLog.err('Failed to save workspace variables in file ''%s''', WTUtils.ifThenElseSet(isempty(targetFile), '<?>', targetFile));
            end
        end

        % Examples:
        %   Supposing 'file' contains a struct S with fields a, b, c, c
        %   [~, a] = loadFrom('file') => S
        %   [~, a, b, c] = loadFrom('file', 'a', 'b', 'c') => S.a, S.b , S.c
        %   [~, a, b, c] = loadFrom('file', 'a') => S.a, {} ,{}
        %   [~, a, b] = loadFrom('file', 'a', 'b', 'c') => S.a, struct(b: S.b, c: S.c)
        % If varargin contains -regexp, then only the first varargout will be valued with 
        % a struct containing all the matching fields. 
        % Differently from 'load', non existing fields are not accepted and cause error, 
        % not a warning.
        function [success, varargout] = loadFrom(fileName, varargin)
            success = true;
            if nargout <= 1
                return
            end
            varargout = cell(1, nargout-1); 
            try
                args = [fileName varargin];
                args = WTUtils.quoteMany(args{:});
                cmd = sprintf('load(%s)', char(join(args, ',')));
                result = evalin('caller', cmd);

                argsAreRegExp = any(strcmp('-regexp', varargin));

                if nargin <= 1 || argsAreRegExp
                    varargout{1} = result;
                    return
                end

                args = varargin(:);
                args(strcmp(args, '-mat')) = [];
                args(strcmp(args, '-ascii')) = [];
                nArgs = length(args);

                if nArgs == 0 
                    varargout{1} = result;
                    return
                end

                nMinArgs = min(nargout-1, nArgs);
                
                for i = 1:nMinArgs-1
                    varargout{i} = result.(args{i});
                    result = rmfield(result,  args{i});
                end
                if nargout-1 == nArgs
                    varargout{nMinArgs} = result.(args{nMinArgs});
                else % return what's left in the struct
                    varargout{nMinArgs} = result;
                end                
            catch me
                success = false;
                WTLog().mexcpt(me).err('Failed to load from file ''%s''',  WTUtils.ifThenElseSet(ischar(fileName), fileName, '<?>'));
            end
        end

        function hlpDlg(title, fmt, varargin)
            [interpreter, text] = WTUtils.setDlgMsg(14, fmt, varargin{:});
            hd = helpdlg(text, strcat('[WTools] ', title), interpreter);
            uiwait(hd);
        end

        function errDlg(title, fmt, varargin)
            [interpreter, text] = WTUtils.setDlgMsg(14, fmt, varargin{:});
            ed = errordlg(text, strcat('[WTools] ', title), interpreter);
            uiwait(ed);
        end

        function wrnDlg(title, fmt, varargin)
            [interpreter, text] = WTUtils.setDlgMsg(14, fmt, varargin{:});
            wd = warndlg(text, strcat('[WTools] ', title), interpreter);
            uiwait(wd);
        end

        function msgBox(title, fmt, varargin)
            [interpreter, text] = WTUtils.setDlgMsg(14, fmt, varargin{:});
            mb = msgbox(text, strcat('[WTools] ', title), interpreter);
            uiwait(mb);
        end

        function msgBoxIf(cnd, title, fmt, varargin)
            if cnd 
                WTUtils.msgBox(title, fmt, varargin{:})
            end
        end

        function retDir = uiGetDir(startPath, msg, varargin)
            if nargin > 1
                WTUtils.msgBoxIf(ismac, 'Select a directory', msg, varargin{:});
                retDir = uigetdir(startPath, msg, varargin{:});
            else 
                retDir = uigetdir(startPath);
            end
        end
        
        function [fileNames, filesDir, filterIdx] = uiGetFiles(filter, msg, varargin)
            if nargin > 1
                WTUtils.msgBoxIf(ismac, 'Select file(s)', msg, varargin{:});
                [fileNames, filesDir, filterIdx] = uigetfile(filter, msg, varargin{:});
            else 
                [fileNames, filesDir, filterIdx] = uigetfile(filter);
            end
            if isscalar(fileNames) 
                fileNames = {};
            elseif ischar(fileNames) 
                fileNames = {fileNames};
            end
        end

        function [selection, indexes] = stringsSelectDlg(prompt, list, single, confirm, varargin)
            if ~WTValidations.isALinearCellArrayOfNonEmptyString(list)
                WTLog.expt('BadArg', 'Bad argument type or value: list');
            end

            selection = list;
            indexes = WTUtils.ifThenElseSet(length(list) == 1, 1, []);
            confirm =  nargin > 3 && any(logical(confirm));
            
            if isempty(list) || (length(list) < 2 && ~confirm)
                return
            end

            mode = WTUtils.ifThenElseSet(nargin > 2 && any(logical(single)), 'single', 'multiple');
            prompt = strrep(prompt, '\n', newline);
            prompt = splitlines(prompt)';

            [indexes, ok] = listdlg(varargin{:}, 'PromptString', prompt, 'SelectionMode', mode, 'ListString', list);
            if ~ok
                selection = {};
                return 
            end 
            selection = list(indexes);
        end

        function found = eeglabDep(fname)
            if nargin == 0
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
                    addpath(eeglabRoot);
                    wtLog.evalcLog(WTLog.LevelInf, 'EEGLAB', 'eeglab nogui');
                    found = true;
                catch me
                    wtLog.mexcpt(me);
                end
            end

            if ~found 
                wtLog.err('Try to add manually eeglab''s root dir to matlab''s and run ''eeglab nogui''...');  
            end
        end

        % When 'safeMode' is true, exceptions are trapped and the first parameter returned is 'success'
        function varargout = eeglabRun(logLevel, safeMode, varargin) 
            safeMode = any(logical(safeMode));
            varargout = cell(nargout,1);
            cmdArgOfs = WTUtils.ifThenElseSet(safeMode, 2, 1);
            wtLog = WTLog();
            warnState = warning;
            me = [];
            warning('off', 'all');
            
            try
                if nargin < 3 % no argument, just run eeglab by default
                    [varargout{cmdArgOfs:end}] = wtLog.evalcLog(logLevel, 'EEGLAB', 'eeglab');
                else
                    cmdStr = sprintf('%s(varargin{2:length(varargin)});', varargin{1});
                    [varargout{cmdArgOfs:end}] = wtLog.evalcLog(logLevel, 'EEGLAB', cmdStr);
                end
            catch me
                wtLog.err('Failed to run eeglab command...');
            end

            warning(warnState);
            if safeMode 
                varargout{1} = isempty(me);
            elseif ~isempty(me)
                wtLog.mexcpt(me, true);
            end
        end

        function varargout = eeglabInputMask(varargin)
            if ~WTUtils.eeglabDep('inputgui.m') 
                WTLog().excpt('WTUtils:EEGLABDependency', 'Can''t find ''inputgui.m''');
            end
            varargout = cell(nargout,1);
            [varargout{:}] = WTUtils().eeglabRun(WTLog.LevelDbg, false, 'inputgui', varargin{:});
        end

        function varargout = eeglabMsgDlg(title, fmt, varargin)
            varargout = cell(nargout,1);
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
                [varargout{:}] = WTUtils.eeglabInputMask('geometry', geom, 'uilist', prms, 'title', tit);
            catch
                WTLog().err('Failed to display on GUI the following msg:\n\nTitle: %s\nMessage: %s', title, msg);
            end
        end

        function ok = eeglabBinaryDlg(title, okStr, cancelStr, fmt, varargin)
            legend = {};
            if ~isempty(cancelStr)
                legend = [legend {sprintf('Cancel = %s', cancelStr)}];
            end
            if ~isempty(okStr)
                legend = [legend {sprintf('Ok = %s', okStr)}];
            end
            if ~isempty(legend)
                fmt = strcat(fmt, sprintf('\n[ %s ]', char(join(legend, ' | '))));
            end
            [~, ~, strHalt] = WTUtils.eeglabMsgDlg(title, fmt, varargin{:});
            ok = strcmp(strHalt,'retuninginputui');
        end     

        function yes = eeglabYesNoDlg(title, fmt, varargin)
            yes = WTUtils.eeglabBinaryDlg(title, 'YES', 'NO', fmt, varargin{:});
        end

        % module: without trailing .m
        function [success, varargout] = readModule(dir, module, varargin) 
            if (nargin > 2 && nargout ~= (nargin - 1)) || (nargin == 2 && nargout ~= 2) || nargin < 2
                WTLog().excpt('WTUtils:BadArgument', 'Input/output args number mismatch');
            end
            success = true;
            varargout = cell(nargout-1,1);
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
                    [varargout{:}] = ws.popToVars(varargin{:});
                end
            catch me
                WTLog().mexcpt(me);
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