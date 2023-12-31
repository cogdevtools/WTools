classdef WTConfigStorage < matlab.mixin.Copyable

    properties(Access=private)
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