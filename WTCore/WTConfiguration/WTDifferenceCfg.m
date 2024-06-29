classdef WTDifferenceCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        Condition1(1,1) uint8 {mustBeFinite}
        Condition2(1,1) uint8 {mustBeFinite}
        ConditionsDiff(1,1) uint8 {mustBeFinite}
        LogarithmicTransform(1,1) uint8 {WTValidations.mustBeZeroOrOne}
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
            o.ConditionsDiff = 1;
            o.LogarithmicTransform = 0;
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
                    o.ConditionsDiff = cells{3};
                    o.LogarithmicTransform = cells{4};
                    o.EvokedOscillations = cells{5};
                else 
                    o.default();
                    WTLog().warn(['The difference parameters (%s) were set by an \n'...
                        'incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.intCellsFieldArgs(o.FldDefaultAnswer, o.Condition1, o.Condition2, o.ConditionsDiff, o.LogarithmicTransform, o.EvokedOscillations);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
