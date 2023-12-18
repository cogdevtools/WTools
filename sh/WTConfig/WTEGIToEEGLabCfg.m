classdef WTEGIToEEGLabCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        Trigger(1,1) uint16
    end

    methods
        function o = WTEGIToEEGLabCfg(ioProc)
            o@WTConfigStorage(ioProc, 'trigger.m');
            o.default();
        end

        function default(o) 
            o.Trigger = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                o.Trigger = str2double(cells{1});
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.GenericCellsFieldArgs(o.FldDefaultAnswer, WTFormatter.FmtIntStr, o.Trigger);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
