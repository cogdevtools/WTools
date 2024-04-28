classdef WTAppConfigGUI

    methods(Static)
        function wtAppConfig = configureApplication(updateCurrent, persist, warnReload)
            updateCurrent = nargin > 0 && updateCurrent;
            persist = nargin > 1 && persist;
            warnReload =  nargin > 2 && warnReload;
            wtLog = WTLog();
            wtAppConfig = [];

            if updateCurrent
                wtAppConfigCrnt = WTAppConfig();
            else
                [wtAppConfigCrnt, success] = WTAppConfig(false).load(false);
                if ~success
                    WTUtils.errDlg('Application configuration', 'Failed load the application configuration!');
                    return
                end
            end

            wtAppConfig = copy(wtAppConfigCrnt);
            
            cbPrjLog = [ ...
                'status = ''off'';' ...
                'if get(findobj(gcbf, ''tag'', ''kPrjLog''), ''value''),' ... 
                '  status = ''on'';' ...
                'end;' ...
                'set(findobj(gcbf, ''-regexp'', ''tag'', ''prjLog.*''), ''enable'', status);' ];
            cbMuteStdLog = [ ...
                'status = ''on'';' ...
                'if get(findobj(gcbf, ''tag'', ''kStdLogMute''), ''value''),' ... 
                '  status = ''off'';' ...
                'end;' ...
                'set(findobj(gcbf, ''-regexp'', ''tag'', ''stdLog.*''), ''enable'', status);' ];

            logLvlStrs = WTLog.LevelStrs;   
            prjLogLvl = wtAppConfig.ProjectLogLevel;
            stdLogLvl = wtAppConfig.DefaultStdLogLevel;

            answer = { ...
                wtAppConfig.ShowSplashScreen ...
                wtAppConfig.PlotsColorMap ...
                wtAppConfig.ProjectLog ...
                prjLogLvl ...
                wtAppConfig.MuteStdLog ...
                wtAppConfig.ColorizedLog ...
                stdLogLvl ...
            };

            function parameters = setParameters()
                enablePrjLogOpt = WTUtils.ifThenElse(wtAppConfig.ProjectLog, 'on', 'off');
                enableStdLogOpt = WTUtils.ifThenElse(wtAppConfig.MuteStdLog, 'off', 'on');
                
                parameters = { ...
                    { 'style' 'text'      'string' 'Show splash screen' } ...
                    { 'style' 'checkbox'  'value'  answer{1,1} } ...
                    { 'style' 'text'      'string' 'Plots color map' } ...
                    { 'style' 'edit'      'string' answer{1,2} }...
                    { 'style' 'text'      'string' 'Project log' } ...
                    { 'style' 'checkbox'  'value'  answer{1,3} 'tag' 'kPrjLog' 'callback' cbPrjLog } ...
                    { 'style' 'text'      'string' 'Project log level' 'tag' 'prjLogLvlTxt' 'enable' enablePrjLogOpt } ...
                    { 'style' 'popupmenu' 'string' logLvlStrs 'value' answer{1,4} 'tag' 'prjLogLvl' 'enable' enablePrjLogOpt }...
                    { 'style' 'text'      'string' 'Mute standard log'  } ...
                    { 'style' 'checkbox'  'value'  answer{1,5} 'tag' 'kStdLogMute' 'callback' cbMuteStdLog } ...
                    { 'style' 'text'      'string' 'Colorised standard log' 'tag' 'stdLogColorTxt' } ...
                    { 'style' 'checkbox'  'value'  answer{1,6} 'tag' 'stdLogColor' 'enable' enableStdLogOpt } ...
                    { 'style' 'text'      'string' 'Default standard log level' 'tag' 'stdLogLvlTxt' 'enable' enableStdLogOpt } ...
                    { 'style' 'popupmenu' 'string' logLvlStrs 'value' answer{1,7} 'tag' 'stdLogLvl' 'enable' enableStdLogOpt } ...
                };
            end
            
            geometry = { [0.6 0.4] [0.6 0.4] [0.6 0.4] [0.6 0.4] [0.6 0.4] [0.6 0.4] [0.6 0.4] };
            success = false;
            anyChange = false;

            while ~success
                parameters = setParameters();
                answer = WTUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'WTools configuration');
                
                if isempty(answer)
                    wtAppConfig = [];
                    return 
                end

                try
                    wtAppConfig.ShowSplashScreen = answer{1,1};
                    wtAppConfig.PlotsColorMap = answer{1,2};
                    wtAppConfig.ProjectLog = answer{1,3};
                    wtAppConfig.ProjectLogLevel = answer{1,4};
                    wtAppConfig.MuteStdLog = answer{1,5};
                    wtAppConfig.ColorizedLog = answer{1,6};
                    wtAppConfig.DefaultStdLogLevel = answer{1,7};
                    anyChange = ~wtAppConfigCrnt.equalTo(wtAppConfig);
                    success = true;
                catch me
                    wtLog.except(me);
                end

                if ~success
                    WTUtils.wrnDlg('Review parameter', 'Invalid paramters: check the log for details');
                elseif wtAppConfig.MuteStdLog && ~WTUtils.eeglabYesNoDlg('Confirm parameter', ...
                    'Muting standard log might hide important information! Continue?')
                    success = false;
                    anyChange = false;
                end
            end

            if ~anyChange
                return
            end

            if updateCurrent
                wtAppConfig.copyTo(WTAppConfig());
            end

            if persist && ~wtAppConfig.persist()
                WTUtils.errDlg('Application configuration', 'Failed to save the application configuration!');
                wtAppConfig = [];
            elseif warnReload && WTSession().IsOpen
                WTUtils.wrnDlg('Application configuration', 'Quit and open again wtools to load the updated configuration');
            end
        end
    end
end