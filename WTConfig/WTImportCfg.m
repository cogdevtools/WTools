classdef WTImportCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldImport = 'export'
    end

    properties
        ImportDirectory char 
    end

    methods
        function o = WTImportCfg(ioProc)
            o@WTConfigStorage(ioProc, 'exported.m');
            o.default();
        end

        function default(o) 
            o.ImportDirectory = '';
        end

        function success = load(o) 
            [success, impdir] = o.read(o.FldImport);
            if ~success
                return
            end
            try
                o.ImportDirectory = impdir;
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.GenericCellsFieldArgs(o.FldImport, WTFormatter.FldStr, o.ImportDirectory);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
