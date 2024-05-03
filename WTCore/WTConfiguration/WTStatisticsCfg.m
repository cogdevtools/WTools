classdef WTStatisticsCfg < WTConfigStorage & matlab.mixin.Copyable & WTTimeFreqCfg

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        ChannelsList(1,:) uint32
        IndividualFreqs(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        EvokedOscillations(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
    end

    methods
        function o = WTStatisticsCfg(ioMngr)
            o@WTConfigStorage(ioMngr, 'avrretrieve_cfg.m');
            o@WTTimeFreqCfg();
            o.default();
        end

        function default(o) 
            default@WTTimeFreqCfg(o)
            o.ChannelsList = [];
            o.IndividualFreqs = 0;
            o.EvokedOscillations = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) == 7
                    o.ChannelsList = WTUtils.str2nums(cells{1});
                    o.TimeMin = WTUtils.str2double(cells{2});
                    o.TimeMax = WTUtils.str2double(cells{3});
                    o.FreqMin = WTUtils.str2double(cells{4});
                    o.FreqMax = WTUtils.str2double(cells{5});
                    o.IndividualFreqs = cells{6};
                    o.EvokedOscillations = cells{7};
                    o.validate();
                else 
                    o.default();
                    WTLog().warn(['The statistics parameters (%s) were set by a previous\n'...
                        'incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTConfigFormatter.FmtArrayStr, num2str(o.ChannelsList), ...
                WTConfigFormatter.FmtIntStr, o.TimeMin, ...
                WTConfigFormatter.FmtIntStr, o.TimeMax, ...
                WTConfigFormatter.FmtIntStr, o.FreqMin, ...
                WTConfigFormatter.FmtIntStr, o.FreqMax, ...    
                WTConfigFormatter.FmtInt, o.IndividualFreqs, ...
                WTConfigFormatter.FmtInt, o.EvokedOscillations);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
