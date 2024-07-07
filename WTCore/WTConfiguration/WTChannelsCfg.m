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

classdef WTChannelsCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=public)
        ReReferenceNone         = 0
        ReReferenceWithAverage  = 1
        ReReferenceWithChannels = 2
    end

    properties(Constant,Access=private)
        FldChannelsLocationFile = 'chanloc'
        FldFileType             = 'filetyp'
        FldSplineFile           = 'splnfile'
        FldReReference          = 'ReRef'
        FldNewChannelsReference = 'newrefchan'
        FldCutChannels          = 'CutChannels'
    end

    properties (Access = private)
        GuardedSet logical
    end

    properties
        ChannelsLocationFile char
        ChannelsLocationFileType char
        SplineFile char
        ReReference uint8 {WTValidations.mustBeInRange(ReReference,0,2,1,1)} = 0
        NewChannelsReference cell {WTValidations.mustBeLinearCellArrayOfChar} = {}
        CutChannels cell {WTValidations.mustBeLinearCellArrayOfChar} = {}
    end

    methods
        function o = WTChannelsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'chan.m');
            o.default();
        end

        function default(o) 
            o.GuardedSet = false;
            o.ChannelsLocationFile = [];
            o.ChannelsLocationFileType = 'autodetect';
            o.SplineFile = [];
            o.ReReference = 0;
            o.NewChannelsReference = { '' };
            o.CutChannels = { };
            o.GuardedSet = true;
        end

        function success = load(o) 
            [success, chnsLocFile, fileTyp, splnFile, reRef, newRefChns, cutChns] = o.read(o.FldChannelsLocationFile, ...
                o.FldFileType, ...
                o.FldSplineFile, ...
                o.FldReReference, ...
                o.FldNewChannelsReference, ...
                o.FldCutChannels);
            if ~success 
                return
            end
            try
                WTValidations.mustBeLimitedLinearCellArrayOfChar(chnsLocFile, 1, 1, 0);
                WTValidations.mustBeLimitedLinearCellArrayOfChar(fileTyp, 1, 1, 0);
                WTValidations.mustBeLimitedLinearCellArrayOfChar(splnFile, 1, 1, 0);
                o.ChannelsLocationFile = chnsLocFile{1};
                o.ChannelsLocationFileType = fileTyp{1};
                o.ReReference = reRef{1};
                o.NewChannelsReference = newRefChns;
                o.CutChannels = cutChns;
                o.GuardedSet = false; % SplineFile could be empty
                o.SplineFile = splnFile{1};
                o.GuardedSet = true;
                o.validate(true);
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function set.ChannelsLocationFile(o, value)
            if o.GuardedSet
                WTValidations.mustBeNonEmptyChar(value);
            end
            o.ChannelsLocationFile = value;
        end

        function set.ChannelsLocationFileType(o, value)
            if o.GuardedSet
                WTValidations.mustBeNonEmptyChar(value);
            end
            o.ChannelsLocationFileType = value;
        end

        function set.SplineFile(o, value)
            if o.GuardedSet
                WTValidations.mustBeNonEmptyChar(value);
            end
            o.SplineFile = value;
        end

        function success = validate(o, throwExcpt) 
            throwExcpt = nargin > 1 && throwExcpt; 
            success = true;

            chansIntersect = intersect(o.CutChannels, o.NewChannelsReference);

            if ~isempty(chansIntersect)
                WTCodingUtils.throwOrLog(WTException.badValue('Reference channels list contains cut channel(s): %s', ...
                    char(join(chansIntersect))), ~throwExcpt);
                success = false;
            end
        end

        function success = persist(o)
            txt1 = WTConfigFormatter.genericCellsFieldArgs(o.FldChannelsLocationFile, WTConfigFormatter.FmtStr, o.ChannelsLocationFile);
            txt2 = WTConfigFormatter.genericCellsFieldArgs(o.FldFileType, WTConfigFormatter.FmtStr, o.ChannelsLocationFileType);
            txt3 = WTConfigFormatter.genericCellsFieldArgs(o.FldSplineFile, WTConfigFormatter.FmtStr, o.SplineFile);
            txt4 = WTConfigFormatter.genericCellsFieldArgs(o.FldReReference, WTConfigFormatter.FmtInt, o.ReReference);
            txt5 = WTConfigFormatter.stringCellsField(o.FldNewChannelsReference, o.NewChannelsReference);
            txt6 = WTConfigFormatter.stringCellsField(o.FldCutChannels, o.CutChannels);
            success = ~any(cellfun(@isempty,{txt1 txt2 txt3 txt4 txt5 txt6})) && ... 
                      o.write(txt1,txt2,txt3,txt4,txt5,txt6);
        end
    end
end