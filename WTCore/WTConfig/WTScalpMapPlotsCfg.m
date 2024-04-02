classdef WTScalpMapPlotsCfg < WTConfigStorage & matlab.mixin.Copyable & WTCommonScalpMapPlotsCfg

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        Contours(1,1) uint8 {WTValidations.mustBeZeroOrOne}
        PeripheralElectrodes(1,1) uint8 {WTValidations.mustBeZeroOrOne}
        ElectrodesLabel(1,1) uint8 {WTValidations.mustBeZeroOrOne}
    end

    methods
        function o = WTScalpMapPlotsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'smavr_cfg.m');
            o@WTCommonScalpMapPlotsCfg();
            o.default()
        end

        function default(o) 
            default@WTCommonScalpMapPlotsCfg(o)
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 6
                    o.Time = WTUtils.str2nums(cells{1});
                    o.Frequency = WTUtils.str2nums(cells{2});
                    o.Scale = WTUtils.str2nums(cells{3});
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

        function success = persist(o)
            txt = WTFormatter.GenericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTFormatter.FmtArrayStr, num2str(o.Time), ...
                WTFormatter.FmtArrayStr, num2str(o.Frequency), ...
                WTFormatter.FmtArrayStr, num2str(o.Scale), ...
                WTFormatter.FmtInt, o.PeripheralElectrodes, ...
                WTFormatter.FmtInt, o.Contours, ...
                WTFormatter.FmtInt, o.ElectrodesLabel);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end