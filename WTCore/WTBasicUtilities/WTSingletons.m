classdef (Sealed) WTSingletons 

    methods(Static, Access = private)
        function id = classId(o)
            id = sprintf('%s[%s]', class(o), o.ClassUUID);
        end 

        function [singletonsMap, o] = singleton(singletonsMap, o)
            if nargin > 1
                id = WTSingletons.classId(o);
                if nargout > 1
                    if isempty(singletonsMap)
                        singletonsMap = containers.Map(id, o);
                    elseif isKey(singletonsMap, id)
                        o = singletonsMap(id);
                    else
                        singletonsMap(id) = o;
                    end
                elseif ~isempty(singletonsMap)
                    remove(singletonsMap, id);
                end
            elseif ~isempty(singletonsMap)
                values = singletonsMap.values();
                for i = 1:length(values)
                    values{i}.unregisterSingleton(); % set the correct state of each object
                end
                singletonsMap = [];
            end
        end

        function o = persistedUnlocked(varargin)
            persistent singletonsMap
            if nargout > 0
                [singletonsMap, o] = WTSingletons.singleton(singletonsMap, varargin{:});
            else 
                singletonsMap = WTSingletons.singleton(singletonsMap, varargin{:});
            end
        end

        function o = persistedLocked(varargin)
            persistent singletonsMap
            mlock();
            if nargout > 0
                [singletonsMap, o] = WTSingletons.singleton(singletonsMap, varargin{:});
            else 
                singletonsMap = WTSingletons.singleton(singletonsMap, varargin{:});
            end
            if isempty(singletonsMap)
                munlock();
            end
        end
    end
    
    methods(Static, Access = ?WTClass)
        function o = register(o, locked)
            WTValidations.mustBeA(o, ?WTClass);
            locked = nargin < 1 || locked;
            if locked
                WTSingletons.persistedUnlocked(o);
                o = WTSingletons.persistedLocked(o);
            else 
                WTSingletons.persistedLocked(o)
                o = WTSingletons.persistedUnlocked(o);
            end
            if ~isvalid(o)
                WTException.badValue('%s singleton has been deleted', class(o)).throw()
            end
        end

        function o = unregister(o, locked)
            WTValidations.mustBeA(o, ?WTClass);
            if locked
                WTSingletons.persistedLocked(o);
            else
                WTSingletons.persistedUnlocked(o);
            end
        end  
    end

    methods(Static)
        function clear(unlocked, locked)
            unlocked = nargin < 1 || unlocked;
            locked = nargin < 2 || locked;
            if unlocked
                WTSingletons.persistedUnlocked();
            end
            if locked 
                WTSingletons.persistedLocked();
            end
        end
    end
end