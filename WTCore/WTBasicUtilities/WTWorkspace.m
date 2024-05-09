classdef WTWorkspace < handle

    properties (Access=private)
        WSStack
    end

    methods (Access=private)

        function push(o, s)
            o.WSStack = [o.WSStack;{s}];
        end
        
        function e = pop(o)
            if size(o.WSStack, 2) == 0
                WTException.workspaceErr('Empty stack').throw();
            end
            c = o.WSStack(end); 
            o.WSStack(end) = [];
            e = c{1};
        end

        function s = popStruct(o) 
            e = o.pop();
            s = cell2struct(e(2,:),e(1,:),2);
        end

        function d = popMap(o) 
            e = o.pop();
            d = containers.Map(e(1,:),e(2,:),'UniformValues',false);
        end
    end

    methods 
        function o = WTWorkspace()
            o.WSStack = {};
        end

        function pushBase(o, clear) 
            ws = evalin('base', '[who, who].''');
            for i=1:size(ws,2)
                ws{2,i} = evalin('base', ws{1,i});
            end
            o.push(ws);
            if nargin == 2 && clear 
                evalin('base', 'clearvars')
            end
        end

        function pushCaller(o, clear) 
            ws = evalin('caller', '[who, who].''');
            for i=1:size(ws,2)
                ws{2,i} = evalin('caller', ws{1,i});
            end
            o.push(ws);
            if nargin == 2 && clear 
                evalin('caller', 'clearvars');
            end
        end

        function popToBase(o, clear) 
            if nargin == 2 && clear 
                evalin('base', 'clearvars')
            end
            ws = o.pop();
            for i=1:size(ws,2)
                assignin('base', ws{1,i},  ws{2,i});
            end
        end

        function wsStruct = popToStruct(o) 
            wsStruct = o.popStruct();
        end

        function wsMap = popToMap(o) 
            wsMap = o.popMap();
        end

        function varargout = popToVars(o, varargin) 
            if nargin ~= nargout+1 
                WTException.ioArgsMismatch('Input/output args number mismatch').throw();
            end
            if nargin == 1 
                return
            end
            ws = o.popMap();
            varargout = cell(nargout,1);
            for i = 1:nargout
                try
                    varargout{i} = ws(varargin{i});
                catch
                    WTException.workspaceErr('Key not found: %s', varargin{i}).throw();
                end
            end
        end
    end
end