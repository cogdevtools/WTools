% Copyright (C) 2024 Eugenio Parise, Luca Filippin
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.

classdef WTDialogUtils 

    properties (Constant, Hidden, Access=public)
        WToolsDialogTitlePrefix = '[WTools]'
    end

    methods (Static, Access=private)

        function title = formatTitle(title) 
            title = [WTDialogUtils.WToolsDialogTitlePrefix ' ' title];
        end

        function [options, msg] = setDlgOptions(fmt, varargin)
            options = struct();
            options.Resize = 'on';
            options.Interpreter = 'tex';
            options.WindowStyle = 'modal';
            if ismac()
                fontSize = 14;
                fontName = 'Helvetica';
            else
                fontSize = 12;
                fontName = 'MS Sans Serif';
            end
            fontNameFmt = sprintf('\\fontname{%s}', fontName);
            fontSizeFmt = sprintf('\\fontsize{%d}', fontSize);
            msg = WTCodingUtils.ifThenElse(isempty(varargin), fmt, @()sprintf(fmt, varargin{:}));
            % Escape Tex control chars + replace \n with newline. Note that the order of char counts:
            % The \ must be replaced before the other chars but after \n 
            msg = regexprep(msg, { '\\n',   '\\',   '\{' , '\}' , '\^', '_'  }, ...
                                 { newline, '\\\\', '\\{', '\\}', '\\^', '\\_' });
            % Unfortunately tex formatting count as part of the text hence affecting how the msg is 
            % broken into lines and displayed. To workaround that, I added a newline after the tex 
            % command and after the end of the actual message (to re-center it vertically).
            msg = [ fontNameFmt fontSizeFmt newline msg newline ];
        end

    end

    methods(Static)

        function hlpDlg(title, fmt, varargin)
            [options, text] = WTDialogUtils.setDlgOptions(fmt, varargin{:});
            uiwait(helpdlg(text, WTDialogUtils.formatTitle(title), options));
        end

        function errDlg(title, fmt, varargin)
            [options, text] = WTDialogUtils.setDlgOptions(fmt, varargin{:});
            uiwait(errordlg(text, WTDialogUtils.formatTitle(title), options));
        end

        function wrnDlg(title, fmt, varargin)
            [options, text] = WTDialogUtils.setDlgOptions(fmt, varargin{:});
            uiwait(warndlg(text, WTDialogUtils.formatTitle(title), options));
        end

        function msgBox(title, fmt, varargin)
            [options, text] = WTDialogUtils.setDlgOptions(fmt, varargin{:});
            uiwait(msgbox(text, WTDialogUtils.formatTitle(title), options));
        end
        
        function choice = askDlg(title, fmt, fmtArgs, choices, defaultchoice)
            [options, text] = WTDialogUtils.setDlgOptions(fmt, fmtArgs{:});
            options.Default = defaultchoice;
            choice = questdlg(text, WTDialogUtils.formatTitle(title), choices{:}, options);
        end

        function msgBoxIf(cnd, title, fmt, varargin)
            if cnd 
                WTDialogUtils.msgBox(title, fmt, varargin{:})
            end
        end

        % uiGetDir() select a directory (starting from startPath). Optionally it checks that the 
        % selected directory doesn't match the regular expresson provided with the parameter excludeDirs.
        function retDir = uiGetDir(startPath, msg, varargin)
            argParser = inputParser();
            argParser.CaseSensitive = true;
            argParser.KeepUnmatched = true;
            validateExcludeDirs = @(v)WTValidations.isLinearCellArrayOfChar(v) || WTValidations.isChar(v);
            addParameter(argParser, 'excludeDirs', {}, validateExcludeDirs);
            argsToParse = WTCodingUtils.ifThenElse(mod(length(varargin), 2), @()varargin(1:end-1), @()varargin); 
            parse(argParser, argsToParse{:}); 
            excludeDirs = WTCodingUtils.ifThenElse(ischar(argParser.Results.excludeDirs), ...
                {{argParser.Results.excludeDirs}}, @()argParser.Results.excludeDirs);
            varargin = WTCodingUtils.popOptionFromArgs(varargin, 'excludeDirs'); 
            WTDialogUtils.msgBoxIf(ismac, 'Select a directory', msg);

            while true
                if nargin > 1
                    retDir = uigetdir(startPath, msg, varargin{:});
                else 
                    retDir = uigetdir(startPath);
                end
                if ~ischar(retDir)
                    return
                end
                if ~isempty(excludeDirs) && ...
                    any(cell2mat(cellfun(@(d)~isempty(regexp(retDir, char(d), 'once')), excludeDirs, 'UniformOutput', false)))
                    WTDialogUtils.wrnDlg('', 'Only select directories not matching the following regular expression(s):\n\n  - %s', char(join(excludeDirs,'\n  - ')));
                    continue
                end
                break
            end
        end

        % uiGetFiles() select min/maxFiles (<= 0 ignored) files applying files type 'filter'.
        % msg is the title of the dialog. varargin are any list of parameters accepted by 
        % matlab uigetfile + an extra optional parameter restrictToDirs which must be either 
        % a char array or a cell array of char arrays whose elements are regular expressions 
        % one of which at least the directory of the selected file matches.
        function [fileNames, filesDir, filterIdx] = uiGetFiles(filter, minFiles, maxFiles, msg, varargin)
            argParser = inputParser();
            argParser.CaseSensitive = true;
            argParser.KeepUnmatched = true;
            validateRestrictToDirs = @(v)WTValidations.isLinearCellArrayOfChar(v) || WTValidations.isChar(v);
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
                    WTDialogUtils.wrnDlg('', 'Only select files within the directories matching the following regular expression(s):\n\n  - %s', char(join(restrictToDirs,'\n  - ')));
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
            WTValidations.mustBeLinearCellArrayOfNonEmptyChar(list);
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