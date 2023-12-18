classdef WTProject < handle

    properties (SetAccess=private, GetAccess=public)
        IsOpen logical
        Config Config
    end

    methods
        function o = WTProject()
            st = singleton();
            if isempty(st) || ~isvalid(st)
                o.IsOpen = false;
                o.Config = WTConfig();
                singleton(o)
            else 
                o = st;
            end
        end

        function open = checkIsOpen(o)
            open = o.IsOpen;
            if ~open
                WTUtils.eeglabMsgGui('Warning', 'Please open a project or create a new one first')
            end
        end

        function success = open(o, rootDir)
            success = o.Config.open(rootDir); 
            o.IsOpen = success;
            name = WTUtils.getPathTrail(rootDir);  
            parentDir = WTUtils.getPathPrefix(rootDir);
            if success 
                WTLog().info('Project ''%s''in dir ''%s'' opened successfully', name, parentDir);
            else
                WTLog().err('Failed to open project ''%s'' in dir ''%s''', name, parentDir);
            end
        end 

        function success = new(o, rootDir)
            success = o.Config.new(rootDir); 
            o.IsOpen = success;  
            name = WTUtils.getPathTrail(rootDir);  
            parentDir = WTUtils.getPathPrefix(rootDir);
            if success 
                WTLog().info('New project ''%s'' created successfully in dir ''%s''', name, parentDir); 
            else
                WTLog().err('Failed to create project ''%s'' in dir ''%s''', name, parentDir);
            end
        end 
    end

    methods(Static)
        function success = checkIsValidName(name, warn)
            success = length(split(name)) == 1 && length(split(name,'\')) == 1 && length(split(name,'/')) == 1;
            if ~success && nargin > 1 && warn
                WTUtils.eeglabMsgGui('Error', ['Invalid project name!\n'...
                    'Remove blanks and / \\ chars from the name.']);
            end
        end
    
        function clear()
            singleton();
            munlock('singleton');
        end
    end
end

function o = singleton(obj)
    mlock;
    persistent uniqueInstance

    if nargin > 0 
        uniqueInstance = obj;
    elseif nargout > 0 
        o = uniqueInstance;
    elseif ~isempty(uniqueInstance)
        delete(uniqueInstance)
    end
end

