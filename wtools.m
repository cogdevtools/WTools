function varargout = wtools(varargin)
    % WTOOLS M-file for wtools.fig
    %      This function opens the WTools GUI.
    %
    %      WTOOLS, by itself, creates a new WTOOLS or raises the existing
    %      singleton*.
    %
    %      H = WTOOLS returns the handle to a new WTOOLS or the handle to
    %      the existing singleton*.
    %
    %      WTOOLS('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in WTOOLS.M with the given input arguments.
    %
    %      WTOOLS('Property','Value',...) creates a new WTOOLS or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before wtools_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to wtools_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    % Edit the above text to modify the response to help wtools
    % Last Modified by GUIDE v2.5 09-May-2024 11:59:45
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    guiPresets();
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @wtools_OpeningFcn, ...
                       'gui_OutputFcn',  @wtools_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    
    i = 1;
    while i <= nargin
        if ischar(varargin{i})
            switch varargin{i}
                case 'help'
                case 'no-splash'
                case 'close'
                case 'configure'
                otherwise
                    gui_State.gui_Callback = str2func(varargin{i});
            end
        end
        i = i+1;
    end
    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
    
    % --- Executes just before wtools is made visible.
    function wtools_OpeningFcn(hObject, eventdata, handles, varargin)
        % This function has no output args, see OutputFcn.
        % hObject    handle to figure
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)

        % BailOut has been to true set within wtools_CreateFcn if wtinit has failed...
        if hObject.UserData.BailOut
            quitApp(hObject);
            return
        end

        wtoolsOpen = isfield(hObject.UserData, 'WToolsOpen');
        help = false;
        close = false;
        showSplash = true;
        configure = false;
        wtLog = [];

        if wtoolsOpen 
            wtLog = WTLog();
        end

        try
            for i = 1:nargin-3
                switch varargin{i}
                    case 'help'
                        help = true;
                        break
                    case 'no-splash'
                        showSplash = false;
                        break
                    case 'close'
                        close = true;
                        break
                    case 'configure'
                        configure = true;
                        break
                    otherwise
                        fprintf(2, 'WTools: some options were ignored as unknown!\n');
                        fprintf(2, '        Run ''wtools help''...\n');
                end
            end

            if configure
                close = configureApp(hObject, handles) && ~wtoolsOpen;
            elseif help 
                displayHelp();
                close = ~wtoolsOpen;
            elseif ~wtoolsOpen
                wtLog = WTLog();
                wtLog.contextOn('Open');
                WTSession().open();
                wtAppConfig = WTAppConfig();

                if showSplash && wtAppConfig.ShowSplashScreen       
                    wtSplash();
                end
                if ~WTEEGLabUtils.eeglabDep()
                    close = true;
                end
                wtLog.reset();
            end

        catch me
            try
                wtLog.except(me);
                wtLog.reset();
            catch
            end
            close = true;
        end

        if close
            quitApp(hObject);
            % return as hObject and the handles have been freed
            return 
        end

        hObject.UserData.WToolsOpen = true;
        % Choose default command line output for wtools
        handles.output = hObject;
        % Update handles structure
        guidata(hObject, handles);
        % UIWAIT makes wtools wait for user response (see UIRESUME)
        % uiwait(handles.figure1);
    
    % --- Outputs from this function are returned to the command line.
    function varargout = wtools_OutputFcn(hObject, eventdata, handles) 
        % varargout  cell array for returning output args (see VARARGOUT);
        % hObject    handle to figure
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        % Get default command line output from handles structure
        % If ForceQuit was set the figure has been deleted at this point
        % so we need to check if handles is empty or not.
        if ~isempty(handles) && any(strcmp(fieldnames(handles), 'output'))
            varargout{1} = handles.output;
        else
            varargout{1} = {};
        end
    
    % --- Executes during object creation, after setting all properties.
    function WTools_CreateFcn(hObject, eventdata, handles)
        % hObject    handle to WTools (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    empty - handles not created until after all CreateFcns called
        hObject.UserData = struct();
        hObject.UserData.BailOut = false;
        [initOk, pathsContext] = wtInit();
        hObject.UserData.PathsContext = pathsContext;
        if ~initOk
            % Note: all _CreateFcn must manage the fact that WTools class might not
            % be in the paths, so if they reference one, they should protect the code
            % within a try-catch. Idem for the _DeleteFcn;
            hObject.UserData.BailOut = true;
            return
        end

    % --- Executes during object deletion, before destroying properties.
    function WTools_DeleteFcn(hObject, eventdata, handles)
        % hObject    handle to WTools (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        try 
            WTLog().contextOn('Close');
        catch
        end
        try 
            WTSession().close();
        catch
        end
        try
            WTSingletons.clear();
        catch
        end
        restorePaths(hObject); 
    
    % --- Executes when user attempts to close WTools.
    function WTools_CloseRequestFcn(hObject, eventdata, handles)
        % hObject    handle to WTools (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        option = WTDialogUtils.askDlg('Confirm', 'Sure to quit?', {}, {'Continue', 'Quit'}, 'Continue');
        unlock(hObject, handles);
        if strcmp(option, 'Continue')
            return
        end
        quitApp(hObject);

    % --- Executes on button press in NewProjectPushButton.
    function NewProject_Callback(hObject, eventdata, handles)
        % hObject    handle to NewProjectPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('NEW PROJECT');
        wtLog.contextOn('NewProject');
        updateApplicationStatus(hObject, handles, true);
        try
            wtNewProject();
            updateProjectName(hObject, handles);
            updateProjectDirectory(hObject, handles);
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to create a new project');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in OpenProjectPushButton.
    function OpenProject_Callback(hObject, eventdata, handles)
        % hObject    handle to OpenProjectPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('OPEN PROJECT');
        wtLog.contextOn('OpenProject');
        updateApplicationStatus(hObject, handles, true);
        try
            wtOpenProject();
            updateProjectName(hObject, handles);
            updateProjectDirectory(hObject, handles);
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to open a project');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ImportDataPushButton.
    function ImportData_Callback(hObject, eventdata, handles)
        % hObject    handle to ImportDataPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('DATA IMPORT');
        wtLog.contextOn('Import');
        updateApplicationStatus(hObject, handles, true);
        try
            wtImport();
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to import data');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();  
        unlock(hObject, handles);
    
    % --- Executes on button press in SubjectsManagerPushButton.
    function SubjectsManager_Callback(hObject, eventdata, handles)
        % hObject    handle to SubjectsManagerPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('SUBJECTS MANAGER');
        wtLog.contextOn('SubjectsManager');
        updateApplicationStatus(hObject, handles, true);
        try
            wtRebuildSubjects();
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to rebuild subjects');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in WaveletTransformPushButton.
    function WaveletTransform_Callback(hObject, eventdata, handles)
        % hObject    handle to WaveletTransformPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('TIME/FREQ ANALYSIS');
        wtLog.contextOn('TimeFreqAnalysis');
        updateApplicationStatus(hObject, handles, true);
        try
            wtPerformCWT();
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to perform time/frequency analysis');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ChopAndBaselinePushButton.
    function ChopAndBaseline_Callback(hObject, eventdata, handles)
        % hObject    handle to ChopAndBaselinePushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('BASELINE/CHOPPING');
        wtLog.contextOn('Baseline/Chopping');
        updateApplicationStatus(hObject, handles, true);
        try
            wtBaselineChop();
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to perform calculate baseline or perform chopping');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ConditionsDifferencePushButton.
    function ConditionsDifference_Callback(hObject, eventdata, handles)
        % hObject    handle to ConditionsDifferencePushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('CONDITIONS DIFFERENCE');
        wtLog.contextOn('ConditionsDifference');
        updateApplicationStatus(hObject, handles, true);
        try
            wtConditionsDifference();
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to perform conditions difference');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in SubjectsGrandAveragePushButton.
    function SubjectsGrandAverage_Callback(hObject, eventdata, handles)
        % hObject    handle to SubjectsGrandAveragePushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('SUBJECTS GRAND AVERAGE');
        wtLog.contextOn('SubjectsGrandAverage');
        updateApplicationStatus(hObject, handles, true);
        try
            wtGrandAverage();
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to perform grand average');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in AveragePlotsPushButton.
    function AveragePlots_Callback(hObject, eventdata, handles)
        % hObject    handle to AveragePlotsPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('AVERAGE PLOTS');
        wtLog.contextOn('AveragePlots');
        updateApplicationStatus(hObject, handles, true);
        try
            wtAvgPlots();
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to show average plots');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ChannelsAveragePlotsPushButton.
    function ChannelsAveragePlots_Callback(hObject, eventdata, handles)
        % hObject    handle to ChannelsAveragePlotsPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('CHANNELS AVERAGE PLOTS');
        wtLog.contextOn('ChannelsAveragePlots');
        updateApplicationStatus(hObject, handles, true);
        try
            wtChansAvgPlots();
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to show channels average plots');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in AverageWithStdErrorPlotsPushButton.
    function AverageWithStdErrorPlots_Callback(hObject, eventdata, handles)
        % hObject    handle to AverageWithStdErrorPlotsPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('AVERAGE WITH STDERR PLOTS');
        wtLog.contextOn('AveragePlotsWithStdError');
        updateApplicationStatus(hObject, handles, true);
        try
            wtAvgStdErrPlots();
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to show average with stderr plots');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ChannelsAverageWithStdErrorPlotsPushButton.
    function ChannelsAverageWithStdErrorPlots_Callback(hObject, eventdata, handles)
        % hObject    handle to ChannelsAverageWithStdErrorPlotsPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('CHANNELS AVERAGE WITH STDERR PLOTS');
        wtLog.contextOn('ChannelsAveragePlotsWithStdError');
        updateApplicationStatus(hObject, handles, true);
        try
            wtChansAvgStdErrPlots();
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to show channels average with stderr plots');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ScalpMap2DPlotsPushButton.
    function ScalpMap2DPlots_Callback(hObject, eventdata, handles)
        % hObject    handle to ScalpMap2DPlotsPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('2D SCALP MAP PLOTS');
        wtLog.contextOn('TwoDimensionalScalpMapPlots');
        updateApplicationStatus(hObject, handles, true);
        try
            wt2DScalpMapPlots();
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to show scalp map plots');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ScalpMap3DPlotsPushButton.
    function ScalpMap3DPlots_Callback(hObject, eventdata, handles)
        % hObject    handle to ScalpMap3DPlotsPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('3D SCALP MAP PLOTS');
        wtLog.contextOn('3DScalpMapPlots');
        updateApplicationStatus(hObject, handles, true);
        try
            wt3DScalpMapPlots();
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to show 3D scalp map plots');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ExportStatisticsPushButton.
    function ExportStatistics_Callback(hObject, eventdata, handles)
        % hObject    handle to ExportStatisticsPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('EXPORT STATISTICS');
        wtLog.contextOn('ExportStatistics');
        updateApplicationStatus(hObject, handles, true);
        try
            wtStatistics();
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to calculate export statistics');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ConfigurePushButton.
    function ConfigurePushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to ConfigurePushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        % --- Executes on button press in HelpPushButton.
        configureApp(hObject, handles);

    function Help_Callback(hObject, eventdata, handles)
        % hObject    handle to HelpPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        wtProject = WTProject().newContext('HELP');
        wtLog.contextOn('Help');
        updateApplicationStatus(hObject, handles, true);
        try
            web('https://github.com/cogdevtools/WTools/wiki/WTools-tutorial', '-browser')
        catch me
            wtLog.except(me);
            wtProject.notifyErr([], 'Failed to show help');
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes during object creation, after setting all properties.
    function LogLevel_CreateFcn(hObject, eventdata, handles)
        % hObject    handle to CurrentProjectEdit (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    empty - handles not created until after all CreateFcns called
        try
            level = WTAppConfig().DefaultStdLogLevel;
            set(hObject, 'Value', level);
        catch
        end
        guidata(hObject, handles);
    
    % --- Executes on selection in LogLevelPopupMenu.
    function LogLevel_Callback(hObject, eventdata, handles)
        % hObject    handle to LogLevelPopupMenu (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    empty - handles not created until after all CreateFcns called
        [success, handles] = lock(hObject, handles);
        if ~success
            set(hObject, 'Value', wtLog.StdLogLevel);
            guidata(hObject, handles);
            return
        end
        wtLog = WTLog();
        wtLog.StdLogLevel = hObject.Value;
        unlock(hObject, handles);
    
    % --- Utilities
    function quitApp(hObject)
        % hObject must be the handle to the figure... Do not use closereq() as it close the gcbf
        % which is not necessarily the WTools figure.
        delete(hObject);

    function restorePaths(hObject)
        userData = hObject.UserData;
        if isstruct(userData) && isfield(userData, 'PathsContext') && ~isempty(userData.PathsContext)
            path(userData.PathsContext);
        end
    
    function handles = updateProjectName(hObject, handles) 
        if isfield(handles,'CurrentProjectEdit')
            wtProject = WTProject();
            prjName = WTCodingUtils.ifThenElse(wtProject.IsOpen, wtProject.Config.getName(), '?');
            set(handles.CurrentProjectEdit, 'String', prjName);
            guidata(hObject, handles);
        end
    
    function handles = updateProjectDirectory(hObject, handles) 
        if isfield(handles,'ProjectDirectoryEdit')
            wtProject = WTProject();
            prjDir = '?';
            if wtProject.IsOpen
                prjDir = WTIOUtils.splitPath(wtProject.Config.getRootDir(), 1);
                nChars = length(prjDir);
                prjDir = WTCodingUtils.ifThenElse(nChars <= 40, prjDir, @()['...' prjDir(nChars-40:end)]);
            end
            set(handles.ProjectDirectoryEdit, 'String', prjDir);
            guidata(hObject, handles);
        end

    function handles = updateTotalSubjects(hObject, handles) 
        if isfield(handles,'SubjectsNumberEdit')
            wtProject = WTProject();
            nSubjs = length(wtProject.Config.SubjectsGrand.SubjectsList);
            nSubjsStr = WTCodingUtils.ifThenElse(wtProject.IsOpen, num2str(nSubjs), '?');
            set(handles.SubjectsNumberEdit, 'String', nSubjsStr);
            guidata(hObject, handles);
        end
    
    function handles = updateApplicationStatus(hObject, handles, busy) 
        if isfield(handles,'ApplicationStatusValueLabel')
            if busy
                set(handles.ApplicationStatusValueLabel, 'String', 'BUSY');
                set(handles.ApplicationStatusValueLabel, 'ForegroundColor', 'red');
            else
                set(handles.ApplicationStatusValueLabel, 'String', 'IDLE');
                set(handles.ApplicationStatusValueLabel, 'ForegroundColor', 'blue');
            end
            guidata(hObject, handles);
        end

    % lock() return the handles as it might modify them (by adding a new one). If reused in the caller
    % the handles to refer to are the ones returned by lock().
    function [success, handles] = lock(hObject, handles)
        if any(strcmp(fieldnames(handles),'wtoolsLocked')) && handles.wtoolsLocked
            WTDialogUtils.wrnDlg('Blocked', 'There''s an ongoing operation or a\ndialog is waiting for your response...');
            success = false;
        else
            handles.wtoolsLocked = true;
            success = true;
        end
        guidata(hObject, handles);
    
    % unlock() return the handles as it might modify them. If reused in the caller the handles to refer
    % to are the ones returned by lock().
    function handles = unlock(hObject, handles)
        handles.wtoolsLocked = false;
        guidata(hObject, handles);

    function closeAppAfter = configureApp(hObject, handles)
        closeAppAfter = false;
        [success, handles] = lock(hObject, handles);
        if ~success
            return
        end
        wtLog = WTLog();
        WTProject().newContext('');
        wtLog.contextOn('Configure WTools');
        updateApplicationStatus(hObject, handles, true);
        try
            WTAppConfigGUI.configureApplication(false, true, true);
        catch me
            wtLog.except(me);
        end
        updateApplicationStatus(hObject, handles, false);
        wtLog.reset();
        unlock(hObject, handles);
        closeAppAfter = true;

    function displayHelp()
        v = WTVersion();
        help = {
            '', ...
            ['WTools v' v.getVersionStr() ' - ' v.getReleaseDateStr()], ... 
            'Usage: wtools [ no-splash | configure | close | help ]', ...
            '', ...
            '       no-splash : do not display splash screen on start', ...  
            '                   (when the relative configuration option is enabled)', ...   
            '       configure : configure the application', ...
            '       close     : force close the application', ...
            '       help      : display this help', ...
            '', ...
        };
        fprintf(1, [char(join(help, '\n')) '\n']);

    function guiPresets() 
        guiFontSize = 10;
        textFontSize = 10;
        
        if ~verLessThan('matlab','8.4')
            comp = computer;

            if strcmpi(comp(1:3), 'MAC')
                screenSize = get(0, 'ScreenSize');
                retinaDisplay = screenSize(3) >= 1920;
                guiFontSize  = 12;
                textFontSize = 12;

                if retinaDisplay
                    guiFontSize = 14;
                    textFontSize = 14;
                end
            end
        end
        set(0, 'defaulttextfontsize', textFontSize);
        set(0, 'DefaultUicontrolFontSize', guiFontSize);
