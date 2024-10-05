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

classdef WT3DScalpMapPlotsCfg < WTConfigStorage & WTPacedTimeFreqCfg & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
        FldSplineFile    = 'SplineFile'
        FldSplineLocal   = 'LocalSpline'
    end

    properties (Access = private)
        GuardedSet logical
    end

    properties
        Scale(1,:) single {WTValidations.mustBeLimitedLinearArray(Scale, 1, 2, 1)}
        SplineFile char
        SplineLocal int8 {WTValidations.mustBeZeroOrOne} = 0
    end

    methods
        function o = WT3DScalpMapPlotsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'smavr3d_cfg.m');
            o@WTPacedTimeFreqCfg();
            o.AllowTimeResolution = false;
            o.AllowFreqResolution = false;
            o.default();
        end

        function default(o) 
            default@WTPacedTimeFreqCfg(o);
            o.GuardedSet = false;
            o.Scale = [];
            o.SplineFile = '';
            o.SplineLocal = 0;
            o.GuardedSet = true;
        end

        function set.SplineFile(o, value)
            if o.GuardedSet
                WTValidations.mustBeNonEmptyChar(value);
            end
            o.SplineFile = value;
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 

            [splineSuccess, splineFile, splineLocal] = o.read(o.FldSplineFile, o.FldSplineLocal);

            try
                if splineSuccess && length(cells) >= 3  
                    o.Time = cells{1};
                    o.Frequency = cells{2};
                    o.Scale = WTNumUtils.str2nums(cells{3});
                    o.SplineFile = splineFile;
                    o.SplineLocal = splineLocal;
                    success = o.validate();
                else 
                    o.default();
                    WTLog().warn(['The parameters for 3D scalp map plots (%s) were set by an \n' ...
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
            success = validate@WTPacedTimeFreqCfg(o, throwExcpt);
            if ~success 
                return
            end
            if o.Scale(1) >= o.Scale(2) 
                WTCodingUtils.throwOrLog(WTException.badValue('Field Scale(2) <= Scale(1)'), ~throwExcpt);
                return
            end
            success = true;
        end

        function success = persist(o)
            txt1 = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTConfigFormatter.FmtArrayStr, num2str(o.Time), ...
                WTConfigFormatter.FmtArrayStr, num2str(o.Frequency), ...
                WTConfigFormatter.FmtArrayStr, num2str(o.Scale));
            txt2 = WTConfigFormatter.genericCellsFieldArgs(o.FldSplineFile, WTConfigFormatter.FmtStr, o.SplineFile);
            txt3 = WTConfigFormatter.intField(o.FldSplineLocal, o.SplineLocal);
            success = ~any(cellfun(@isempty,{txt1 txt2 txt3})) && ... 
                      o.write(txt1,txt2,txt3);
        end
    end
end