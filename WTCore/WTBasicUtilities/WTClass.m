% Copyright (C) 2024 Eugenio Parise, Luca Filippin
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.

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

        function is = isSingleton(o)
            is = o.InstanceType == WTClass.Singleton || ...
                 o.InstanceType == WTClass.LockedSingleton;
        end

        function is = isLockedSingleton(o)
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
            WTSingletons.unregister(o, o.isLockedSingleton);
            o.InstanceType = WTClass.NonSingleton;
        end
    end
end