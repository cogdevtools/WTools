classdef WTBaselineChopCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        ChopMin(1,1) single
        ChopMax(1,1) single
        BaselineMin(1,1) single
        BaselineMax(1,1) single
        Log10Enable(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        NoBaselineCorrection(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        EvokedOscillations(1,1) uint8  {WTValidations.mustBeZeroOrOne} = 0
    end
    methods
        function o = WTBaselineChopCfg(ioProc)
            o@WTConfigStorage(ioProc, 'baseline_chop_cfg.m');
            o.default();
        end

        function default(o) 
            o.ChopMin = 0;
            o.ChopMax = 0;
            o.BaselineMin = 0;
            o.BaselineMax = 0;
            o.Log10Enable = 0;
            o.NoBaselineCorrection = 0;
            o.EvokedOscillations = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 7 
                    o.ChopMin = str2double(cells{1});
                    o.ChopMax = str2double(cells{2});
                    o.BaselineMin = str2double(cells{3});
                    o.BaselineMax = str2double(cells{4});
                    o.Log10Enable = cells{5};
                    o.NoBaselineCorrection = cells{6};
                    o.EvokedOscillations = cells{7};
                    return
                else
                    o.default();
                    WTLog().warn(['The baseline chop parameters (%s) were set by a\n'...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().mexcpt(me);
                success = false;
            end
        end

        function success = validate(o)
            success = false;

            if o.ChopMin > o.ChopMax 
                return
            end
            if ~o.NoBaselineCorrection && o.BaselineMin > o.BaselineMax
                return
            end
            success = true;
        end

        function success = persist(o)
            txt = WTFormatter.GenericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTFormatter.FmtIntStr, o.ChopMin, ...
                WTFormatter.FmtIntStr, o.ChopMax, ...
                WTFormatter.FmtIntStr, o.BaselineMin, ...
                WTFormatter.FmtIntStr, o.BaselineMax, ...
                WTFormatter.FmtInt, o.Log10Enable, ...
                WTFormatter.FmtInt, o.NoBaselineCorrection, ...
                WTFormatter.FmtInt, o.EvokedOscillations);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end