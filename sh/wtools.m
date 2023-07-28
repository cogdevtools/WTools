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

%CHECK WTools path is set correctly
complexwtPath=which('complexwt.m');
pathResult=strfind(complexwtPath,strcat(filesep,'sh',filesep,'complexwt.m'));

if isempty(pathResult)
    
    string=strcat(filesep,'WTools_2016',filesep,'sh',filesep);
    fprintf(2,'\nWTools path is not set correctly!!!\n');
    fprintf(2,'It should point to the folder %s.\n',string);
    fprintf(2,'Please fix it.\n');
    fprintf('\n');
    
    return
    
end

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @wtools_OpeningFcn, ...
                   'gui_OutputFcn',  @wtools_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
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
% varargin   command line arguments to wtools (see VARARGIN)

% Choose default command line output for wtools
handles.output = hObject;

% INACTIVATE the local icadefs.m in the sh folder on PCs
if ispc
    sla='\';
    wtoolspath = which('wtools.m');
    slashes = findstr(wtoolspath,sla);
    wtoolspath = strcat(wtoolspath(1:slashes(end)));
    if exist(strcat(wtoolspath,'icadefs.m'),'file') == 2
        currentFolder = pwd;
        cd (wtoolspath);
        movefile('icadefs.m', 'NotActive_icadefs.m');
        cd (currentFolder);
    end
end

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
varargout{1} = handles.output;



function ProjectEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ProjectEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ProjectEdit as text
%        str2double(get(hObject,'String')) returns contents of ProjectEdit as a double
%
%checks to see if input is empty. if so, default ProjectEdit to None
if exist('PROJECTPATH','var')
    set(handles.ProjectEdit_CreateFcn,'String',c);
else
    set(handles.ProjectEdit_CreateFcn,'String','None')
end
guidata(hObject, handles);


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


function SSnEdit_Callback(hObject, eventdata, handles)
% hObject    handle to SSnEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SSnEdit as text
%        str2double(get(hObject,'String')) returns contents of SSnEdit as a double
%
%checks to see if input is empty. if so, default ProjectEdit to None
if exist('PROJECTPATH','var')
    set(handles.SSnEdit_CreateFcn,'String',nn);
else
    set(handles.SSnEdit_CreateFcn,'String','None')
end
guidata(hObject, handles);


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
newproject();
if ispc
    sla='\';
else
    sla='/';
end
try
    PROJECTPATH=evalin('base','PROJECTPATH');
catch
end
if exist('PROJECTPATH','var')
    c = PROJECTPATH(max(findstr(PROJECTPATH,sla))+1:end);
    nn = '0';
    set(handles.ProjectEdit,'String',c);
    set(handles.SSnEdit,'String',nn);
    %assignin('base','PROJECTPATH',PROJECTPATH);
    clear global ans;
elseif exist('handles.ProjectEdit','var')
    %'Cancel' has been pressed on the ui
    c = 'None';
    nn = 'None';
    set(handles.ProjectEdit,'String',c);
    set(handles.SSnEdit,'String',nn);
else
    return
end
guidata(hObject, handles);

% --- Executes on button press in OpenPushButton.
function OpenPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to OpenPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
openproject();
if ispc
    sla='\';
else
    sla='/';
end
try
    PROJECTPATH=evalin('base','PROJECTPATH');
catch
end
if exist('PROJECTPATH','var')
    c = PROJECTPATH(max(findstr(PROJECTPATH,sla))+1:end);
    set(handles.ProjectEdit,'String',c);
    %assignin('base','PROJECTPATH',PROJECTPATH);
    PROJECTPATH=evalin('base','PROJECTPATH');
    addpath(strcat(PROJECTPATH,'/pop_cfg'));
    if exist('subjgrand.m', 'file')
        subjgrand;
        nn = num2str(length(subjects));
    else
        nn = '0';
    end
    set(handles.SSnEdit,'String',nn);
    clear global ans;
elseif exist('handles.ProjectEdit','var')
    %'Cancel' has been pressed on the ui
    c = 'None';
    nn = 'None';
    set(handles.ProjectEdit,'String',c);
    set(handles.SSnEdit,'String',nn);
else
    return
end
guidata(hObject, handles);

% --- Executes on button press in ImportEEGPushButton.
function ImportEEGPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to ImportEEGPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
import2eegl();
guidata(hObject, handles);

% --- Executes on button press in SSManagerPushButton.
function SSManagerPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to SSManagerPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
tf_cmor();
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

% --- Executes on button press in Chop_BasePushButton.
function Chop_BasePushButton_Callback(hObject, eventdata, handles)
% hObject    handle to Chop_BasePushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
baseline_chop();
guidata(hObject, handles);

% --- Executes on button press in DifferencePushButton.
function DifferencePushButton_Callback(hObject, eventdata, handles)
% hObject    handle to DifferencePushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
difference();
guidata(hObject, handles);

% --- Executes on button press in GrandPushButton.
function GrandPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to GrandPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
xavr();
guidata(hObject, handles);

% --- Executes on button press in ChavrPushButton.
function ChavrPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to ChavrPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
chavr();
guidata(hObject, handles);

% --- Executes on button press in XavrSEPushButton.
function XavrSEPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to XavrSEPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
xavrse();
guidata(hObject, handles);

% --- Executes on button press in ChavrSEPushButton.
function ChavrSEPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to ChavrSEPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
chavrse();
guidata(hObject, handles);

% --- Executes on button press in SmavrPushButton.
function SmavrPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to SmavrPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
smavr();
guidata(hObject, handles);

% --- Executes on button press in Smavr3dPushButton.
function Smavr3dPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to Smavr3dPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
smavr3d();
guidata(hObject, handles);

% --- Executes on button press in AvrretrievePushButton.
function AvrretrievePushButton_Callback(hObject, eventdata, handles)
% hObject    handle to AvrretrievePushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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


