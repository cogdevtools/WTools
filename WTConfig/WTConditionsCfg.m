classdef WTConditionsCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldConditions = 'conditions'
    end

    properties
        ConditionsList cell {WTValidations.mustBeALinearCellArrayOfNonEmptyString} = {}
    end
    
    methods
        function o = WTConditionsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'cond.m');
            o.default();
        end

        function default(o) 
            o.ConditionsList = {};
        end

        function success = load(o) 
            [success, conds] = o.read(o.FldConditions);
            if ~success
                return
            end
            try
                o.ConditionsList = conds;
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.StringCellsField(o.FldConditions, o.ConditionsList);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
