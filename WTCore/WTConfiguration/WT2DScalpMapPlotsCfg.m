classdef WT2DScalpMapPlotsCfg < WTConfigStorage & matlab.mixin.Copyable & WTPacedTimeFreqCfg

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        Scale(1,:) single {WTValidations.mustBeALimitedLinearArray(Scale, 1, 2, 1)}
        Contours(1,1) uint8 {WTValidations.mustBeZeroOrOne}
        PeripheralElectrodes(1,1) uint8 {WTValidations.mustBeZeroOrOne}
        ElectrodesLabel(1,1) uint8 {WTValidations.mustBeZeroOrOne}
    end

    methods
        function o = WT2DScalpMapPlotsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'smavr_cfg.m');
            o@WTPacedTimeFreqCfg();
            o.AllowTimeResolution = true;
            o.AllowFreqResolution = true;
            o.default()
        end

        function default(o) 
            default@WTPacedTimeFreqCfg(o)
            o.Scale = [];
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 6
                    o.Time = cells{1};
                    o.Frequency = cells{2};
                    o.Scale = WTNumUtils.str2nums(cells{3});
                    o.PeripheralElectrodes = cells{4};
                    o.Contours = cells{5};
                    o.ElectrodesLabel = cells{6};
                    o.validate();
                else
                    o.default()
                    WTLog().warn(['The parameters for scalp map 2D plots (%s) were set by a\n' ...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
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
                WTConfigFormatter.FmtArrayStr, num2str(o.Scale), ...
                WTConfigFormatter.FmtInt, o.PeripheralElectrodes, ...
                WTConfigFormatter.FmtInt, o.Contours, ...
                WTConfigFormatter.FmtInt, o.ElectrodesLabel);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end