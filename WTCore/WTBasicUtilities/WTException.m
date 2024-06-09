classdef WTException < MException 

    properties(Constant,Hidden,Access=public)
        WToolsId = 'WTOOLS'

        % Exception types
        BadType             = 'BadType'
        BadValue            = 'BadValue'
        MissingValue        = 'MissingValue'
        IncompatibleValues  = 'IncompatibleValues'
        IOArgsMismatch      = 'IOArgsMismatch'
        IOErr               = 'IOError'
        MissingArg          = 'MissingArg'
        BadArg              = 'BadArg'
        BadArgType          = 'BadArgType'
        BadArgValue         = 'BadArgValue'
        WorkspaceErr        = 'WorkspaceErr'
        EvalinErr           = 'EvalinErr'
        NotExistingPath     = 'NotExistingPath'
        EEGLabDependency    = 'EEGLabDependency'
        Unsupported         = 'Unsupported'
        GenericErr          = 'GenericErr'  
    end 

    methods(Access=public)
        function o = WTException(errId, msg, varargin)
            o@MException(WTException.errId(errId), msg, varargin{:});
        end

        % addSource not just a add a new source id, but return a new exception object
        function new = addSource(o, source)
            ids = split(o.identifier, ":");
            ids = {source ids{2:end}};
            identifier = char(join(ids, ':'));
            new = WTException(identifier, o.message);
            for cause = o.cause
                new.addCause(o.cause);
            end
            for correction = o.Correction
                new.addCorrection(correction);
            end
        end

        function o = log(o)
            WTLog().fromCaller().err('Exception(%s): %s', o.identifier, o.message);
        end
    end

    methods(Static,Access=private)
        function errId = errId(errSubId)
            errId = [WTException.WToolsId ':' errSubId];  
        end
    end

    methods(Static)
        function e = badType(msg, varargin)
            e = WTException(WTException.BadType, msg, varargin{:});
        end

        function e = badValue(msg, varargin)
            e = WTException(WTException.BadValue, msg, varargin{:});
        end

        function e = missingValue(msg, varargin)
            e = WTException(WTException.MissingValue, msg, varargin{:});
        end

        function e = incompatibleValues(msg, varargin)
            e = WTException(WTException.IncompatibleValues, msg, varargin{:});
        end

        function e = ioArgsMismatch(msg, varargin)
            e = WTException(WTException.IOArgsMismatch, msg, varargin{:});
        end

        function e = ioError(msg, varargin)
            e = WTException(WTException.IOErr, msg, varargin{:});
        end

        function e = missingArg(msg, varargin)
            e = WTException(WTException.MissingArg, msg, varargin{:});
        end

        function e = badArg(msg, varargin)
            e = WTException(WTException.BadArg, msg, varargin{:});
        end

        function e = badArgType(msg, varargin)
            e = WTException(WTException.BadArgType, msg, varargin{:});
        end

        function e = badArgValue(msg, varargin)
            e = WTException(WTException.BadArgValue, msg, varargin{:});
        end

        function e = workspaceErr(msg, varargin)
            e = WTException(WTException.WorkspaceErr, msg, varargin{:});
        end

        function e = evalinErr(msg, varargin)
            e = WTException(WTException.EvalinErr, msg, varargin{:});
        end

        function e = notExistingPath(msg, varargin)
            e = WTException(WTException.NotExistingPath, msg, varargin{:});
        end

        function e = eeglabDependency(msg, varargin)
            e = WTException(WTException.EEGLabDependency, msg, varargin{:});
        end

        function e = unsupported(msg, varargin)
            e = WTException(WTException.Unsupported, msg, varargin{:});
        end

        function e = genericErr(msg, varargin)
            e = WTException(WTException.GenericErr, msg, varargin{:});
        end
    end
end