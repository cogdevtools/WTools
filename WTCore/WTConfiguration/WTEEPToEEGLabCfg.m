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

classdef WTEEPToEEGLabCfg < WTConfigStorage & WTEpochsAndFreqFiltersCfg & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    methods
        function o = WTEEPToEEGLabCfg(ioProc)
            o@WTConfigStorage(ioProc, 'eep2eegl_cfg.m');
            o@WTEpochsAndFreqFiltersCfg();
            o.default();
        end

        function default(o)  
            default@WTEpochsAndFreqFiltersCfg(o);
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 3 
                    o.EpochLimits = WTNumUtils.str2nums(cells{1});
                    o.HighPassFilter = WTNumUtils.str2double(cells{2}, true);
                    o.LowPassFilter = WTNumUtils.str2double(cells{3}, true);
                    o.validate(true)
                else
                    o.default();
                    WTLog().err('EEP to EEGLab conversion (%s): wrong number of parameters! They''ll be reset', o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                o.default();
                success = false;
            end 
        end

        function success = validate(o, throwExcpt) 
            success = validate@WTEpochsAndFreqFiltersCfg(o, throwExcpt);
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTConfigFormatter.FmtArrayStr, num2str(o.EpochLimits), ...
                WTConfigFormatter.FmtFloatStr, o.HighPassFilter, ...
                WTConfigFormatter.FmtFloatStr, o.LowPassFilter);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
