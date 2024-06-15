classdef WTEEGLabUtils

    methods(Static)
        function found = eeglabDep(fileName)
            if nargin == 0
                fileName = 'eeglab.m';
            end
            
            found = WTIOUtils.fileExist(fileName);  
            if found
                return
            end
            
            WTDialogUtils.msgBox('', 'EEGLAB file ''%s'' is required.\nPlease set EEGLAB root directory...', fileName);
            wtLog = WTLog();

            while ~found
                eeglabRoot = uigetdir(pwd, 'Set EEGLAB root directory');
                
                if eeglabRoot == 0 
                    wtLog.err('eeglab''s file ''%s'' is needed, but user skipped to set eeglab root directory.', fileName);
                    break
                end

                pathlist = dir(fullfile(eeglabRoot, '**', fileName)); 
                filelist = pathlist(~[pathlist.isdir]); 

                if size(filelist, 1) ~= 1 
                    WTDialogUtils.errDlg('', '%s not found (or many found) in %s: retry...', fileName, eeglabRoot);
                    continue;
                end

                try
                    addpath(eeglabRoot);
                    WTEval.evalcLog(WTLog.LevelInf, 'EEGLAB', 'eeglab nogui');
                    found = true;
                catch me
                    wtLog.except(me);
                end
            end

            if ~found 
                wtLog.err('Try to add manually eeglab''s root dir to matlab''s and run ''eeglab nogui''...');  
            end
        end

        % When 'safeMode' is true, exceptions are trapped and the first parameter returned is 'success'
        function varargout = eeglabRun(logLevel, safeMode, varargin) 
            varargout = cell(nargout,1);
            cmdArgOfs = WTCodingUtils.ifThenElse(safeMode, 2, 1);
            wtLog = WTLog();
            me = [];
            warnState = warning('off', 'all');
            
            try
                if nargin < 3 % no argument, just run eeglab by default
                    [varargout{cmdArgOfs:end}] = WTEval.evalcLog(logLevel, 'EEGLAB', 'eeglab(''nogui'')');
                else
                    cmdStr = sprintf('%s(varargin{2:length(varargin)});', varargin{1});
                    [varargout{cmdArgOfs:end}] = WTEval.evalcLog(logLevel, 'EEGLAB', cmdStr);
                end
            catch me
                wtLog.err('Failed to run eeglab command...');
            end

            warning(warnState);
            if safeMode 
                varargout{1} = isempty(me);
            elseif ~isempty(me)
                wtLog.except(me, true);
            end
        end

        function varargout = eeglabInputMask(varargin)
            if ~WTEEGLabUtils.eeglabDep('inputgui.m') 
                WTException.eeglabDependency('Can''t find ''inputgui.m''').throw();
            end
            varargout = cell(nargout,1);
            % Update title if defined
            for i = 1:nargin
                if ischar(varargin{i}) && strcmpi(varargin{i}, 'title') && nargin > i && ischar(varargin{i+1})
                    varargin{i+1} = [ WTDialogUtils.WToolsDialogTitlePrefix ' ' varargin{i+1}];
                    break
                end
            end
            [varargout{:}] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'inputgui', varargin{:});
        end

        function varargout = eeglabMsgDlg(title, fmt, varargin)
            varargout = cell(nargout,1);
            msg = sprintf(fmt, varargin{:});
            msg = strrep(msg, '\n', newline);
            prms = splitlines(msg)';
            geom = cell(length(prms),1);

            for i = 1:length(prms)
                prms{i} = {'style', 'text', 'string', prms{i}};
                geom{i} = 1;
            end
            try
                [varargout{:}] = WTEEGLabUtils.eeglabInputMask('geometry', geom, 'uilist', prms, 'title', title);
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
            [~, ~, strHalt] = WTEEGLabUtils.eeglabMsgDlg(title, fmt, varargin{:});
            ok = strcmp(strHalt,'retuninginputui');
        end     

        function yes = eeglabYesNoDlg(title, fmt, varargin)
            yes = WTEEGLabUtils.eeglabBinaryDlg(title, 'YES', 'NO', fmt, varargin{:});
        end
    end
end