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

if nargin && ischar(varargin{1}) 
    if ~strcmp(varargin{1}, 'no-splash')
        gui_State.gui_Callback = str2func(varargin{1});
    elseif nargin > 1 && ischar(varargin{2})
        gui_State.gui_Callback = str2func(varargin{2});
    end
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

try 
    for i = 4:nargin
        switch varargin{i-3}
            case 'no-splash'
                showSplash = false;
                continue
            otherwise
                wtLog.warn('Unknown command line option: %s', num2str(varargin{i-3}));
        end
    end
    if showSplash && ~any(strcmp(fieldnames(handles),'wtoolsOpen'))      
        wtSplash()
    end
    if ~WTUtils.eeglabDep()
        forceClose = true;
    end
    wtChangeGUIColors(hObject, [0.1 0.8 0.4], [0 0.9 .1])
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
wtProject = WTProject();
wtLog = WTLog();
wtLog.ctxOn('NewProject');
try
    if wtNewProject()
        set(handles.ProjectEdit, 'String', wtProject.Config.getName());
        set(handles.SSnEdit, 'String', '0');
    end
catch me
    wtLog.mexcpt(me);
end
if ~wtProject.IsOpen
    set(handles.ProjectEdit, 'String', 'None');
    set(handles.SSnEdit,'String', 'None');
end
wtLog.reset();
guidata(hObject, handles);

% --- Executes on button press in OpenPushButton.
function OpenPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to OpenPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtProject = WTProject();
wtLog = WTLog();
wtLog.ctxOn('OpenProject');
try
    if wtOpenProject()
        set(handles.ProjectEdit, 'String', wtProject.Config.getName());
        subjsGrand = wtProject.Config.SubjectsGrand;
        if subjsGrand.exist() 
            subjsGrand.load(); 
        end
        set(handles.SSnEdit,'String', num2str(length(subjsGrand.SubjectsList)));
    end
catch me
    wtLog.mexcpt(me);
end
if ~wtProject.IsOpen
    set(handles.ProjectEdit, 'String', 'None');
    set(handles.SSnEdit,'String', 'None');
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
    wtImport();
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

% context: 'SubjectManager'
subjrebuild();
if exist('subjects','var')
    nn = num2str(length(subjects));
    set(handles.SSnEdit,'String',nn);
    clear global ans;
elseif exist('handles.SSnEdit','var')
    %'Cancel' has been pressed on the ui
    nn = 'None';
    set(handles.SSnEdit,'String',nn);
else
    return
end
guidata(hObject, handles);

% --- Executes on button press in WTPushButton.
function WTPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to WTPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wtLog = WTLog();
wtLog.ctxOn('Time/Freq analysis');
try
    wtPerformCWT();
    if exist('subjects','var')
        set(handles.SSnEdit, 'String', num2str(length(subjects)));
    else
        set(handles.SSnEdit, 'String', 'None');
    end
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
    difference();
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

% Context: SubjectsGrandAverage
grand();
if exist('subjects','var')
    nn = num2str(length(subjects));
    set(handles.SSnEdit,'String',nn);
    clear global ans;
elseif exist('handles.SSnEdit','var')
    %'Cancel' has been pressed on the ui
    nn = 'None';
    set(handles.SSnEdit,'String',nn);
else
    return
end
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

% Context: 'Statistics'
avrretrieve();
if exist('subjects','var')
    nn = num2str(length(subjects));
    set(handles.SSnEdit,'String',nn);
    clear global ans;
elseif exist('handles.SSnEdit','var')
    %'Cancel' has been pressed on the ui
    nn = 'None';
    set(handles.SSnEdit,'String',nn);
else
    return
end
guidata(hObject, handles);


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

function LogLevelPopupMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ProjectEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
level = WTLog().getLogLevel();
set(hObject, 'Value', level);
guidata(hObject, handles);


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
WTSession().open();
handles.output = hObject;
guidata(hObject, handles);    

% --- Executes during object deletion, before destroying properties.
function WToolsMain_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to WToolsMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
WTSession().close();
WTSession.clear();
