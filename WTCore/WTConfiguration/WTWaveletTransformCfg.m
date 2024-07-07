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

classdef WTWaveletTransformCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldDefaultAnswer = 'defaultanswer'
    end

    properties
        TimeMin(1,1) int32
        TimeMax(1,1) int32
        TimeRes(1,1) uint32 
        FreqMin(1,1) uint32 {WTValidations.mustBeGT(FreqMin,0)} = 1
        FreqMax(1,1) uint32 {WTValidations.mustBeGT(FreqMax,0)} = 1
        FreqRes(1,1) uint32 {WTValidations.mustBeGT(FreqRes,0)} = 1
        EdgePadding(1,1) uint32
        ChannelsList(1,:) uint32
        EpochsList(1,:) uint32
        LogarithmicTransform(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        EvokedOscillations(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        NormalizedWavelets(1,1) uint8 {WTValidations.mustBeZeroOrOne} = 0
        WaveletsCycles(1,1) uint8 {WTValidations.mustBeInRange(WaveletsCycles,2,15,1,1)} = 7
    end
    methods
        function o = WTWaveletTransformCfg(ioProc)
            o@WTConfigStorage(ioProc, 'tf_cmor_cfg.m');
            o.default();
        end

        function default(o) 
            o.TimeMin = 0;
            o.TimeMax = 0;
            o.TimeRes = 1;
            o.FreqMin = 1;
            o.FreqMax = 1;
            o.FreqRes = 1;
            o.EdgePadding = 0;
            o.ChannelsList = [];
            o.EpochsList = [];
            o.LogarithmicTransform = 0;
            o.EvokedOscillations = 0;
            o.NormalizedWavelets = 1;
            o.WaveletsCycles = 7;
        end

        function set.ChannelsList(o, value)
            o.ChannelsList = unique(value);
        end

        function set.EpochsList(o, value)
            o.EpochsList = unique(value);
        end

        function success = load(o) 
            [success, cells] = o.read(o.FldDefaultAnswer);
            if ~success 
                return
            end 
            try
                if length(cells) >= 13 
                    o.TimeMin = WTNumUtils.str2double(cells{1});
                    o.TimeMax = WTNumUtils.str2double(cells{2});
                    o.TimeRes = WTNumUtils.str2double(cells{3});
                    o.FreqMin = WTNumUtils.str2double(cells{4});
                    o.FreqMax = WTNumUtils.str2double(cells{5});
                    o.FreqRes = WTNumUtils.str2double(cells{6});
                    o.EdgePadding = WTNumUtils.str2double(cells{7});
                    o.ChannelsList = WTNumUtils.str2nums(cells{8});
                    o.EpochsList = WTNumUtils.str2nums(cells{9});
                    o.LogarithmicTransform = cells{10};
                    o.EvokedOscillations = cells{11};
                    o.NormalizedWavelets = cells{12};
                    o.WaveletsCycles = cells{13};
                else
                    o.data.waveletTransform = o.default();
                    WTLog().warn(['The complex Morlet transformation parameters (%s) were set by an \n'...
                        'incompatible version of WTools, hence they have been reset...'], o.DataFileName); 
                end
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt = WTConfigFormatter.genericCellsFieldArgs(o.FldDefaultAnswer, ...
                WTConfigFormatter.FmtIntStr, o.TimeMin, ...
                WTConfigFormatter.FmtIntStr, o.TimeMax, ...
                WTConfigFormatter.FmtIntStr, o.TimeRes, ...
                WTConfigFormatter.FmtIntStr, o.FreqMin, ...    
                WTConfigFormatter.FmtIntStr, o.FreqMax, ...
                WTConfigFormatter.FmtIntStr, o.FreqRes, ...    
                WTConfigFormatter.FmtIntStr, o.EdgePadding, ...   
                WTConfigFormatter.FmtArrayStr, num2str(o.ChannelsList), ...
                WTConfigFormatter.FmtArrayStr, num2str(o.EpochsList), ...
                WTConfigFormatter.FmtInt, o.LogarithmicTransform, ...
                WTConfigFormatter.FmtInt, o.EvokedOscillations, ...
                WTConfigFormatter.FmtInt, o.NormalizedWavelets, ...
                WTConfigFormatter.FmtInt, o.WaveletsCycles);
            success = ~isempty(txt) && o.write(txt);
        end
    end
end

