classdef WTAvgPlotsCfg < WTConfigStorage & matlab.mixin.Copyable & WTCommonPlotsCfg

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        Scale(1,2) single  
        Contours(1,1) uint8 {WTValidations.mustBeZeroOrOne}
        AllChannels(1,1) uint8 {WTValidations.mustBeZeroOrOne}
    end

    methods
        function o = WTAvgPlotsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'xavr_cfg.m');
            o@WTCommonPlotsCfg();
            o.default()
        end

        function default(o) 
            default@WTCommonPlotsCfg(o)
            o.Scale = [-10.0 10.0];
            o.Contours = 0;
            o.AllChannels = 1;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 7
                    o.TimeMin = WTUtils.str2double(cells{1});
                    o.TimeMax = WTUtils.str2double(cells{2});
                    o.FreqMin = WTUtils.str2double(cells{3});
                    o.FreqMax = WTUtils.str2double(cells{4});
                    o.Scale = WTUtils.str2nums(cells{5});
                    o.Contours = cells{6};
                    o.AllChannels = cells{7};
                    o.validate();
                else
                    o.default()
                    WTLog().warn(['The  parameters for average plots (%s) were set by a\n' ...
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

            if ~validate@WTCommonPlotsCfg(o, throwExcpt)
                success = false;
            end
            
            if o.Scale(1) >= o.Scale(2) 
                WTUtils.throwOrLog(WTException.badValue('Field Scale(2) <= Scale(1)'), ~throwExcpt);
                success = false;
            end
        end

        function success = persist(o)
            txt = WTFormatter.GenericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTFormatter.FmtIntStr, o.TimeMin, ...
                WTFormatter.FmtIntStr, o.TimeMax, ...
                WTFormatter.FmtIntStr, o.FreqMin, ...
                WTFormatter.FmtIntStr, o.FreqMax, ...
                WTFormatter.FmtArrayStr, num2str(o.Scale), ...
                WTFormatter.FmtInt, o.Contours, ...
                WTFormatter.FmtInt, o.AllChannels);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end