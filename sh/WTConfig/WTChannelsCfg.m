classdef WTChannelsCfg < WTConfigStorage & matlab.mixin.Copyable 

    properties(Constant,Access=private)
        FldChannelsLocationFile = 'chanloc'
        FldFileType             = 'filetyp'
        FldSplineFile           = 'splnfile'
        FldReReference          = 'ReRef'
        FldNewChannelsReference = 'newrefchan'
        FldCutChannels          = 'CutChannels'
        DataFileName = 'chan.m'
    end

    properties
        ChannelsLocationFile cell {WTValidations.mustBeALinearCellArrayOfString(ChannelsLocationFile, 1, 1)} = {}
        FileType cell {WTValidations.mustBeALinearCellArrayOfString(FileType, 1, 1)} = {}
        SplineFile cell {WTValidations.SplineFile(SplineFile, 1, 1)} = {}
        ReReference uint8  {mustBeInRange(ReReference,0,1)} = 0
        NewChannelsReference cell {WTValidations.mustBeALinearCellArrayOfString} = {}
        CutChannels cell {WTValidations.mustBeALinearCellArrayOfString} = {}
    end

    methods
        function o = WTChannelsCfg(ioProc)
            o@WTConfigStorage(ioProc, DataFileName);
            o.default();
        end

        function default(o) 
            o.ChannelsLocationFile = { '' };
            o.FileType =  { 'autodetect' };
            o.SplineFile = { '' };
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
                o.ChannelsLocationFile = chnsLocFile;
                o.FileType = fileTyp;
                o.SplineFile = splnFile;
                o.ReReference = reRef;
                o.NewChannelsReference = newRefChns;
                o.CutChannels = cutChns;
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt1 = WTFormatter.StringCellsField(o.FldChannelsLocationFile, o.ChannelsLocationFile);
            txt2 = WTFormatter.StringCellsField(o.FldFileType, o.FileType);
            txt3 = WTFormatter.StringCellsField(o.FldSplineFile, o.SplineFile);
            txt4 = WTFormatter.GenericCellsFieldArgs(o.FldReReference, WTFormatter.FmtInt, o.ReReference);
            txt5 = WTFormatter.StringCellsField(o.FldNewChannelsReference, o.NewChannelsReference);
            txt6 = WTFormatter.StringCellsField(o.FldCutChannels, o.CutChannels);
            success = ~any(cellfunc(@isempty,{txt1 txt2 txt3 txt4 txt5 txt6})) && ... 
                      o.write(txt1,txt2,txt3,txt4,txt5,txt6);
        end
    end
end