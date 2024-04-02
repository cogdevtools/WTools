classdef WTChannelsCfg < WTConfigStorage & matlab.mixin.Copyable 

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

    properties
        ChannelsLocationFile char
        ChannelsLocationFileType char
        SplineFile char
        ReReference uint8  {mustBeInRange(ReReference,0,2)} = 0
        NewChannelsReference cell {WTValidations.mustBeALinearCellArrayOfString} = {}
        CutChannels cell {WTValidations.mustBeALinearCellArrayOfString} = {}
    end

    methods
        function o = WTChannelsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'chan.m');
            o.default();
        end

        function default(o) 
            o.ChannelsLocationFile = [];
            o.ChannelsLocationFileType = 'autodetect';
            o.SplineFile = [];
            o.ReReference = 0;
            o.NewChannelsReference = { '' };
            o.CutChannels = { };
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
                WTValidations.mustBeALimitedLinearCellArrayOfString(chnsLocFile, 1, 1, 0);
                WTValidations.mustBeALimitedLinearCellArrayOfString(fileTyp, 1, 1, 0);
                WTValidations.mustBeALimitedLinearCellArrayOfString(splnFile, 1, 1, 0);
                o.ChannelsLocationFile = chnsLocFile{1};
                o.ChannelsLocationFileType = fileTyp{1};
                o.SplineFile = splnFile{1};
                o.ReReference = reRef{1};
                o.NewChannelsReference = newRefChns;
                o.CutChannels = cutChns;
                o.validate(true);
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = validate(o, throwExcpt) 
            throwExcpt = nargin > 1 && any(logical(throwExcpt)); 
            success = true;

            if isempty(o.ChannelsLocationFile) 
                WTUtils.throwOrLog(WTException.badValue('Empty channel location file'), ~throwExcpt);
                success = false;
            end
            if isempty(o.ChannelsLocationFileType) 
                WTUtils.throwOrLog(WTException.badValue('Empty channel location file type'), ~throwExcpt);
                success = false;
            end
            if isempty(o.SplineFile) 
                WTUtils.throwOrLog(WTException.badValue('Empty spline file'), ~throwExcpt);
                success = false;
            end
            chansIntersect = intersect(o.CutChannels, o.NewChannelsReference);
            if ~isempty(chansIntersect)
                WTUtils.throwOrLog(WTException.badValue('Reference channels list contains cut channel(s): %s', ...
                    char(join(chansIntersect))), ~throwExcpt);
                success = false;
            end
        end

        function success = persist(o)
            txt1 = WTFormatter.GenericCellsFieldArgs(o.FldChannelsLocationFile, WTFormatter.FmtStr, o.ChannelsLocationFile);
            txt2 = WTFormatter.GenericCellsFieldArgs(o.FldFileType, WTFormatter.FmtStr, o.ChannelsLocationFileType);
            txt3 = WTFormatter.GenericCellsFieldArgs(o.FldSplineFile, WTFormatter.FmtStr, o.SplineFile);
            txt4 = WTFormatter.GenericCellsFieldArgs(o.FldReReference, WTFormatter.FmtInt, o.ReReference);
            txt5 = WTFormatter.StringCellsField(o.FldNewChannelsReference, o.NewChannelsReference);
            txt6 = WTFormatter.StringCellsField(o.FldCutChannels, o.CutChannels);
            success = ~any(cellfun(@isempty,{txt1 txt2 txt3 txt4 txt5 txt6})) && ... 
                      o.write(txt1,txt2,txt3,txt4,txt5,txt6);
        end
    end
end