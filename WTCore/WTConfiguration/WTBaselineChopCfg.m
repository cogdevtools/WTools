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

classdef WTBaselineChopCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        ChopTimeMin(1,1) single
        ChopTimeMax(1,1) single
        BaselineTimeMin(1,1) single
        BaselineTimeMax(1,1) single
        LogarithmicTransform(1,1) int8 {WTValidations.mustBeZeroOrOne} = 0
        NoBaselineCorrection(1,1) int8 {WTValidations.mustBeZeroOrOne} = 0
        EvokedOscillations(1,1) int8  {WTValidations.mustBeZeroOrOne} = 0
    end

    methods
        function o = WTBaselineChopCfg(ioProc)
            o@WTConfigStorage(ioProc, 'baseline_chop_cfg.m');
            o.default();
        end

        function default(o) 
            o.ChopTimeMin = 0;
            o.ChopTimeMax = 0;
            o.BaselineTimeMin = 0;
            o.BaselineTimeMax = 0;
            o.LogarithmicTransform = 0;
            o.NoBaselineCorrection = 0;
            o.EvokedOscillations = 0;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 7 
                    o.ChopTimeMin = WTNumUtils.str2double(cells{1});
                    o.ChopTimeMax = WTNumUtils.str2double(cells{2});
                    o.BaselineTimeMin = WTNumUtils.str2double(cells{3});
                    o.BaselineTimeMax = WTNumUtils.str2double(cells{4});
                    o.LogarithmicTransform = cells{5};
                    o.NoBaselineCorrection = cells{6};
                    o.EvokedOscillations = cells{7};
                    success = o.validate();
                    return
                else
                    o.default();
                    WTLog().warn(['The baseline chop parameters (%s) were set by an \n'...
                        'incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                o.default();
                success = false;
            end
        end

        function success = validate(o, throwExcpt)
            throwExcpt = nargin > 1 && throwExcpt; 
            success = true;

            if o.ChopTimeMin > o.ChopTimeMax 
                WTCodingUtils.throwOrLog(WTException.badValue('Field ChopTimeMax < ChopTimeMin'), ~throwExcpt);
                success = false;
            end
            if ~o.NoBaselineCorrection && o.BaselineTimeMin > o.BaselineTimeMax
                WTCodingUtils.throwOrLog(WTException.badValue('Field BaselineTimeMax < BaselineTimeMin'), ~throwExcpt);
                success = false;
            end
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTConfigFormatter.FmtIntStr, o.ChopTimeMin, ...
                WTConfigFormatter.FmtIntStr, o.ChopTimeMax, ...
                WTConfigFormatter.FmtIntStr, o.BaselineTimeMin, ...
                WTConfigFormatter.FmtIntStr, o.BaselineTimeMax, ...
                WTConfigFormatter.FmtInt, o.LogarithmicTransform, ...
                WTConfigFormatter.FmtInt, o.NoBaselineCorrection, ...
                WTConfigFormatter.FmtInt, o.EvokedOscillations);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end