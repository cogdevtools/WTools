% eegplugin_wtools() - EEGLAB plugin for wavelet analysis and plots
%
% Usage:
%   >> eegplugin_wtools(fig);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%
% Author: Eugenio Parise & Luca Filippin, University of Trento, Italy, 2023

% -------------------------------------------------------------------------
% Copyright (C) 2023 Eugenio Parise & Luca Filippin, University of Trento
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
% -------------------------------------------------------------------------

function vers = eegplugin_wtools(fig, tryStrs, catchStrs)
    if nargin < 1
        error('eegplugin_wtools requires figure argument');
    end

    cwd = pwd();
    thisFileDir = fileparts(mfilename('fullpath'));
    cd(fullfile(thisFileDir, 'WTCore'));
    vers = WTVersion().getVersionStr();
    cd(cwd);   
    toolsMenu = findobj(fig, 'tag', 'tools');
    createWToolsMenu(toolsMenu);
    setMenuUserData(toolsMenu, 'startup', 'on');
end

function createWToolsMenu(parentMenu) 
    wtMenu = uimenu(parentMenu, ...
        'label', 'WTools (wavelet analysis)', ...
        'tag', 'WTools', ...
        'userdata', 'startup:on', ...
        'separator', 'on');

    wtMenuRun = uimenu(wtMenu, ...
        'label', 'Run', ...
        'tag', 'WToolsRun', ...
        'userdata', 'startup:on');

    wtMenuClose = uimenu(wtMenu, ...
        'label', 'Close', ...
        'tag', 'WToolsClose', ...
        'userdata', 'startup:off');

    wtMenuConfigure = uimenu(wtMenu, ...
        'label', 'Configure', ...
        'tag', 'WToolsConfigure', ...
        'userdata', 'startup:on');

    set(wtMenuRun, 'callback', {@wtRun, wtMenuClose});
    set(wtMenuClose, 'callback', @wtClose);
    set(wtMenuConfigure, 'callback',  @wtConfigure);
end

function wtRun(~, ~, menuClose) 
    wtools('no-splash');
    menuClose.Enable = true;
end 

function wtClose(menuClose, ~) 
    if menuClose.Enable
        wtools('force-close');
        menuClose.Enable = false;
    end
end 

function wtConfigure(~, ~) 
    wtools('configure');
end 

function hMenu = setMenuUserData(hMenu, flag, value)
    userDataItems = split(hMenu.UserData, ';')';
    flag = [flag ':'];
    idx = startsWith(userDataItems, flag);
    if ~isempty(idx)
        userDataItems{idx} = [flag value];
    else
        userDataItems = [ [flag value] userDataItems ]; 
    end
    hMenu.UserData = char(join(userDataItems, ';'));
end