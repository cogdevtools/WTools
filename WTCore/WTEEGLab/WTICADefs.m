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

classdef WTICADefs < WTClass
    
    properties(Constant)
        ClassUUID = '617286e1-02cd-4a83-a702-5474abe17736'
    end

    properties(Access = private)
        Overriders
    end

    methods(Access = private)
        function idx = push(o, overrider, permanent)
            if permanent 
                o.Overriders.Permanent(end+1) = {overrider};
                idx = -1;
            else
                o.Overriders.Temporary(end+1)= {overrider};
                idx = length(o.Overriders.Temporary);
            end
        end
    end

    methods
        function o = WTICADefs()
            singleton = true;
            locked = true;

            o = o@WTClass(singleton, locked);
            if ~o.InstanceInitialised
                o.Overriders = struct();
                o.Overriders.Permanent = {};
                o.Overriders.Temporary = {};
            end
        end

        % pushModifier push a modifier function to the stack
        % @param hFunction function handle
        % @return index of the pushed modifier
        % hFunction must return a char array representing the matlab code which 
        % is expected to overrides icadefs settings.
        function idx = pushModifier(o, hFunction, permanent)
            permanent = nargin > 2 && permanent;

            if ~isa(hFunction, 'function_handle')
                WTExcetion.badArg('parameter must be a function handle').throw();
            end
            if nargin(hFunction) ~= 0
                WTExcetion.badArg('function must have no input argument').throw();
            end
            if nargout(hFunction) ~= 1
                WTExcetion.badArg('function must have one output argument').throw();
            end
            overridingCode = hFunction();
            if ~ischar(overriderCode)
                WTExcetion.badValue('function must return a char array').throw();
            end
            idx = o.push({overridingCode}, permanent);            
        end

        function idx = pushVariable(o, variable, value, permanent)
            permanent = nargin > 3 && permanent;
            if ~ischar(variable)
                WTExcetion.badArg('variable must be a string').throw();
            end
            idx = o.push({variable, value}, permanent);    
        end

        function pop(o, idx)
            if idx < 1 || idx > length(o.Overriders.Temporary)
                WTExcetion.badArg('index out of range').throw();
            end
            o.Overriders.Temporary(idx:end) = [];
        end

        function reset(o)
            o.Overriders.Temporary = {};
        end

        function overriders = get(o) 
            overriders = [o.Overriders.Permanent o.Overriders.Temporary];
        end
    end
end