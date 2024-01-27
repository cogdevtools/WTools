classdef WTConvertToEEGLabCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        EEPFlag(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        EGIFlag(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        BRVFlag(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        EEGLabFlag(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
    end

    methods
        function o = WTConvertToEEGLabCfg(ioProc)
            o@WTConfigStorage(ioProc, 'import2eegl_cfg.m');
            o.default();
        end

        function default(o) 
            o.EEPFlag = 0;
            o.EGIFlag = 1;
            o.BRVFlag = 0;
            o.EEGLabFlag = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 4
                    o.EEPFlag = cells{1};
                    o.EGIFlag = cells{2};
                    o.BRVFlag = cells{3};
                    o.EEGLabFlag = cells{4};
                else 
                    o.default()
                    WTLog().warn(['The import to EEGLab format parameters (%s) were set by a\n'...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.IntCellsFieldArgs(o.FldDefaultAnswer, o.EEPFlag, o.EGIFlag, o.BRVFlag, o.EEGLabFlag);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
