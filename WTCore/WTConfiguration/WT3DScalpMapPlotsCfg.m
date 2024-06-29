classdef WT3DScalpMapPlotsCfg < WTConfigStorage & matlab.mixin.Copyable & WTPacedTimeFreqCfg

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        Scale(1,:) single {WTValidations.mustBeALimitedLinearArray(Scale, 1, 2, 1)}
    end

    methods
        function o = WT3DScalpMapPlotsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'smavr3d_cfg.m');
            o@WTPacedTimeFreqCfg();
            o.AllowTimeResolution = false;
            o.AllowFreqResolution = false;
            o.default();
        end

        function default(o) 
            default@WTPacedTimeFreqCfg(o);
            o.Scale = [];
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 3
                    o.Time = cells{1};
                    o.Frequency = cells{2};
                    o.Scale = WTNumUtils.str2nums(cells{3});
                    o.validate();
                else
                    o.default();
                    WTLog().warn(['The parameters for 3D scalp map plots (%s) were set by an \n' ...
                        'incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = validate(o, throwExcpt)
            throwExcpt = nargin > 1 && throwExcpt; 
            success = validate@WTPacedTimeFreqCfg(o, throwExcpt);
            if ~success 
                return
            end
            if o.Scale(1) >= o.Scale(2) 
                WTCodingUtils.throwOrLog(WTException.badValue('Field Scale(2) <= Scale(1)'), ~throwExcpt);
                return
            end
            success = true;
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTConfigFormatter.FmtArrayStr, num2str(o.Time), ...
                WTConfigFormatter.FmtArrayStr, num2str(o.Frequency), ...
                WTConfigFormatter.FmtArrayStr, num2str(o.Scale));
            success = ~isempty(txt) && o.write(txt);
        end
    end
end