classdef WTConfig < matlab.mixin.Copyable 

    properties
        Prefix WTPrefixCfg
        Subjects WTSubjectsCfg
        Conditions WTConditionsCfg
        Channels WTChannelsCfg
        SubjectsGrand WTSubjectsGrandCfg
        ConditionsGrand WTConditionsGrandCfg
        GrandAverage WTGrandAverageCfg
        BaselineChop WTBaselineChopCfg
        ImportType WTImportTypeCfg
        EGIToEEGLab WTEGIToEEGLabCfg
        BRVToEEGLab WTBRVToEEGLabCfg
        EEPToEEGLab WTEEPToEEGLabCfg
        WaveletTransform WTWaveletTransformCfg
        Statistics WTStatisticsCfg
        Difference WTDifferenceCfg
        MinMaxTrialId WTMinMaxTrialIdCfg
        GlobalPlots WTGlobalPlotsCfg
        Sampling WTSamplingCfg
    end

    properties(SetAccess=private,GetAccess=public)
        IOProc
    end

    methods(Access=private)
        function default(o)
            o.Prefix.default();
            o.Subjects.default();
            o.Conditions.default();
            o.Channels.default();
            o.SubjectsGrand.default();
            o.ConditionsGrand.default();
            o.GrandAverage.default();
            o.BaselineChop.default();
            o.ImportType.default();
            o.EGIToEEGLab.default();
            o.BRVToEEGLab.default();
            o.EEPToEEGLab.default();
            o.WaveletTransform.default();
            o.Statistics.default();
            o.Difference.default();
            o.MinMaxTrialId.default();
            o.GlobalPlots.default();
            o.Sampling.default();
        end

        function success = load(o) 
            success = false;
            wtLog = WTLog();
            
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
            if o.Channels.exist() && ~o.Channels.load()
                wtLog.err('Failed to load channels configuration file: ''%s'' ', o.Channels.getFileName());
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
            if o.GrandAverage.exist() && ~o.GrandAverage.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.GrandAverage.getFileName());
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
            if o.ImportType.exist() && ~o.ImportType.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.ImportType.getFileName());
                return
            end
            if o.EGIToEEGLab.exist() && ~o.EGIToEEGLab.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.EGIToEEGLab.getFileName());
                return
            end
            if o.BRVToEEGLab.exist() && ~o.BRVToEEGLab.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.BRVToEEGLab.getFileName());
                return
            end
            if o.EEPToEEGLab.exist() && ~o.EEPToEEGLab.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.EEPToEEGLab.getFileName());
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
            if o.Sampling.exist() &&  ~o.Sampling.load()
                wtLog.err('Failed to load configuration file: ''%s'' ', o.Sampling.getFileName());
                return
            end
            success = true;
        end
    end

    methods(Access = protected)
        function cp = copyElement(o)
            cp = copyElement@matlab.mixin.Copyable(o);
            cp.IOProc = o.ioProc;
            cp.Prefix = copy(o.Prefix);
            cp.Subjects = copy(o.Subjects);
            cp.Conditions = copy(o.Conditions);
            cp.Channels = copy(o.Channels);
            cp.SubjectsGrand = copy(o.SubjectsGrand);
            cp.GrandAverage = copy(o.GrandAverage);
            cp.ConditionsGrand = copy(o.ConditionsGrand);
            cp.BaselineChop = copy(o.BaselineChop);
            cp.ImportType = copy(o.ImportType);
            cp.EGIToEEGLab = copy(o.EGIToEEGLab);
            cp.BRVToEEGLab = copy(o.BRVToEEGLab);
            cp.EEPToEEGLab = copy(o.EEPToEEGLab);
            cp.WaveletTransform = copy(o.WaveletTransform);
            cp.Statistics = copy(o.Statistics);
            cp.Difference = copy(o.Difference);
            cp.MinMaxTrialId = copy(o.MinMaxTrialId);
            cp.GlobalPlots = copy(o.GlobalPlots);
            cp.Sampling = copy(o.Sampling);
        end
     end

    methods
        function o = WTConfig()
            ioProc = WTIOProcessor();
            o.IOProc = ioProc;
            o.Prefix = WTPrefixCfg(ioProc);
            o.Subjects = WTSubjectsCfg(ioProc);
            o.Conditions = WTConditionsCfg(ioProc);
            o.Channels = WTChannelsCfg(ioProc);
            o.SubjectsGrand = WTSubjectsGrandCfg(ioProc);
            o.ConditionsGrand = WTConditionsGrandCfg(ioProc);
            o.GrandAverage = WTGrandAverageCfg(ioProc);
            o.BaselineChop = WTBaselineChopCfg(ioProc);
            o.ImportType = WTImportTypeCfg(ioProc);
            o.EGIToEEGLab = WTEGIToEEGLabCfg(ioProc);
            o.BRVToEEGLab = WTBRVToEEGLabCfg(ioProc);
            o.EEPToEEGLab = WTEEPToEEGLabCfg(ioProc);
            o.WaveletTransform = WTWaveletTransformCfg(ioProc);
            o.Statistics = WTStatisticsCfg(ioProc);
            o.Difference = WTDifferenceCfg(ioProc);
            o.MinMaxTrialId = WTMinMaxTrialIdCfg(ioProc);
            o.GlobalPlots = WTGlobalPlotsCfg(ioProc);
            o.Sampling = WTSamplingCfg(ioProc);
        end
        
        function name = getName(o) 
            name = WTUtils.getPathTail(o.IOProc.RootDir);
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
            name = WTUtils.getPathTail(rootDir);
            o.Prefix.FilesPrefix = name;
            success = o.IOProc.setRootDir(rootDir, false) && o.Prefix.persist();
        end
    end
end