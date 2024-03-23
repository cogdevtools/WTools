classdef WTHandle < handle
    properties(Hidden,Access=public)
        Value
    end

    methods
        function o = WTHandle(value)
            o.Value = value;
        end
    end
end