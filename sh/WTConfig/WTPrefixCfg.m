classdef WTPrefixCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldFileName = 'filename'
    end

    properties
        FilesPrefix char
    end

    methods
        function o = WTPrefixCfg(ioProc)
            o@WTConfigStorage(ioProc, 'filenm.m');
            o.FilesPrefix = '';
        end

        function default(o) 
            o.FilesPrefix = '';
        end
        
        function success = load(o) 
            [success, pfx] = o.read(o.FldFileName);
            if ~success
                return
            end
            try
                o.FilesPrefix = pfx;
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.StringCellsFieldArgs(o.FldFileName, strcat(o.FilesPrefix, '_'));
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
