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

classdef WTEEGLabUtils

    properties (Constant)
        MinEEGLabMajorVersionNum = 2019
    end

    methods(Static)
        % eeglabVersionOk assumes that eeglab is accessible and return true only if its version 
        % is greater or equal to the minimum expected by WTools.
        function versionOk = eeglabVersionOk(showDialog)
            try
                [~, versionMaj, ~] = WTEval.evalcLog(WTLog.LevelInf, 'EEGLAB', 'eeg_getversion');
                versionOk = versionMaj >= WTEEGLabUtils.MinEEGLabMajorVersionNum;
            catch me
                wtLog.except(me);
                wtLog.err('Cannot check eeglab version: it might be definitively too old...')
            end
            if ~versionOk && showDialog
                WTDialogUtils.msgBox('', 'EEGLAB version is too old. Minimum required: %d',  WTEEGLabUtils.MinEEGLabMajorVersionNum);
            end
        end

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
                    rehash();
                    WTEval.evalcLog(WTLog.LevelInf, 'EEGLAB', 'eeglab nogui');
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
            if ~WTEEGLabUtils.eeglabDep() || ~WTEEGLabUtils.eeglabVersionOk()
                WTException.eeglabDependency('Can''t find EEGLAB or wrong version').throw();
            end

            varargout = cell(nargout, 1);
            cmdArgOfs = WTCodingUtils.ifThenElse(safeMode, 2, 1);
            warnState = warning('off', 'all');
            varargout{1} = true;

            try
                if nargin < 3 % no argument, just run eeglab by default
                    [varargout{cmdArgOfs:end}] = WTEval.evalcLog(logLevel, 'EEGLAB', 'eeglab(''nogui'')');
                else
                    cmdStr = sprintf('%s(varargin{2:end});', varargin{1});
                    [varargout{cmdArgOfs:end}] = WTEval.evalcLog(logLevel, 'EEGLAB', cmdStr);
                end
                warning(warnState);
            catch me
                warning(warnState);
                WTLog().except(me, false);
                if ~safeMode
                    WTException.evalErr('Failed to run eeglab command').throw();
                end
                varargout{1} = false;
            end
        end

        function varargout = eeglabRunQuiet(safeMode, varargin) 
            if ~WTEEGLabUtils.eeglabDep() || ~WTEEGLabUtils.eeglabVersionOk()
                WTException.eeglabDependency('Can''t find EEGLAB or wrong version').throw();
            end

            varargout = cell(nargout, 1);
            cmdArgOfs = WTCodingUtils.ifThenElse(safeMode, 2, 1);
            warnState = warning('off', 'all');
            varargout{1} = true;

            try
                if nargin < 2 % no argument, just run eeglab by default
                    [varargout{cmdArgOfs:end}] = WTEval.evalcQuiet('eeglab(''nogui'')');
                else
                    cmdStr = sprintf('%s(varargin{2:end});', varargin{1});
                    [varargout{cmdArgOfs:end}] = WTEval.evalcQuiet(cmdStr);
                end
                warning(warnState);
            catch me
                warning(warnState);
                if ~safeMode
                    me.rethrow();
                end
                varargout{1} = false;
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