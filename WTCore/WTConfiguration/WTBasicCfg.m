classdef WTBasicCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldFileName = 'filename'
        FldSourceSystem = 'srcsys'
        FldImportDone = 'import'
        FldWaveletAnalysisDone = 'analisys'
        FldChopAndBaselineCorrectionDone = 'correction'
        FldConditionsDifferenceDone = 'difference'
        FldGrandAverageDone = 'average'
    end

    properties
        FilesPrefix char {mustBeNonempty} = 'UnnamedProject'
        SourceSystem char 
        ImportDone uint8 {WTValidations.mustBeZeroOrOne} = 0
        WaveletAnalysisDone uint8 {WTValidations.mustBeZeroOrOne} = 0
        ChopAndBaselineCorrectionDone uint8 {WTValidations.mustBeZeroOrOne} = 0
        ConditionsDifferenceDone uint8 {WTValidations.mustBeZeroOrOne} = 0
        GrandAverageDone uint8 {WTValidations.mustBeZeroOrOne} = 0
    end

    methods
        function o = WTBasicCfg(ioProc)
            o@WTConfigStorage(ioProc, 'filenm.m');
            o.default();
        end

        function default(o) 
            o.FilesPrefix = 'UnnamedProject';
            o.SourceSystem = '';
            o.ImportDone = 0;
            o.WaveletAnalysisDone = 0;
            o.ChopAndBaselineCorrectionDone = 0;
            o.GrandAverageDone = 0;
        end
        
        function success = load(o) 
            % For backward compatibility we accept file having only FldFileName...
            [success, pfx, srcSys, import, wtAnalisys, chopAndBaseline, condsDiff, grandAvg] = o.read(o.FldFileName, ...
                o.FldSourceSystem, o.FldImportDone, o.FldWaveletAnalysisDone, o.FldChopAndBaselineCorrectionDone, ... 
                o.FldConditionsDifferenceDone, o.FldGrandAverageDone);
            if ~success
                WTLog().info('Load of ''%s'' failed, maybe for backward compatibility issues: trying with old format...', o.DataFileName);
                [success, pfx] = o.read(o.FldFileName);
                if ~success
                    return
                end
                srcSys = '';
            end
            try
                o.FilesPrefix = pfx;
                o.SourceSystem = srcSys;
                o.ImportDone = import;
                o.WaveletAnalysisDone = wtAnalisys;
                o.ChopAndBaselineCorrectionDone = chopAndBaseline;
                o.ConditionsDifferenceDone = condsDiff;
                o.GrandAverageDone = grandAvg;
            catch me
                WTLog().except(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt1 = WTConfigFormatter.stringCellsFieldArgs(o.FldFileName, o.FilesPrefix);
            txt2 = WTConfigFormatter.stringCellsFieldArgs(o.FldSourceSystem, o.SourceSystem);
            txt3 = WTConfigFormatter.intField(o.FldImportDone, o.ImportDone);
            txt4 = WTConfigFormatter.intField(o.FldWaveletAnalysisDone, o.WaveletAnalysisDone);
            txt5 = WTConfigFormatter.intField(o.FldChopAndBaselineCorrectionDone, o.ChopAndBaselineCorrectionDone);
            txt6 = WTConfigFormatter.intField(o.FldConditionsDifferenceDone, o.ConditionsDifferenceDone);
            txt7 = WTConfigFormatter.intField(o.FldGrandAverageDone, o.GrandAverageDone);
            success = ~isempty(txt1) && ~isempty(txt2) && o.write(txt1, txt2, txt3, txt4, txt5, txt6, txt7);
        end
    end
end
