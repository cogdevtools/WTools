classdef WTSubjectsGrandCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldSubjects = 'subjects'
    end

    properties
        SubjectsList cell {WTValidations.mustBeALinearCellArrayOfNonEmptyString} = {}
    end

    methods
        function o = WTSubjectsGrandCfg(ioProc)
            o@WTConfigStorage(ioProc, 'subjgrand.m');
            o.default();
        end

        function default(o) 
            o.SubjectsList = {};
        end

        function success = load(o) 
            [success, subjs] = o.read(o.FldSubjects);
            if ~success
                return
            end
            try
                o.SubjectsList = subjs;
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.stringCellsField(o.FldSubjects, o.SubjectsList);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end