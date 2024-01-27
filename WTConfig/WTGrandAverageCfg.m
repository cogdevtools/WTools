classdef WTGrandAverageCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        UseAllSubjects(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        PerSubjectAgerage(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        Log10Enable(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        EvokedOscillations(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
    end

    methods
        function o = WTGrandAverageCfg(ioProc)
            o@WTConfigStorage(ioProc, 'grand_cfg.m');
            o.default();
        end

        function default(o) 
            o.UseAllSubjects = 1;
            o.PerSubjectAgerage = 1;
            o.Log10Enable = 0;
            o.EvokedOscillations = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 4
                    o.UseAllSubjects = cells{1};
                    o.PerSubjectAgerage = cells{2};
                    o.Log10Enable = cells{3};
                    o.EvokedOscillations = cells{4};
                else 
                    o.default()
                    WTLog().warn(['The grand average parameters (%s) were set by a\n'...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.IntCellsFieldArgs(o.FldDefaultAnswer, o.UseAllSubjects, o.PerSubjectAgerage, o.Log10Enable, o.EvokedOscillations);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end