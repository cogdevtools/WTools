classdef WTBasicCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldFileName = 'filename'
        FldSourceSystem = 'srcsys'
    end

    properties
        FilesPrefix char {mustBeNonempty} = 'UnnamedProject'
        SourceSystem char 
    end

    methods
        function o = WTBasicCfg(ioProc)
            o@WTConfigStorage(ioProc, 'filenm.m');
            o.default();
        end

        function default(o) 
            o.FilesPrefix = 'UnnamedProject';
            o.SourceSystem = '';
        end
        
        function success = load(o) 
            % For backward compatibility we accept file having only FldFileName...
            [success, pfx, srcSys] = o.read(o.FldFileName, o.FldSourceSystem);
            if ~success
                WTLog().info('Load of ''%s'' failed, maybe for backward compatibility issues: trying with old format...', o.DataFileName);
                [success, pfx] = o.read(o.FldFileName);
                if ~success
                    return
                end
                srcSys = '';
            end
            try
                o.FilesPrefix = pfx;
                o.SourceSystem = srcSys;
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt1 = WTFormatter.StringCellsFieldArgs(o.FldFileName, o.FilesPrefix);
            txt2 = WTFormatter.StringCellsFieldArgs(o.FldSourceSystem, o.SourceSystem);
            success = ~isempty(txt1) && ~isempty(txt2) && o.write(txt1, txt2);
        end
    end
end
