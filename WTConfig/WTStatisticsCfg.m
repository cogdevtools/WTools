classdef WTStatisticsCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        ChannelsList cell
        TimeMin(1,1) uint32 
        TimeMax(1,1) uint32
        FreqMin(1,1) uint32
        FreqMax(1,1) uint32
        RetrieveIndividualFreqs(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        RetrieveEvokedOscillations(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
    end

    methods
        function o = WTStatisticsCfg(ioMngr)
            o@WTConfigStorage(ioMngr, 'avrretrieve_cfg.m');
            o.default();
        end

        function default(o) 
            o.ChannelsList = [];
            o.TimeMin = 0;
            o.TimeMax = 0;
            o.FreqMin = 0;
            o.FreqMax = 0;
            o.RetrieveIndividualFreqs = 0;
            o.RetrieveEvokedOscillations = 0;
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
                    o.RetrieveIndividualFreqs = cells{6};
                    o.RetrieveEvokedOscillations = cells{7};
                else 
                    o.default()
                    WTLog().warn(['The statistics parameters (%s) were set by a previous\n'...
                        'incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.GenericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTFormatter.FmtArrayStr, num2str(o.ChannelsList), ...
                WTFormatter.FmtIntStr, o.TimeMin, ...
                WTFormatter.FmtIntStr, o.TimeMax, ...
                WTFormatter.FmtIntStr, o.FreqMin, ...
                WTFormatter.FmtIntStr, o.FreqMax, ...    
                WTFormatter.FmtInt, o.RetrieveIndividualFreqs, ...
                WTFormatter.FmtInt, o.RetrieveEvokedOscillations);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
