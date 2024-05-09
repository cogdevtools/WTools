classdef WTChansAvgPlotsCfg < WTConfigStorage & matlab.mixin.Copyable & WTTimeFreqCfg

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        Scale(1,2) single  
        Contours(1,1) uint8 {WTValidations.mustBeZeroOrOne}
        AllChannels(1,1) uint8 {WTValidations.mustBeZeroOrOne}
    end

    methods
        function o = WTChansAvgPlotsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'xavr_cfg.m');
            o@WTTimeFreqCfg();
            o.default()
        end

        function default(o) 
            default@WTTimeFreqCfg(o)
            o.Scale = [-10.0 10.0];
            o.Contours = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 6
                    o.TimeMin = WTNumUtils.str2double(cells{1});
                    o.TimeMax = WTNumUtils.str2double(cells{2});
                    o.FreqMin = WTNumUtils.str2double(cells{3});
                    o.FreqMax = WTNumUtils.str2double(cells{4});
                    o.Scale = WTNumUtils.str2nums(cells{5});
                    o.Contours = cells{6};
                    o.validate();
                else
                    o.default()
                    WTLog().warn(['The parameters for channels average plots (%s) were set by a\n' ...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = validate(o, throwExcpt)
            throwExcpt = nargin > 1 && throwExcpt; 
            success = true;

            if ~validate@WTTimeFreqCfg(o, throwExcpt)
                success = false;
            end
            
            if o.Scale(1) >= o.Scale(2) 
                WTCodingUtils.throwOrLog(WTException.badValue('Field Scale(2) <= Scale(1)'), ~throwExcpt);
                success = false;
            end
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTConfigFormatter.FmtIntStr, o.TimeMin, ...
                WTConfigFormatter.FmtIntStr, o.TimeMax, ...
                WTConfigFormatter.FmtIntStr, o.FreqMin, ...
                WTConfigFormatter.FmtIntStr, o.FreqMax, ...
                WTConfigFormatter.FmtArrayStr, num2str(o.Scale), ...
                WTConfigFormatter.FmtInt, o.Contours);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end