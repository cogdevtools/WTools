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

classdef WTConfigStorage < matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Access=protected)
        IOProc WTIOProcessor
        DataFileName char
    end

    methods
        function o = WTConfigStorage(ioProc, fName)
            mustBeNonempty(fName)
            o.IOProc = ioProc;
            o.DataFileName = fName;
        end
    end

    methods(Access=protected)
        function [success, varargout] = read(o, varargin) 
            varargout = cell(nargout-1, 1);
            [success, varargout{:}] = o.IOProc.configRead(o.DataFileName, varargin{:});
        end

        function success = write(o, varargin) 
            success = o.IOProc.configWrite(o.DataFileName, varargin{:});
        end
    end

    methods
        function dataFileName = getFileName(o, fullName) 
            if nargin > 1 && fullName
                dataFileName = o.IOProc.getConfigFile(o.DataFileName);
            else
                dataFileName = o.DataFileName;
            end
        end

        function fileExist = exist(o)
            [~,fileExist] = o.IOProc.configExist(false, o.DataFileName);
        end
    end
end