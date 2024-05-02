classdef WTSubjectsCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldSubjects = 'subjects'
        FldFiles = 'files'
    end

    properties
        SubjectsList cell {WTValidations.mustBeALinearCellArrayOfNonEmptyString(SubjectsList)}  = {}
        FilesList cell {WTValidations.mustBeALinearCellArrayOfNonEmptyString(FilesList)}  = {}
    end

    methods
        function o = WTSubjectsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'subj.m');
            o.default();
        end

        function default(o) 
            o.SubjectsList = {};
            o.FilesList = {};
        end

        function success = load(o) 
            [success, subjs, files] = o.read(o.FldSubjects, o.FldFiles);
            if ~success
                [success, subjs] = o.read(o.FldSubjects);
                if success 
                    WTLog().err(['The subjets parameters (%s) misses field ''%s'': '...
                        'add it manually...'], o.DataFileName, o.FldFiles); 
                    success = false;
                    return
                end
            end
            try
                o.SubjectsList = subjs;
                o.FilesList = files;
                o.validate(true);
            catch me
                WTLog().except(me);
                o.default()
                success = false;
            end 
        end

        function success = validate(o, throwExcpt)
            success = true;
            subjs = o.SubjectsList;
            files = o.FilesList;
            throwExcpt = nargin > 1 && throwExcpt;
            objFld = @(fld)[class(o) '.' fld];

            if length(subjs) ~= length(files)
                WTUtils.throwOrLog(WTException.incompatibleValues('Fields %s and %s have different length', ...
                    objFld(o.FldSubjects), objFld(o.FldFiles)), ~throwExcpt);
                success = false;
            end
            if any(cellfun(@isempty, regexp(subjs, '^\d+$')))
                WTUtils.throwOrLog(WTException.badValue('%s must be char arrays representing numbers', ...
                    objFld(o.FldSubjects)), ~throwExcpt);
                success = false;
            end
            if ~all(arrayfun(@(i)contains(files{i},subjs{i}), 1:length(files)))
                WTUtils.throwOrLog(WTException.badValue('Each %s[n] element must contain %s[n]', ...
                    objFld(o.FldFiles), objFld(o.FldSubjects)), ~throwExcpt);
                success = false;
            end
        end

        function success = persist(o)
            txt1 = WTFormatter.stringCellsField(o.FldSubjects, o.SubjectsList);
            txt2 = WTFormatter.stringCellsField(o.FldFiles, o.FilesList);
            success = ~any(cellfun(@isempty,{txt1 txt2})) && o.write(txt1,txt2);
        end
    end
end
