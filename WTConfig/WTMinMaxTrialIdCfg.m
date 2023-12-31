classdef WTMinMaxTrialIdCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        MinTrialId uint32 
        MaxTrialId uint32
    end

    methods
        function o = WTMinMaxTrialIdCfg(ioProc)
            o@WTConfigStorage(ioProc, 'minmaxtrialid.m');
            o.default();
        end

        function default(o) 
            o.MinTrialId = 0;
            o.MaxTrialId = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success
                return
            end
            try
                if length(cells) >= 2
                    o.MinTrialId = str2double(cells{1});
                    o.MaxTrialId = str2double(cells{2});
                else 
                    o.default()
                    WTLog().warn(['The min/max trial id parameters (%s) were set by a\n'...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTFormatter.GenericCellsFieldArgs(o.FldDefaultAnswer, ....
                WTFormatter.FmtIntStr, o.MinTrialId, ...
                WTFormatter.FmtIntStr, o.MaxTrialId);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end