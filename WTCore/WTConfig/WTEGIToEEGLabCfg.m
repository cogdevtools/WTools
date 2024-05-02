classdef WTEGIToEEGLabCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        TriggerLatency(1,1) single {mustBeFinite, WTValidations.mustBeGTE(TriggerLatency, 0)}
    end

    methods
        function o = WTEGIToEEGLabCfg(ioProc)
            o@WTConfigStorage(ioProc, 'trigger.m');
            o.default();
        end

        function default(o) 
            o.TriggerLatency = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                o.TriggerLatency = WTUtils.str2double(cells{1});
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, WTFormatter.FmtFloatStr, o.TriggerLatency);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
