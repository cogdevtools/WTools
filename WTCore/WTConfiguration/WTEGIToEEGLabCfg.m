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

classdef WTEGIToEEGLabCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        TriggerLatency(1,1) single
    end

    properties (Access = private)
        GuardedSet logical
    end

    methods
        function o = WTEGIToEEGLabCfg(ioProc)
            o@WTConfigStorage(ioProc, 'trigger.m');
            o.default();
        end

        function default(o) 
            o.GuardedSet = false;
            o.TriggerLatency = 0;
            o.GuardedSet = true;
        end

        function set.TriggerLatency(o, latency)
            if o.GuardedSet
                WTValidations.mustBeGT(latency, 0, false, false);
            end
            o.TriggerLatency = latency;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 1 
                    o.TriggerLatency = WTNumUtils.str2double(cells{1});
                else
                    o.default();
                    WTLog().err('EGI to EEGLab conversion (%s): wrong number of parameters! They''ll be reset', o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                o.default();
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, WTConfigFormatter.FmtFloatStr, o.TriggerLatency);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
