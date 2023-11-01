classdef WTWorkSpace < handle

    properties (Access=private)
        wsStack
    end

    methods (Access=private)
        function obj = WTWorkSpace()
            obj.wsStack = {};
        end

        function push(obj, s)
            obj.wsStack = [obj.wsStack;{s}];
        end
        
        function e = pop(obj)
            if size(obj.wsStack, 2) == 0
                WTLog.excpt('WTWorkSpace', 'Empty stack')
            end
            c = obj.wsStack(end); 
            obj.wsStack(end) = [];
            e = c{1};
        end

        function s = popStruct(obj) 
            e = obj.pop();
            s = cell2struct(e(2,:),e(1,:),2);
        end

        function d = popMap(obj) 
            e = obj.pop();
            d = containers.Map(e(1,:),e(2,:),'UniformValues',false);
        end
    end

    methods (Static)
        function pushBase(clear) 
            obj = instance();
            ws = evalin('base', '[who, who].''');
            for i=1:size(ws,2)
                ws{2,i} = evalin('base', ws{1,i});
            end
            obj.push(ws);
            if nargin == 1 && clear 
                evalin('base', 'clearvars')
            end
        end

        function pushCaller(clear) 
            obj = instance();
            ws = evalin('caller', '[who, who].''');
            for i=1:size(ws,2)
                ws{2,i} = evalin('caller', ws{1,i});
            end
            obj.push(ws);
            if nargin == 1 && clear 
                evalin('caller', 'clearvars');
            end
        end

        function popToBase(clear) 
            obj = instance();
            if nargin == 1 && clear 
                evalin('base', 'clearvars')
            end
            ws = obj.pop();
            for i=1:size(ws,2)
                assignin('base', ws{1,i},  ws{2,i});
            end
        end

        function wsStruct = popToStruct() 
            obj = instance();
            wsStruct = obj.popStruct();
        end

        function wsMap = popToMap() 
            obj = instance();
            wsMap = obj.popMap();
        end

        function varargout = popToVars(varargin) 
            if nargin ~= nargout 
                WTLog.excpt('WTWorkSpace', 'Input/output args number mismatch')
            end
            if nargin == 0 
                return
            end
            obj = instance();
            ws = obj.popMap();
            varargout = cell(nargout,1);
            for i=1:nargout
                try
                    varargout{i} = ws(varargin{i});
                catch
                    WTLog.excpt('WTWorkSpace', 'Key not found: %s', varargin{i});
                end
            end
        end

        function close()
            instance()
            munlock('instance');
        end  
    end
end

function obj = instance()
    mlock;
    persistent uniqueInstance
    if nargout == 0 
        uniqueInstance = {};
        return
    end
    if isempty(uniqueInstance)
        obj = WTWorkSpace();
        uniqueInstance = obj;
    else
        obj = uniqueInstance;
    end
end