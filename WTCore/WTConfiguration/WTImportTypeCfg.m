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

classdef WTImportTypeCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        EEPFlag(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        EGIFlag(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        BRVFlag(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        EEGLabFlag(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
    end

    methods
        function o = WTImportTypeCfg(ioProc)
            o@WTConfigStorage(ioProc, 'import2eegl_cfg.m');
            o.default();
        end

        function default(o) 
            o.EEPFlag = 0;
            o.EGIFlag = 1;
            o.BRVFlag = 0;
            o.EEGLabFlag = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 4
                    o.EEPFlag = cells{1};
                    o.EGIFlag = cells{2};
                    o.BRVFlag = cells{3};
                    o.EEGLabFlag = cells{4};
                else 
                    o.default();
                    WTLog().warn(['The import type format parameters (%s) were set by an \n'...
                        'incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.intCellsFieldArgs(o.FldDefaultAnswer, o.EEPFlag, o.EGIFlag, o.BRVFlag, o.EEGLabFlag);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end
