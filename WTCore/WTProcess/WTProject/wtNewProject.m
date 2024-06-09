function success = wtNewProject
    success = false;
    wtProject = WTProject();
    prjName = '';

    while true 
        prms = { { 'style' 'text' 'string' 'New project name:' } ...
                 { 'style' 'edit' 'string' prjName } };
        answer = WTEEGLabUtils.eeglabInputMask( 'geometry', { [1 2] }, 'uilist', prms, 'title', '[WTools] Set project name');

        if isempty(answer)
            return 
        end

        prjName = strip(answer{1});
        if wtProject.checkIsValidName(prjName, true)
            break;
        end
    end

    prjParentDir = WTDialogUtils.uiGetDir('.', 'Select the project parent directory...', ... 
        'excludeDirs', ['^' regexptranslate('escape', WTLayout.getToolsDir())]);
    
        if ~ischar(prjParentDir)
        return
    end

    prjPath = fullfile(prjParentDir, prjName);
    if  WTIOUtils.dirExist(prjPath)
        if ~WTEEGLabUtils.eeglabYesNoDlg('Warning', ['Project directory already exists!\n' ...
            'Directory: %s\n' ...
            'Do you want to overwrite it?'], prjPath)
            return;
        end            
    end

    if ~wtProject.new(prjPath)
        return
    end

    wtAppConfig = WTAppConfig();

    if wtAppConfig.ProjectLog
        ioProc = wtProject.Config.IOProc;
        wtLog = WTLog();
        [~, opened] = wtLog.openStream(ioProc.getLogFile(prjName));
        wtLog.MuteStdStreams = WTCodingUtils.ifThenElse(opened, wtAppConfig.MuteStdLog, false);
    end

    wtImport(true);
    success = true;
end