classdef WTAppConfig < WTClass & matlab.mixin.Copyable

    properties(Constant)
        ClassUUID = 'c6848e73-fb3c-48c6-a542-695ac2225339'
    end

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

    properties (SetAccess=private, GetAccess=public)
        ConfigFile
    end

    properties(Access=public)
        ShowSplashScreen(1,1) logical
        DefaultStdLogLevel(1,1) uint8
        ProjectLogLevel(1,1) uint8
        ProjectLog(1,1) logical
        MuteStdLog(1,1) logical     % effective only when ProjectLog = true
        ColorizedLog(1,1) logical   % apply only to standard log
        PlotsColorMap char
    end 

    methods(Static, Access=private)
        function [level, valid] = validLogLevel(level, levelType, throwExcpt)
            valid = false;
            if ischar(level) 
                code = WTLog.logLevelCode(level);
                valid = ~isempty(code);
                if ~valid
                    excp = WTException.badValue('Not a valid %s log level: ''%s''', levelType, level);
                else
                    level = code;
                end
            elseif WTValidations.isInt(level) 
                valid = ~isempty(WTLog.logLevelStr(level));
                if ~valid
                    excp = WTException.badValue('Not a valid %s log level: ''%d''', levelType, level);
                end
            else 
                excp = WTException.badValue('Not a valid %s log level type: ''%s''', levelType, class(level));
            end
            if ~valid
                WTCodingUtils.throwOrLog(excp, ~throwExcpt);
            end
        end

        function [colorMap, valid] = validColorMap(colorMap, throwExcpt)
            % colormap needs a figure or it will open one
            hFigure = figure('Visible', 'off');
            oldColorMap = colormap();
            try
                colormap(colorMap);
                valid = true;   
            catch
                valid = false;      
            end
            colormap(oldColorMap);
            delete(hFigure);
            if ~valid
                excp = WTException.badValue('Not a valid colormap: ''%s''', colorMap);
                WTCodingUtils.throwOrLog(excp, ~throwExcpt);
            end
        end
    end

    methods
        function o = WTAppConfig(singleton)
            singleton = nargin < 1 || singleton;
            o = o@WTClass(singleton, true);
            if ~o.InstanceInitialised
                o.ConfigFile = fullfile(WTLayout.getAppConfigDir(), o.ConfigFileName);
                o.default();
                o.load();
            end
        end

        function copyFrom(o, oo)
            WTValidations.mustBeA(oo, ?WTAppConfig);
            o.ShowSplashScreen = oo.ShowSplashScreen;
            o.DefaultStdLogLevel = oo.DefaultStdLogLevel;
            o.ProjectLogLevel = oo.ProjectLogLevel;
            o.MuteStdLog = oo.MuteStdLog;
            o.ProjectLog = oo.ProjectLog;
            o.ColorizedLog = oo.ColorizedLog;
            o.PlotsColorMap = oo.PlotsColorMap;
        end 

        function copyTo(o, oo)
            WTValidations.mustBeA(oo, ?WTAppConfig); 
            oo.copyFrom(o)
        end

        function same = equalTo(o, oo)
            WTValidations.mustBeA(oo, ?WTAppConfig); 
            same = o.ShowSplashScreen == oo.ShowSplashScreen && ...
                o.DefaultStdLogLevel == oo.DefaultStdLogLevel && ...
                o.ProjectLogLevel == oo.ProjectLogLevel && ...
                o.MuteStdLog == oo.MuteStdLog && ...
                o.ProjectLog == oo.ProjectLog && ...
                o.ColorizedLog == oo.ColorizedLog && ...
                strcmp(o.PlotsColorMap, oo.PlotsColorMap);
        end

        function o = default(o)
            o.ShowSplashScreen = false;
            o.DefaultStdLogLevel = WTLog.LevelInf;
            o.ProjectLogLevel = WTLog.LevelInf;
            o.ProjectLog = false;
            o.MuteStdLog = false;
            o.ColorizedLog = false;
            o.PlotsColorMap = 'parula';
        end
        
        function set.ProjectLogLevel(o, level)
            o.ProjectLogLevel = WTAppConfig.validLogLevel(level, 'project', true);
        end

        function set.DefaultStdLogLevel(o, level)
            o.DefaultStdLogLevel = WTAppConfig.validLogLevel(level, 'standard', true);
        end

        function set.PlotsColorMap(o, colorMap)
            o.PlotsColorMap = WTAppConfig.validColorMap(strip(colorMap), true);
        end

        function [o, success] = load(o, throwExcpt)
            throwExcpt = nargin > 1 && throwExcpt;
            success = true;
            try
                jsonText = fileread(o.ConfigFile, 'Encoding', 'UTF-8');
                data = jsondecode(jsonText);
                c = copy(o);

                if isfield(data, o.FldShowSplashScreen)
                    c.ShowSplashScreen = data.(o.FldShowSplashScreen);
                end
                if isfield(data, o.FldDefaultStdLogLevel)
                    logLevelStr = char(data.(o.FldDefaultStdLogLevel));
                    c.DefaultStdLogLevel = WTAppConfig.validLogLevel(logLevelStr, 'standard', true);
                end
                if isfield(data, o.FldProjectLogLevel)
                    logLevelStr = char(data.(o.FldProjectLogLevel));
                    c.ProjectLogLevel = WTAppConfig.validLogLevel(logLevelStr, 'project', true);
                end
                if isfield(data, o.FldMuteStdLog)
                    c.MuteStdLog = data.(o.FldMuteStdLog);
                end
                if isfield(data, o.FldProjectLog)
                    c.ProjectLog = data.(o.FldProjectLog);
                end
                if isfield(data, o.FldColorizedLog)
                    c.ColorizedLog = data.(o.FldColorizedLog);
                end
                if isfield(data, o.FldPlotsColorMap)
                    colorMap = data.(o.FldPlotsColorMap);
                    c.PlotsColorMap = WTAppConfig.validColorMap(colorMap, true);
                end
            catch me
                success = false;
                WTCodingUtils.throwOrLog(me, ~throwExcpt);
            end
            if success
                o.copyFrom(c);
            end
        end
 
        function success = persist(o)
            success = false;
            try
                data = struct(); 
                data.(o.FldShowSplashScreen) = o.ShowSplashScreen;
                data.(o.FldPlotsColorMap) = o.PlotsColorMap;
                data.(o.FldDefaultStdLogLevel) = WTLog.logLevelStr(o.DefaultStdLogLevel);
                data.(o.FldProjectLogLevel) = WTLog.logLevelStr(o.ProjectLogLevel);
                data.(o.FldMuteStdLog) = o.MuteStdLog;
                data.(o.FldProjectLog) = o.ProjectLog;
                data.(o.FldColorizedLog) = o.ColorizedLog;
                jsonText = jsonencode(data, 'PrettyPrint', true);
                writelines(jsonText, o.ConfigFile, 'Encoding', 'UTF-8');
                success = true;
            catch me
                WTLog().except(me);
            end
        end
    end
end
