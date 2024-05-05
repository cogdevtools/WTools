classdef WTProject < WTClass

    properties(Constant)
        ClassUUID = '3569ead7-4a95-4393-8598-2428490215e1'
    end

    properties (SetAccess=private, GetAccess=public)
        IsOpen logical
        Config WTConfig
        Context cell
    end

    properties
        Interactive logical
    end

    methods (Access=private)
        function msg = getContextMsg(o, fmt, varargin)
            msg = WTUtils.ifThenElse(~isempty(o.Context), @()char(join(o.Context,':')), '');
            if isempty(fmt)
                return
            end
            tail = sprintf(fmt, varargin{:});
            msg = WTUtils.ifThenElse(isempty(msg), tail, @()[msg ': ' tail]);
        end

        function msg = getAlternativeMsg(o, msg, fmt, varargin) 
            msg = WTUtils.ifThenElse(~isempty(msg), msg, sprintf(fmt, varargin{:}));
            if isempty(msg)
                return
            end
            msg(1) = WTUtils.ifThenElse(isempty(o.Context), upper(msg(1)), lower(msg(1)));
        end
    end

    methods
        function o = WTProject(singleton)
            singleton = nargin < 1 || singleton;
            o = o@WTClass(singleton, true);
            if ~o.InstanceInitialised
                o.IsOpen = false;
                o.Interactive = true;
                o.Context = {};
                o.Config = WTConfig();
            end
        end
        
        function o = newContext(o, ctx)
            o.Context = { ctx };
        end

        function o = addContext(o, ctx)
            o.Context = [ o.Context ctx ];
        end

        function o = delContext(o)
            if ~isempty( o.Context)
                o.Context(1:end) = [];
            end
        end

        function open = checkIsOpen(o)
            open = o.IsOpen;
            if ~open
                o.notifyWrn([], 'A project must be opened/created to proceed');
            end
        end

        function done = checkImportDone(o)
            done = o.checkIsOpen();
            if ~done 
                return
            end

            subjectsPrms = o.Config.Subjects;
            conditionsPrms = o.Config.Conditions;
            channelsPrms = o.Config.Channels;

            done = subjectsPrms.exist() && ...
                conditionsPrms.exist() && ...
                channelsPrms.exist() && ...
                ~isempty(subjectsPrms.FilesList) && ... 
                ~isempty(conditionsPrms.ConditionsList);
            if ~done
                o.notifyWrn([], 'Data import must be performed before to proceed');
            end
        end

        function done = checkWaveletAnalysisDone(o)
            done = o.checkImportDone();
            if ~done 
                return
            end

            waveletPrms = o.Config.WaveletTransform;
            condsGrandPrms = o.Config.ConditionsGrand;
            subjsGrandPrms = o.Config.SubjectsGrand;

            done = waveletPrms.exist() && ...
                subjsGrandPrms.exist() && ...
                condsGrandPrms.exist() && ...
                ~isempty(subjsGrandPrms.SubjectsList) && ...
                ~isempty(condsGrandPrms.ConditionsList);
            if ~done
                o.notifyWrn([], 'Wavelet analysis must be performed before to proceed');
            end
        end

        function done = checkChopAndBaselineCorrectionDone(o)
            done = o.checkWaveletAnalysisDone();
            if ~done 
                return
            end  
                      
            baselineChopPrms = o.Config.BaselineChop;
            done = baselineChopPrms.exist(); 

            if ~done
                o.notifyWrn([], 'Chop and baseline correction must be performed before to proceed');
            end
        end

        function notify(o, title, fmt, varargin)
            if o.Interactive 
                WTUtils.eeglabMsgDlg(title, fmt, varargin{:});
            end
        end

        function notifyErr(o, title, fmt, varargin)
            wtLog = WTLog(); 
            if wtLog.LogLevel >= WTLog.LevelErr 
                WTLog().err(fmt, varargin{:});
                title = o.getContextMsg(o.getAlternativeMsg(title, 'error'));
                o.notify(title, fmt, varargin{:});
            end
        end

        function notifyWrn(o, title, fmt, varargin)
            wtLog = WTLog(); 
            if wtLog.LogLevel >= WTLog.LevelWrn 
                WTLog().warn(fmt, varargin{:});
                title = o.getContextMsg(o.getAlternativeMsg(title, 'warning'));
                o.notify(title, fmt, varargin{:});
            end
        end

        function notifyInf(o, title, fmt, varargin)
            wtLog = WTLog(); 
            if wtLog.LogLevel >= WTLog.LevelInf 
                title = o.getContextMsg(o.getAlternativeMsg(title, 'info'));
                o.notify(title, fmt, varargin{:});
            end
        end

        function success = checkIsValidName(o, name, warn)
            success = ~isempty(name) && length(split(name)) == 1 && length(split(name,'\')) == 1 && length(split(name,'/')) == 1;
            if ~success && nargin > 1 && warn
                o.notifyErr([], ['Empty or invalid project name!\n'...
                    'Make sure to remove blanks and / \\ chars from the name.']);
            end
        end

        function success = open(o, rootDir)
            success = o.Config.open(rootDir); 
            o.IsOpen = success;
            name = WTUtils.getPathTail(rootDir);  
            parentDir = WTUtils.getPathPrefix(rootDir);
            if success 
                o.notifyInf([], 'Project ''%s''in dir ''%s'' opened successfully', name, parentDir);
            else
                o.notifyErr([], 'Failed to open project ''%s'' in dir ''%s''', name, parentDir);
            end
        end 

        function success = new(o, rootDir)
            success = o.Config.new(rootDir); 
            o.IsOpen = success;  
            name = WTUtils.getPathTail(rootDir);  
            parentDir = WTUtils.getPathPrefix(rootDir);
            if success 
                o.notifyInf([], 'New project ''%s'' created successfully in dir ''%s''', name, parentDir); 
            else
                o.notifyErr([], 'Failed to create project ''%s'' in dir ''%s''', name, parentDir);
            end
        end 
    end
end
