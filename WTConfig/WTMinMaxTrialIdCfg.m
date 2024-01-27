classdef WTMinMaxTrialIdCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        MinTrialId uint32 {WTValidations.mustBeGTE(MinTrialId, 0, 1)} = NaN
        MaxTrialId uint32 {WTValidations.mustBeGTE(MaxTrialId, 0, 1)} = NaN
    end

    methods
        function o = WTMinMaxTrialIdCfg(ioProc)
            o@WTConfigStorage(ioProc, 'minmaxtrialid.m');
            o.default();
        end

        function default(o) 
            o.MinTrialId = NaN;
            o.MaxTrialId = NaN;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success
                return
            end
            try
                if length(cells) >= 2
                    % For backward compatibility
                    o.MinTrialId = WTUtils.ifThenElseSet(ischar(cells{1}) && isempty(cells{1}), NaN, str2double(cells{1}));
                    o.MaxTrialId = WTUtils.ifThenElseSet(ischar(cells{2}) && isempty(cells{2}), NaN, str2double(cells{2}));
                    o.validate();
                else 
                    o.default();
                    WTLog().warn(['The min/max trial id parameters (%s) were set by a\n'...
                        'previous incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = validate(o, throwExcpt) 
            success = true;
            if ~isnan(o.MinTrialId) && ~isnan(o.MaxTrialId)
                success = o.MaxTrialId >= o.MinTrialId;
            end
            if nargin > 1 && any(logical(throwExcpt)) 
                WTLog().excpt('BadValue', 'Field MaxTrialId < MinTrialId');
            end
        end

        function isAllTrials= allTrials(o)
            isAllTrials = isnan(o.MinMaxTrialId) && isnan(o.MaxTrialId)
        end

        function newObj = interpret(o)
            newObj = copy(o);
            if isnan(o.MinMaxTrialId) && isnan(o.MaxTrialId) % all trials case
                return
            elseif isnan(o.MaxTrialId)
                newObj.MaxTrialId = 1000000; % set an arbitrary large enough number
            elseif isnan(o.MinTrialId)
                newObj.MinTrialId = 0; % set a value < of the min possible trial = 1
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