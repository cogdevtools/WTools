classdef WTConfig < matlab.mixin.Copyable

    properties
        Prefix WTPrefixCfg
        Import WTImportCfg
        Subjects WTSubjectsCfg
        Conditions WTConditionsCfg
        SubjectsGrand WTSubjectsGrandCfg
        ConditionsGrand WTConditionsGrandCfg
        BaselineChop WTBaselineChopCfg
        ImportToEEGLab WTImportToEEGLabCfg
        EGIToEEGL WTEGIToEEGLabCfg
        WaveletTransform WTWaveletTransformCfg
        Statistics WTStatisticsCfg
        Difference WTDifferenceCfg
        MinMaxTrialId WTMinMaxTrialIdCfg
        GlobalPlots WTGlobalPlotsCfg
    end

    properties(SetAccess=private,GetAccess=public)
        IOProc
    end

    methods(Access=private)
        function default(o)
            o.Prefix.default();
            o.Import.default();
            o.Subjects.default();
            o.Conditions.default();
            o.SubjectsGrand.default();
            o.ConditionsGrand.default();
            o.BaselineChop.default();
            o.ImportToEEGLab.default();
            o.EGIToEEGL.default();
            o.WaveletTransform.default();
            o.Statistics.default();
            o.Difference.default();
            o.MinMaxTrialId.default();
            o.GlobalPlots.default();
        end

        function success = load(o) 
            success = false;
            wtLog = WTLog();
            
            if ~o.Import.exist() 
                wtLog.err('An essential configuration file is missing: ''%s'' ', o.Import.getFileName());
                return
            end
            if ~o.Import.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.Import.getFileName());
                return
            end
            if ~o.Prefix.exist()
                wtLog.err('An essential project configuration file is missing: ''%s'' ', o.Prefix.getFileName());
                return
            end
            if ~o.Prefix.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.Prefix.getFileName());
                return
            end
            if o.Subjects.exist() && ~o.Subjects.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.Subjects.getFileName());
                return
            end
            if o.Conditions.exist() && ~o.Conditions.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.Conditions.getFileName());
                return
            end
            if o.SubjectsGrand.exist() && ~o.SubjectsGrand.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.SubjectsGrand.getFileName());
                return
            end
            if o.ConditionsGrand.exist() && ~o.ConditionsGrand.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.ConditionsGrand.getFileName());
                return
            end
            if o.WaveletTransform.exist() && ~o.WaveletTransform.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.WaveletTransform.getFileName());
                return
            end
            if o.BaselineChop.exist() && ~o.BaselineChop.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.BaselineChop.getFileName());
                return
            end
            if o.ImportToEEGLab.exist() && ~o.ImportToEEGLab.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.ImportToEEGLab.getFileName());
                return
            end
            if o.EGIToEEGL.exist() && ~o.EGIToEEGL.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.EGIToEEGL.getFileName());
                return
            end
            if o.Statistics.exist() && ~o.Statistics.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.Statistics.getFileName());
                return
            end
            if o.Difference.exist() && ~o.Difference.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.Difference.getFileName());
                return
            end
            if o.MinMaxTrialId.exist() && ~o.MinMaxTrialId.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.MinMaxTrialId.getFileName());
                return
            end
            if o.GlobalPlots.exist() && ~o.GlobalPlots.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.GlobalPlots.getFileName());
                return
            end
            success = true;
        end
    end

    methods(Access = protected)
        function cp = copyElement(o)
            cp = copyElement@matlab.mixin.Copyable(o);
            cp.ioProc = o.ioProc;
            cp.Prefix = copy(o.Prefix);
            cp.Import = copy(o.Import);
            cp.Subjects = copy(o.Subjects);
            cp.Conditions = copy(o.Conditions);
            cp.SubjectsGrand = copy(o.SubjectsGrand);
            cp.ConditionsGrand = copy(o.ConditionsGrand);
            cp.BaselineChop = copy(o.BaselineChop);
            cp.ImportToEEGLab = copy(o.ImportToEEGLab);
            cp.EGIToEEGL = copy(o.EGIToEEGL);
            cp.WaveletTransform = copy(o.WaveletTransform);
            cp.Statistics = copy(o.Statistics);
            cp.Difference = copy(o.Difference);
            cp.MinMaxTrialId = copy(o.MinMaxTrialId);
            cp.GlobalPlots = copy(o.GlobalPlots);
        end
     end

    methods
        function o = WTConfig()
            ioProc = IOProcessor();
            o.IOProc = ioProc;

            o.Prefix = WTPrefixCfg(ioProc);
            o.Import = WTImportCfg(ioProc);
            o.Subjects = WTSubjectsCfg(ioProc);
            o.Conditions = WTConditionsCfg(ioProc);
            o.SubjectsGrand = WTSubjectsGrandCfg(ioProc);
            o.ConditionsGrand = WTConditionsGrandCfg(ioProc);
            o.BaselineChop = WTBaselineChopCfg(ioProc);
            o.ImportToEEGLab = WTImportToEEGLabCfg(ioProc);
            o.EGIToEEGLab = WTEGIToEEGLabCfg(ioProc);
            o.WaveletTransform = WTWaveletTransformCfg(ioProc);
            o.Statistics = WTStatisticsCfg(ioProc);
            o.Difference = WTDifferenceCfg(ioProc);
            o.MinMaxTrialId = WTMinMaxTrialIdCfg(ioProc);
            o.GlobalPlots = WTGlobalPlotsCfg(ioProc);
        end
        
        function name = getName(o) 
            name = WTUtils.getPathTrail(o.IOProc.RootDir);
        end

        function rootDir = getRootDir(o) 
            rootDir = o.IOProc.RootDir;
        end

        function configDir = getConfigDir(o) 
            configDir = o.IOProc.ConfigDir;
        end

        function success = open(o, rootDir)
            o.default();
            success = o.IOProc.setRootDir(rootDir, true) &&  o.load();
        end

        function success = new(o, rootDir)
            o.default()
            success = o.IOProc.setRootDir(rootDir, false) && o.Prefix.save() && o.Import.save();
        end
    end
end