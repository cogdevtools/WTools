classdef WTAppConfig < handle

    properties (Constant,Hidden)
        ConfigFileName = 'wtools.json'

        FldShowSplashScreen = "ShowSplashScreen"
        FldDefaultStdLogLevel = 'DefaultStdLogLevel'
        FldProjectLogLevel = 'ProjectLogLevel'
        FldProjectLog = 'ProjectLog'
        FldMuteStdLog = 'MuteStdLog'
        FldColorizedLog = 'ColorizedLog'
        FldPlotsColorMap = 'PlotsColorMap'
    end

    properties(SetAccess=private,GetAccess=public)
        ShowSplashScreen(1,1) logical
        DefaultStdLogLevel(1,1) uint8
        ProjectLogLevel(1,1) uint8
        ProjectLog(1,1) logical
        MuteStdLog(1,1) logical     % effective only when ProjectLog = true
        ColorizedLog(1,1) logical   % apply only to standard log
        PlotsColorMap char
    end 

    methods
        function o = WTAppConfig()
            st = singleton();
            if isempty(st) || ~isvalid(st)
                o.default();
                o.load();
                singleton(o);
            else 
                o = st;
            end
         end

        function o = default(o)
            o.ShowSplashScreen = false;
            o.DefaultStdLogLevel = WTLog.LevelInf;
            o.ProjectLogLevel = WTLog.LevelInf;
            o.ProjectLog = false;
            o.MuteStdLog = false;
            o.ColorizedLog = false;
            o.PlotsColorMap = '';
        end
        
        function o = load(o)
            try
                jsonFile = fullfile(WTLayout.getResourcesDir, o.ConfigFileName);
                jsonText = fileread(jsonFile, 'Encoding', 'UTF-8');
                data = jsondecode(jsonText);
                
                splashScreen = o.ShowSplashScreen;
                defaultStdLogLevel = o.DefaultStdLogLevel;
                projectLogLevel = o.ProjectLogLevel;
                muteStdLog = o.MuteStdLog;
                projectLog = o.ProjectLog;
                colorizedLog = o.ColorizedLog;
                plotsColorMap = o.PlotsColorMap;

                if isfield(data, o.FldShowSplashScreen)
                    o.ShowSplashScreen = data.(o.FldShowSplashScreen);
                end
                if isfield(data, o.FldDefaultStdLogLevel)
                    defaultLogLevelStr = char(data.(o.FldDefaultStdLogLevel));
                    o.DefaultStdLogLevel = WTLog.logLevelCode(defaultLogLevelStr);
                    if isempty(o.DefaultStdLogLevel) 
                        WTLog.err('Not a valid std log level: ''%s''', defaultLogLevelStr);
                        o.DefaultStdLogLevel = defaultStdLogLevel;  
                    end
                end
                if isfield(data, o.FldProjectLogLevel)
                    defaultLogLevelStr = char(data.(o.FldProjectLogLevel));
                    o.ProjectLogLevel = WTLog.logLevelCode(defaultLogLevelStr);
                    if isempty(o.ProjectLogLevel) 
                        WTLog.err('Not a valid project log level: ''%s''', defaultLogLevelStr);
                        o.ProjectLogLevel = projectLogLevel;  
                    end
                end
                if isfield(data, o.FldMuteStdLog)
                    o.MuteStdLog = data.(o.FldMuteStdLog);
                end
                if isfield(data, o.FldProjectLog)
                    o.ProjectLog = data.(o.FldProjectLog);
                end
                if isfield(data, o.FldColorizedLog)
                    o.ColorizedLog = data.(o.FldColorizedLog);
                end
                if isfield(data, o.FldPlotsColorMap)
                    colorMapName = data.(o.FldPlotsColorMap);
                    hFigure = figure(); % colormap needs a figure or it will open one
                    hFigure.Visible = 'off';
                    oldColorMap = colormap();
                    try
                        colormap(colorMapName);
                        o.PlotsColorMap = colorMapName;
                    catch
                        WTLog.err('Not a valid colormap: ''%s''', colorMap);
                    end
                    colormap(oldColorMap);
                    delete(hFigure);
                end
            catch me
                o.ShowSplashScreen = splashScreen;
                o.DefaultStdLogLevel = defaultStdLogLevel;
                o.ProjectLogLevel = projectLogLevel;
                o.MuteStdLog = muteStdLog;
                o.ProjectLog = projectLog;
                o.ColorizedLog = colorizedLog;
                o.PlotsColorMap = plotsColorMap;
                WTLog().except(me);
            end
        end
 
        function o = persist(o)
            try
                jsonFile = fullfile(WTLayout.getResourcesDir, o.ConfigFileName);
                data = struct(); 
                data.(o.FldShowSplashScreen) = o.ShowSplashScreen;
                data.(o.FldDefaultStdLogLevel) = WTLog.logLevelStr(o.DefaultStdLogLevel);
                data.(o.FldProjectLogLevel) = WTLog.logLevelStr(o.ProjectLogLevel);
                data.(o.FldMuteStdLog) = o.MuteStdLog;
                data.(o.FldProjectLog) = o.ProjectLog;
                data.(o.FldColorizedLog) = o.ColorizedLog;
                jsonText = jsonencode(data);
                writelines(jsonText, jsonFile, 'Encoding', 'UTF-8');
            catch me
                WTLog().except(me);
            end
        end
    end

    methods(Static)
        function clear()
            singleton();
            munlock('singleton');
        end
    end
end

function o = singleton(o)
    mlock;
    persistent uniqueInstance

    if nargin > 0 
        uniqueInstance = o;
    elseif nargout > 0 
        o = uniqueInstance;
    elseif ~isempty(uniqueInstance)
        delete(uniqueInstance)
    end
end