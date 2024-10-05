% Copyright (C) 2024 Eugenio Parise, Luca Filippin
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.

classdef WTSubjectsCfg < WTConfigStorage & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant,Access=private)
        FldSubjects = 'subjects'
        FldImportedSubjects= 'imported'
        FldFiles = 'files'
    end

    properties
        SubjectsList cell {WTValidations.mustBeLinearCellArrayOfNonEmptyChar(SubjectsList)}  = {}
        ImportedSubjectsList cell {WTValidations.mustBeLinearCellArrayOfNonEmptyChar(ImportedSubjectsList)}  = {}
        FilesList cell {WTValidations.mustBeLinearCellArrayOfNonEmptyChar(FilesList)}  = {}
    end

    methods
        function o = WTSubjectsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'subj.m');
            o.default();
        end

        function default(o) 
            o.SubjectsList = {};
            o.ImportedSubjectsList = {};
            o.FilesList = {};
        end

        function set.SubjectsList(o, value)
            o.SubjectsList = sort(unique(value));
        end

        function set.FilesList(o, value)
            o.FilesList = sort(unique(value));
        end

        function success = load(o) 
            [success, subjs, imported, files] = o.read(o.FldSubjects, o.FldImportedSubjects, o.FldFiles);
            if ~success
                [success, subjs] = o.read(o.FldSubjects);
                if success 
                    WTLog().err(['The subjets parameters file (%s) misses any/all of these fields ''%s'', ''%s'': '...
                        'try fixing it manually...'], o.DataFileName, o.FldImportedSubjects, o.FldFiles); 
                    success = false;
                    return
                end
            end
            try
                o.SubjectsList = subjs;
                o.ImportedSubjectsList = imported;
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
            imported = o.ImportedSubjectsList;
            files = o.FilesList;
            throwExcpt = nargin > 1 && throwExcpt;
            objFld = @(fld)[class(o) '.' fld];

            if length(imported) ~= length(files)
                WTCodingUtils.throwOrLog(WTException.incompatibleValues('Fields %s and %s have different length', ...
                    objFld(o.FldImportedSubjects), objFld(o.FldFiles)), ~throwExcpt);
                success = false;
            end
            if any(cellfun(@isempty, regexp(subjs, WTIOProcessor.SubjIdRe)))
                WTCodingUtils.throwOrLog(WTException.badValue('%s must be char arrays representing numbers', ...
                    objFld(o.FldSubjects)), ~throwExcpt);
                success = false;
            end
            if any(cellfun(@isempty, regexp(imported, WTIOProcessor.SubjIdRe)))
                WTCodingUtils.throwOrLog(WTException.badValue('%s must be char arrays representing numbers', ...
                    objFld(o.FldImportedSubjects)), ~throwExcpt);
                success = false;
            end
            if ~all(arrayfun(@(i)WTIOProcessor.isSubjectInImportFileName(imported{i}, files{i}), 1:length(files)))
                WTCodingUtils.throwOrLog(WTException.badValue('Each %s[n] element must contain %s[n]', ...
                    objFld(o.FldFiles), objFld(o.FldImportedSubjects)), ~throwExcpt);
                success = false;
            end
            if length(intersect(subjs, imported)) ~= length(subjs)
                WTCodingUtils.throwOrLog(WTException.badValue('Each %s element must be in %s', ...
                    objFld(o.FldSubjects), objFld(o.FldImportedSubjects)), ~throwExcpt);
                success = false;
            end
        end

        function success = persist(o)
            txt1 = WTConfigFormatter.stringCellsField(o.FldSubjects, o.SubjectsList);
            txt2 = WTConfigFormatter.stringCellsField(o.FldImportedSubjects, o.ImportedSubjectsList);
            txt3 = WTConfigFormatter.stringCellsField(o.FldFiles, o.FilesList);
            success = ~any(cellfun(@isempty,{txt1 txt2 txt3})) && o.write(txt1,txt2,txt3);
        end
    end
end
