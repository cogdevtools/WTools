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
            case 'no-splash'
            case 'bg-color'
                i = i+1;
            case 'fg-color'
                i = i+1;
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
wtLog = WTLog();
forceClose = false;
showSplash = true;
bgColor = [];
fgColor = [];

try
    i = 1;
    while i <= nargin-3
        if ~ischar(varargin{i})
            wtLog.warn('Unexpected command line option: %s', num2str(varargin{i}));
            i = i+1;
            continue;
        end
        switch varargin{i}
            case 'no-splash'
                showSplash = false;
            case 'bg-color'
                if i < nargin
                    i = i+1;
                    bgColor = varargin{i};
                end
            case 'fg-color'
                if i < nargin
                    i = i+1;
                    fgColor = varargin{i};
                end
        end
        i = i+1;
    end

    if ~WTUtils.eeglabDep()
        forceClose = true;
    elseif ~any(strcmp(fieldnames(handles),'wtoolsOpen'))
        if showSplash       
            wtSplash()
        end
        if ~isempty(bgColor) && ~isempty(fgColor)
            wtChangeGUIColors(hObject, bgColor, fgColor)
        end
    end
catch me
    WTLog().mexcpt(me);
    forceClose = true;
end

if forceClose 
    closereq()
    return
end

handles.wtoolsOpen = 1;
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
if ~isempty(handles) 
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
wtLog = WTLog();
wtLog.ctxOn('NewProject');
try
    wtNewProject();
    updateProjectName(handles);
    updateTotalSubjects(handles);
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in OpenPushButton.
function OpenPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to OpenPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('OpenProject');
try
    wtOpenProject();
    updateProjectName(handles);
    updateTotalSubjects(handles);
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in ImportEEGPushButton.
function ImportEEGPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to ImportEEGPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('Import');
try
    wtConvert();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();  
guidata(hObject, handles);

% --- Executes on button press in SSManagerPushButton.
function SSManagerPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to SSManagerPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('SubjectManager');
try
    wtSubjectsRebuild();
    updateTotalSubjects(handles);
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in WTPushButton.
function WTPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to WTPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('TimeFreqAnalysis');
try
    wtPerformCWT();
    updateTotalSubjects(handles);
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in Chop_BasePushButton.
function Chop_BasePushButton_Callback(hObject, eventdata, handles)
% hObject    handle to Chop_BasePushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('BaselineChop');
try
    wtBaselineChop();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in DifferencePushButton.
function DifferencePushButton_Callback(hObject, eventdata, handles)
% hObject    handle to DifferencePushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('ConditionsDifference');
try
    wtDifference();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in GrandPushButton.
function GrandPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to GrandPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('SubjectsGrandAverage');
try
    wtGrandAverage();
    updateTotalSubjects(handles)
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in XavrPushButton.
function XavrPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to XavrPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('GlobalPlots');
try
    xavr();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in ChavrPushButton.
function ChavrPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to ChavrPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('ChannelsPlots');
try
    chavr();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in XavrSEPushButton.
function XavrSEPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to XavrSEPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('GlobalPlotsWithStdError');
try
    xavrse();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in ChavrSEPushButton.
function ChavrSEPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to ChavrSEPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('ChannelsPlotsWithStdError');
try
    chavrse();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in SmavrPushButton.
function SmavrPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to SmavrPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('ScalpMapPlots');
try
    smavr();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in Smavr3dPushButton.
function Smavr3dPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to Smavr3dPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('3DScalpMapPlots');
try
    smavr3d();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in AvrretrievePushButton.
function AvrretrievePushButton_Callback(hObject, eventdata, handles)
% hObject    handle to AvrretrievePushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('Statistics');
try
    avrretrieve();
    updateTotalSubjects();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in HelpPushButton.
function HelpPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to HelpPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('Help');
try
    web('https://github.com/cogdevtools/WTools/wiki/WTools-tutorial', '-browser')
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function LogLevelPopupMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ProjectEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
level = WTLog().getLogLevel();
set(hObject, 'Value', level);
guidata(hObject, handles);

% --- Executes on selection in LogLevelPopupMenu.
function LogLevelPopupMenu_Callback(hObject, eventdata, handles)
% hObject    handle to LogLevelPopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
WTLog().setLogLevel(hObject.Value);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function WToolsMain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WToolsMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
wtLog = WTLog();
wtLog.ctxOn('Init');
try
    WTSession().open();
catch me
    wtLog.mexcpt(me);
end
wtLog.reset();
guidata(hObject, handles); 

% --- Executes during object deletion, before destroying properties.
function WToolsMain_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to WToolsMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
try
    wtLog.reset();
    WTSession().close();
    WTSession.clear();
end
guidata(hObject, handles);


% --- Utilities
function updateProjectName(handles) 
if isfield(handles,'ProjectEdit')
    wtProject = WTProject();
    prjName = WTUtils.ifThenElseSet(wtProject.IsOpen, wtProject.Config.getName(), '?');
    set(handles.ProjectEdit, 'String', prjName);
end

function updateTotalSubjects(handles) 
if isfield(handles,'SSnEdit')
    wtProject = WTProject();
    nSubjs = length(wtProject.Config.SubjectsGrand.SubjectsList);
    nSubjsStr = WTUtils.ifThenElseSet(wtProject.IsOpen, num2str(nSubjs), '?');
    set(handles.SSnEdit, 'String', nSubjsStr);
end

