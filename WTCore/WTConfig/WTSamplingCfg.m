classdef WTSamplingCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        SamplingRate single {mustBeFinite, WTValidations.mustBeGT(SamplingRate, 0)}
    end

    methods
        function o = WTSamplingCfg(ioProc)
            o@WTConfigStorage(ioProc, 'samplrate.m');
            o.default();
        end

        function default(o) 
            o.SamplingRate = 1;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success
                return
            end
            try
                o.SamplingRate = WTUtils.str2double(cells{1});
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.GenericCellsFieldArgs(o.FldDefaultAnswer, WTFormatter.FmtStr, num2str(o.SamplingRate));
            success = ~isempty(txt) && o.write(txt);
        end
    end
end