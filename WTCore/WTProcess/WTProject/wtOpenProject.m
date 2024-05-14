function success = wtOpenProject
    success = false;

    prjPath = WTDialogUtils.uiGetDir('.', 'Select the project directory...');
    if ~ischar(prjPath)
        return
    end

    wtProject = WTProject();
    
    if ~wtProject.open(prjPath) 
        return
    end

    wtAppConfig = WTAppConfig();

    if wtAppConfig.ProjectLog
        ioProc = wtProject.Config.IOProc;
        wtLog = WTLog();
        [~, opened] = wtLog.openStream(ioProc.getLogFile(wtProject.Config.getName()));
        wtLog.MuteStdStreams = WTCodingUtils.ifThenElse(opened, wtAppConfig.MuteStdLog, false);
    end

    success = true;
end