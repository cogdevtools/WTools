classdef WTDifferenceCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        Condition1(1,1) uint8 {mustBeFinite}
        Condition2(1,1) uint8 {mustBeFinite}
        ConditionDiff(1,1) uint8 {mustBeFinite}
        LogDiff(1,1) uint8 {WTValidations.mustBeZeroOrOne}
        EvokedOscillations(1,1) uint8 {WTValidations.mustBeZeroOrOne}
    end

    methods
        function o = WTDifferenceCfg(ioProc)
            o@WTConfigStorage(ioProc, 'difference_cfg.m');
            o.default();
        end

        function default(o) 
            o.Condition1 = 1;
            o.Condition2 = 1;
            o.ConditionDiff = 1;
            o.LogDiff = 0;
            o.EvokedOscillations = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 5
                    o.Condition1 = cells{1};
                    o.Condition2 = cells{2};
                    o.ConditionDiff = cells{3};
                    o.LogDiff = cells{4};
                    o.EvokedOscillations = cells{5};
                else 
                    o.default()
                    WTLog().warn(['The difference parameters (%s) were set by a\n'...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.IntCellsFieldArgs(o.FldDefaultAnswer, o.Condition1, o.Condition2, o.ConditionDiff, o.LogDiff, o.EvokedOscillations);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
