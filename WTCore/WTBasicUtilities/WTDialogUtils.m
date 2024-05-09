classdef WTDialogUtils 

    methods (Static, Access=private)

        function [options, msg] = setDlgOptions(fontSize, fmt, varargin)
            options = struct();
            options.Resize = 'on';
            options.Interpreter = 'tex';
            options.WindowStyle = 'modal';
            fontSizeFmt = sprintf('\\fontsize{%d}', fontSize);
            msg = WTCodingUtils.ifThenElse(isempty(varargin), fmt, @()sprintf(fmt, varargin{:}));
            % Escape Tex control chars + replace \n with newline. Note that the order of char counts:
            % The \ must be replaced before the other chars but after \n 
            msg = regexprep(msg, { '\\n',   '\\',   '\{' , '\}' , '\^'  }, ...
                                 { newline, '\\\\', '\\{', '\\}', '\\^' });
            msg = [ fontSizeFmt  msg ];
        end

    end

    methods(Static)

        function hlpDlg(title, fmt, varargin)
            [options, text] = WTDialogUtils.setDlgOptions(14, fmt, varargin{:});
            uiwait(helpdlg(text, strcat('[WTools] ', title), options));
        end

        function errDlg(title, fmt, varargin)
            [options, text] = WTDialogUtils.setDlgOptions(14, fmt, varargin{:});
            uiwait(errordlg(text, strcat('[WTools] ', title), options));
        end

        function wrnDlg(title, fmt, varargin)
            [options, text] = WTDialogUtils.setDlgOptions(14, fmt, varargin{:});
            uiwait(warndlg(text, strcat('[WTools] ', title), options));
        end

        function msgBox(title, fmt, varargin)
            [options, text] = WTDialogUtils.setDlgOptions(14, fmt, varargin{:});
            uiwait(msgbox(text, strcat('[WTools] ', title), options));
        end
        
        function choice = askDlg(title, fmt, fmtArgs, choices, defaultchoice)
            [options, text] = WTDialogUtils.setDlgOptions(14, fmt, fmtArgs{:});
            options.Default = defaultchoice;
            choice = questdlg(text, strcat('[WTools] ', title), choices{:}, options);
        end

        function msgBoxIf(cnd, title, fmt, varargin)
            if cnd 
                WTDialogUtils.msgBox(title, fmt, varargin{:})
            end
        end

        function retDir = uiGetDir(startPath, msg, varargin)
            if nargin > 1
                WTDialogUtils.msgBoxIf(ismac, 'Select a directory', msg);
                retDir = uigetdir(startPath, msg, varargin{:});
            else 
                retDir = uigetdir(startPath);
            end
        end

        % uiGetFiles() select min/maxFiles (<= 0 ignored) files applying files type 'filter'.
        % msg is the title of the dialog. varargin are any list of paramters accepted by 
        % matlab uigetfile + an extra optional parameter restrictToDirs which must be either 
        % a char array or a cell array of char arrays whose elements are regular expressions 
        % one of which at least the directory of the selected file matches.
        function [fileNames, filesDir, filterIdx] = uiGetFiles(filter, minFiles, maxFiles, msg, varargin)
            argParser = inputParser();
            argParser.CaseSensitive = true;
            argParser.KeepUnmatched = true;
            validateRestrictToDirs = @(v)WTValidations.isALinearCellArrayOfString(v) || ischar(v);
            addParameter(argParser, 'restrictToDirs', {}, validateRestrictToDirs);
            argsToParse = WTCodingUtils.ifThenElse(mod(length(varargin), 2), @()varargin(1:end-1), @()varargin); 
            parse(argParser, argsToParse{:}); 
            restrictToDirs = WTCodingUtils.ifThenElse(ischar(argParser.Results.restrictToDirs), ...
                {{argParser.Results.restrictToDirs}}, @()argParser.Results.restrictToDirs);
            varargin = WTCodingUtils.popOptionFromArgs(varargin, 'restrictToDirs'); 
            WTDialogUtils.msgBoxIf(nargin > 3 && ismac, 'Select file(s)', msg);

            while true
                if nargin > 3
                    [fileNames, filesDir, filterIdx] = uigetfile(filter, msg, varargin{:});
                else 
                    [fileNames, filesDir, filterIdx] = uigetfile(filter);
                end
                if isscalar(fileNames) 
                    fileNames = {};
                    return
                elseif ischar(fileNames) 
                    fileNames = {fileNames};
                end
                if ~isempty(restrictToDirs) && ...
                   all(cell2mat(cellfun(@(d)isempty(regexp(filesDir, char(d), 'once')), restrictToDirs, 'UniformOutput', false)))
                    WTDialogUtils.wrnDlg('', 'Only select files within the directories matching the following regexp:\n\n  - %s', char(join(restrictToDirs,'\n  - ')));
                    continue
                end
                if minFiles > 0 && length(fileNames) < minFiles
                    WTDialogUtils.wrnDlg('', 'You must select min %d files...', minFiles);
                    continue
                end
                if maxFiles > 0 && length(fileNames) > maxFiles
                    WTDialogUtils.wrnDlg('', 'You can select max %d files...', maxFiles);
                    continue
                end
                break
            end
        end

        function [selection, indexes] = stringsSelectDlg(prompt, list, single, confirm, varargin)
            WTValidations.mustBeALinearCellArrayOfNonEmptyString(list);
            confirm =  nargin > 3 && confirm;
            selection = list;
            indexes = WTCodingUtils.ifThenElse(length(list) == 1, 1, []);
            
            if isempty(list) || (length(list) < 2 && ~confirm)
                return
            end

            mode = WTCodingUtils.ifThenElse(nargin > 2 && single, 'single', 'multiple');
            prompt = strrep(prompt, '\n', newline);
            prompt = splitlines(prompt)';

            [indexes, ok] = listdlg(varargin{:}, 'PromptString', prompt, 'SelectionMode', mode, 'ListString', list);
            if ~ok
                selection = {};
                return 
            end 
            selection = list(indexes);
        end
    end
end