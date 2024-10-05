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

function [success, pathsContext] = wtInit
    warning('off', 'all');
    success = true;
    crntDir = pwd();
    pathsContext = [];

    try
        wtoolsRootDir = fileparts(mfilename('fullpath'));
        pathsContext = path();
        addpath(genpath(wtoolsRootDir));
        rehash();
    catch me
        try
            wtLog = WTLog();
            wtLog.except(me);
            wtLog.info('WTools bailed out due to internal error...');
        catch
            display(getReport(me, 'extended'));
            fprintf(2, ['\n+------------------------------------------+\n' ...
                          '|WTools bailed out due to internal error...|\n' ...
                          '+------------------------------------------+\n']);
        end
        if ~isempty(pathsContext)
            path(pathsContext);
            rehash();
        end
        success = false;
    end

    cd(crntDir);
end