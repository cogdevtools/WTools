classdef WTClass < handle

    properties(Abstract, Constant)
        ClassUUID char % must be a version 4 UUID
    end

    properties(Constant, Access = private)
        NonSingleton = 0
        Singleton = 1
        LockedSingleton = 2
    end

    properties(GetAccess = protected, SetAccess = private)
        InstanceInitialised logical
    end

    properties(SetAccess = private)
        InstanceType 
    end

    methods
        function o = WTClass(singleton, locked)
            locked = nargin > 1 && locked;
            o.InstanceType = WTClass.NonSingleton;
            o.InstanceInitialised = false;
            if singleton
                o = o.registerSingleton(locked); 
            end
        end

        function is = IsSingleton(o)
            is = o.InstanceType == WTClass.Singleton || ...
                 o.InstanceType == WTClass.LockedSingleton;
        end

        function is = IsLockedSingleton(o)
            is = o.InstanceType == WTClass.LockedSingleton;
        end

        function o = registerSingleton(o, locked)
            locked = nargin < 1 || locked;
            st = WTSingletons.register(o, locked);
            st.InstanceType = WTClass.Singleton;
            if locked
                st.InstanceType = WTClass.LockedSingleton;
            end
            st.InstanceInitialised = ~eq(st, o);
            o = st;
        end

        function o = unregisterSingleton(o)
            WTSingletons.unregister(o, o.IsLockedSingleton);
            o.InstanceType = WTClass.NonSingleton;
        end
    end
end