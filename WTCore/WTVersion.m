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

classdef WTVersion

    properties(Constant)
        Maj   = 2
        Min   = 0
        Patch = 0
        ReleaseDate = datetime(2023,12,31,0,0,0)
    end

    methods
        function val = getVersionShortStr(o) 
            val = sprintf('%d.%d', o.Maj,  o.Min);
        end

        function val = getVersionStr(o) 
            val = sprintf('%d.%d.%d',  o.Maj,  o.Min, o.Patch);
        end

        function val = getReleaseDateStr(o) 
            val = char(datetime(o.ReleaseDate, 'Format', 'MMMM y'));
        end
    end
end