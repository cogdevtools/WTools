classdef WTIOUtils

    methods(Static)

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
            [~, tail] = WTIOUtils.splitPath(path);
        end

        function prefix = getPathPrefix(path)
            prefix = WTIOUtils.splitPath(path);
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
                WTException.notExistingPath('Path ''%s'' does not exist', path).throw();
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
                [absPath, success] = WTIOUtils.getExistingAbsPath(path, true);
                if success
                    absPath = fullfile(absPath, tails{:});
                    break
                end
                [path, tail, split] = WTIOUtils.splitPath(path, false);
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

        function response = fileExist(filePart, varargin)
            fileName = fullfile(filePart, varargin{:});
            response = exist(fileName, 'file');
        end

        function response = dirExist(dirPart, varargin)
            dirName = fullfile(dirPart, varargin{:});
            response = exist(dirName, 'dir');
        end

        function success = writeTxtFile(dirName, fileName, mode, varargin)
            success = false;
            fullName = [];
            wtLog = WTLog();

            try
                if nargin < 4
                    varargin = {''};
                end
                if ~WTIOUtils.dirExist(dirName) && ~mkdir(dirName)
                    wtLog.err('Failed to make dir ''%s''', dirName);
                    return
                end
                fullName = fullfile(dirName, fileName);
                file = fopen(fullName, mode, 'native', 'UTF-8');
                if file >= 0 
                    varargin = cellfun(@(a)WTCodingUtils.ifThenElse(iscell(a), char(join(a, '\n')), a), varargin, 'UniformOutput', false);
                    text = join(varargin, '\n');
                    fprintf(file, strcat(text{1}, newline));
                    fclose(file);
                    success = true;
                end
            catch me
                wtLog.except(me);
            end

            if ~success 
                wtLog.err('Failed to write text to file ''%s''', WTCodingUtils.ifThenElse(isempty(fullName), '<?>', fullName));
            end
        end

        % varargin must be strings
        function success = saveTo(dirName, fileName, varargin)
            success = false;
            targetFile = [];
            wtLog = WTLog();
            try
                if isempty(dirName)
                    [dirName, fileName] = WTIOUtils.splitPath(fileName);
                end
                if ~WTIOUtils.dirExist(dirName) && ~mkdir(dirName)
                    wtLog.err('Failed to make dir ''%s''', dirName);
                    return
                end
                targetFile = fullfile(dirName, fileName);
                args = [targetFile varargin];
                args = WTStringUtils.quoteMany(args{:});
                cmd = sprintf('save(%s)', char(join(args, ',')));
                evalin('caller', cmd);
                success = true;
            catch me
                wtLog.except(me);
                wtLog.err('Failed to save workspace variables in file ''%s''', WTCodingUtils.ifThenElse(isempty(targetFile), '<?>', targetFile));
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
                args = WTStringUtils.quoteMany(args{:});
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
                WTLog().except(me).err('Failed to load from file ''%s''',  WTCodingUtils.ifThenElse(ischar(fileName), fileName, '<?>'));
            end
        end

        % module: without trailing .m
        function [success, varargout] = readModule(dir, module, varargin) 
            if (nargin > 2 && nargout ~= (nargin - 1)) || (nargin == 2 && nargout ~= 2) || nargin < 2
                WTException.ioArgsMismatch('Input/output args number mismatch').throw();
            end
            success = true;
            varargout = cell(nargout-1,1);
            ws = WTWorkspace();
            ws.pushBase(true);
            cwd = pwd;
            try
                cd(dir);
                evalin('base', module);
                ws.pushBase();
                if nargin == 2 
                    varargout{1} = ws.popToStruct();
                else 
                    [varargout{:}] = ws.popToVars(varargin{:});
                end
            catch me
                WTLog().except(me);
                success = false;
            end
            cd(cwd)
            ws.popToBase(true);
        end

        % fileName: with trailing .m
        function [success, varargout] = readModuleFile(fileName, varargin) 
            success = false;
            varargout = cell(nargout-1,1);
            if (nargin > 1 && nargin ~= nargout) || (nargin == 1 && nargout ~= 2) || nargin < 1
                WTException.ioArgsMismatch('Input/output args number mismatch').throw();
            elseif ~isfile(fileName) 
                WTLog().err('Not a file or not existing: "%s"', fileName);
            else
                [dir, module, ~] = fileparts(fileName);
                [success, varargout{:}] = WTIOUtils.readModule(dir, module, varargin{:});
            end
        end
    end
end
