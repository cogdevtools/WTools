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
    % Last Modified by GUIDE v2.5 03-Jul-2013 13:43:07
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
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
                if ~WTUtils.eeglabDep()
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
    function ProjectEdit_CreateFcn(hObject, eventdata, handles)
        % hObject    handle to ProjectEdit (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    empty - handles not created until after all CreateFcns called
        
        % Hint: edit controls usually have a white background on Windows.
        %       See ISPC and COMPUTER.
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end
    
    
    % --- Executes during object creation, after setting all properties.
    function SSnEdit_CreateFcn(hObject, eventdata, handles)
        % hObject    handle to SSnEdit (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    empty - handles not created until after all CreateFcns called
        
        % Hint: edit controls usually have a white background on Windows.
        %       See ISPC and COMPUTER.
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end
    
    % --- Executes on button press in NewPushButton.
    function NewPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to NewPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('NewProject');
        try
            wtNewProject();
            updateProjectName(hObject, handles);
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to create a new project');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in OpenPushButton.
    function OpenPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to OpenPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('OpenProject');
        try
            wtOpenProject();
            updateProjectName(hObject, handles);
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to open a project');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ImportEEGPushButton.
    function ImportEEGPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to ImportEEGPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('Import');
        try
            wtConvert();
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to import data');
        end
        wtLog.reset();  
        unlock(hObject, handles);
    
    % --- Executes on button press in SSManagerPushButton.
    function SSManagerPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to SSManagerPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('SubjectManager');
        try
            wtRebuildSubjects();
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to rebuild subjects');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in WTPushButton.
    function WTPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to WTPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('TimeFreqAnalysis');
        try
            wtPerformCWT();
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to perform time/frequency analysis');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in Chop_BasePushButton.
    function Chop_BasePushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to Chop_BasePushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('BaselineChop');
        try
            wtBaselineChop();
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to perform calculate baseline or perform chopping');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in DifferencePushButton.
    function DifferencePushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to DifferencePushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('ConditionsDifference');
        try
            wtDifference();
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to perform conditions difference');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in GrandPushButton.
    function GrandPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to GrandPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('SubjectsGrandAverage');
        try
            wtGrandAverage();
            updateTotalSubjects(hObject, handles)
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to perform grand average');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in XavrPushButton.
    function XavrPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to XavrPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('AveragePlots');
        try
            wtAvgPlots();
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to show average plots');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ChavrPushButton.
    function ChavrPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to ChavrPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('ChannelsPlots');
        try
            wtChansAvgPlots();
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to show channels average plots');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in XavrSEPushButton.
    function XavrSEPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to XavrSEPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('GlobalPlotsWithStdError');
        try
            wtAvgStdErrPlots();
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to show average with stderr plots');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in ChavrSEPushButton.
    function ChavrSEPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to ChavrSEPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('ChannelsPlotsWithStdError');
        try
            wtChansAvgStdErrPlots();
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to show channels average with stderr plots');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in SmavrPushButton.
    function SmavrPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to SmavrPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('ScalpMapPlots');
        try
            wtScalpMapPlots();
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to show scalp map plots');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in Smavr3dPushButton.
    function Smavr3dPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to Smavr3dPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('3DScalpMapPlots');
        try
            smavr3d();
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to show 3D scalp map plots');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in AvrretrievePushButton.
    function AvrretrievePushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to AvrretrievePushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('Statistics');
        try
            avrretrieve();
            updateTotalSubjects(hObject, handles);
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to calculate statistics');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes on button press in HelpPushButton.
    function HelpPushButton_Callback(hObject, eventdata, handles)
        % hObject    handle to HelpPushButton (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        wtLog = WTLog();
        wtLog.contextOn('Help');
        try
            web('https://github.com/cogdevtools/WTools/wiki/WTools-tutorial', '-browser')
        catch me
            wtLog.except(me);
            WTProject().notifyErr([], 'Failed to show help');
        end
        wtLog.reset();
        unlock(hObject, handles);
    
    % --- Executes during object creation, after setting all properties.
    function LogLevelPopupMenu_CreateFcn(hObject, eventdata, handles)
        % hObject    handle to ProjectEdit (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    empty - handles not created until after all CreateFcns called
        try
            level = WTAppConfig().DefaultStdLogLevel;
            set(hObject, 'Value', level);
        catch
        end
        guidata(hObject, handles);
    
    % --- Executes on selection in LogLevelPopupMenu.
    function LogLevelPopupMenu_Callback(hObject, eventdata, handles)
        % hObject    handle to LogLevelPopupMenu (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    empty - handles not created until after all CreateFcns called
        wtLog = WTLog();
        if ~lock(hObject, handles)
            set(hObject, 'Value', wtLog.StdLogLevel);
            guidata(hObject, handles);
            return
        end
        wtLog.StdLogLevel = hObject.Value;
        unlock(hObject, handles);
    
    % --- Executes during object creation, after setting all properties.
    function WToolsMain_CreateFcn(hObject, eventdata, handles)
        % hObject    handle to WToolsMain (see GCBO)
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
    function WToolsMain_DeleteFcn(hObject, eventdata, handles)
        % hObject    handle to WToolsMain (see GCBO)
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
    
    % --- Executes when user attempts to close WToolsMain.
    function WToolsMain_CloseRequestFcn(hObject, eventdata, handles)
        % hObject    handle to WToolsMain (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        if ~lock(hObject, handles)
            return
        end
        option = WTUtils.askDlg('Confirm', 'Sure to quit?', {}, {'Continue', 'Quit'}, 'Continue');
        unlock(hObject, handles);
        if strcmp(option, 'Continue')
            return
        end
        quitApp(hObject);
    
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
    
    function updateProjectName(hObject, handles) 
        if isfield(handles,'ProjectEdit')
            wtProject = WTProject();
            prjName = WTUtils.ifThenElse(wtProject.IsOpen, wtProject.Config.getName(), '?');
            set(handles.ProjectEdit, 'String', prjName);
            guidata(hObject, handles);
        end
    
    function updateTotalSubjects(hObject, handles) 
        if isfield(handles,'SSnEdit')
            wtProject = WTProject();
            nSubjs = length(wtProject.Config.SubjectsGrand.SubjectsList);
            nSubjsStr = WTUtils.ifThenElse(wtProject.IsOpen, num2str(nSubjs), '?');
            set(handles.SSnEdit, 'String', nSubjsStr);
            guidata(hObject, handles);
        end
    
    function success = lock(hObject, handles)
        if any(strcmp(fieldnames(handles),'wtoolsLocked')) && handles.wtoolsLocked
            WTUtils.wrnDlg('Blocked', 'There''s an ongoing operation or a\ndialog is waiting for your response...');
            success = false;
        else
            handles.wtoolsLocked = true;
            success = true;
        end
        guidata(hObject, handles);
    
    function handles = unlock(hObject, handles)
        handles.wtoolsLocked = false;
        guidata(hObject, handles);

    function closeAppAfter = configureApp(hObject, handles)
        closeAppAfter = false;
        if ~lock(hObject, handles)
            return
        end
        WTAppConfigGUI.configureApplication(false, true, true);
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
            '                   (when the relative configuration option is on)', ...   
            '       configure : configure the application', ...
            '       close     : force close the application', ...
            '       help      : display this help', ...
            '', ...
        };
        fprintf(1, [char(join(help, '\n')) '\n']);

    