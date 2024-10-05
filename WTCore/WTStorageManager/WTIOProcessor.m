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

classdef WTIOProcessor < handle

    properties(Constant,Access=private)
        LogSubDir        = 'Logs'
        ConfigSubDir     = 'Config'
        SupportSubDir    = 'Support'
        ImportSubDir     = 'Import'
        WaveletsSubDir   = 'WaveletTransform'
        AnalysisSubDir   = 'Analysis'
        GrandAvgSubDir   = 'GrandAvg'
        StatisticsSubDir = 'Statistics'
        TemporarySubDir  = 'Tmp'
    end

    properties(Constant, Hidden)
        WaveletsAnalisys         = ''
        WaveletsAnalisys_ITLC    = 'ITLC'
        WaveletsAnalisys_ITPC    = 'ITPC'
        WaveletsAnalisys_ERSP    = 'ERSP'
        WaveletsAnalisys_evWT    = 'evWT'
        WaveletsAnalisys_avWT    = 'avWT'
        WaveletsAnalisys_WTav    = 'WTav'
        WaveletsAnalisys_Induced = 'Induced'

        SystemEGI    = 'EGI'
        SystemEEP    = 'EEP'
        SystemEEGLab = 'EEGLab'
        SystemBRV    = 'BRV'

        ChansLocationCEDFileExt = '.ced'
        ChansLocationSFPFileExt = '.sfp'
        ChansLocationELPFileExt = '.elp'
        SplineFileExt = '.spl'
        SplineFileTypeFlt = ['*' WTIOProcessor.SplineFileExt]
        MeshFileExt = '.mat'
        GrandAvgFileExt = '.mat'
        PerSbjGrandAvgFileExt = '.ss'
        SubjIdRe = '^\d+$'
        SubjAnalysisSubDirRe  = sprintf('^(?<subject>\\d+)%s*$', WTCodingUtils.ifThenElse(ispc, '\\','/'));
        EGIConditionSegmentFldRe = '^(?<condition>.+)_Segment[^0-9]*(?<segment>\d+)$'
        BaselineCorrectedFileNameRe = ['^((?<subject>\d+)_)?(?<condition>[^_]+)_bc-(?<measure>.+)(?:\' ...
            WTIOProcessor.GrandAvgFileExt '|\' WTIOProcessor.PerSbjGrandAvgFileExt ')$'] 
    end

    properties(Constant,Access=private,Hidden)
        SystemEEPImportFileRe = '^(?<subject>\d+).*\.cnt$'
        SystemEEGLabImportFileRe = '^(?<subject>\d+).*\.set$'
        SystemEGIImportFileRe = '^(?<subject>\d+).*\.mat$'
        SystemBRVImportFileRe = '^(?<subject>\d+).*\.mat$'

        AnyImportFileRe = [
            WTIOProcessor.SystemEEPImportFileRe '|' ...
            WTIOProcessor.SystemEEGLabImportFileRe '|' ...
            WTIOProcessor.SystemEGIImportFileRe '|' ...
            WTIOProcessor.SystemBRVImportFileRe]
    end

    properties(SetAccess=private,GetAccess=public)
        RootDir char
        LogDir char
        ConfigDir char
        SupportDir char
        ImportDir char
        AnalysisDir char
        GrandAvgDir char
        StatisticsDir char
        TemporaryDir char
    end

    methods(Static,Access=private)
        function [success, varargout] = readModule(dir, file, varargin) 
            fName = fullfile(dir, file);
            varargout = cell(nargout-1, 1);
            [success, varargout{:}] = WTIOUtils.readModuleFile(fName, varargin{:});

            if success 
                return
            elseif nargin == 1
                WTLog().err('Can''t read file ''%s''', fName);
            else
                WTLog().err('Can''t read file ''%s'' or some content field(s) are missing: %s', fName, char(join(varargin,',')));
            end
        end

        function success = writeTxtFile(dir, file, varargin) 
            fName = fullfile(dir, file);
            success = WTIOUtils.writeTxtFile(dir, file, 'wt', 'UTF-8', varargin{:});
            if ~success 
                WTLog().err('Failed to write file ''%s''', fName);
            end
        end

        function [fName, fileExist] = exist(shouldExist, dir, file)
            fName = fullfile(dir, file);
            fileExist = isfile(fName);
            if shouldExist && ~fileExist 
                WTException.notExistingPath('"%s" is not a valid file path', fName).throw();
            end
        end

        function [subjects, sbjFiles] = getSbjsFromImportFiles(fileNameFmtRe, varargin)
            match = regexp(varargin, fileNameFmtRe, 'once', 'names');
            result = ~cellfun(@isempty, match);
            sbjFiles = varargin(result);
            subjects = cellfun(@(x){x.subject}, match(result));
        end

        function re = getSystemImportFileNameFmtRe(system) 
            switch system
                case WTIOProcessor.SystemEEP
                    re = WTIOProcessor.SystemEEPImportFileRe;
                case WTIOProcessor.SystemEEGLab
                    re = WTIOProcessor.SystemEEGLabImportFileRe;
                case WTIOProcessor.SystemEGI
                    re = WTIOProcessor.SystemEGIImportFileRe;
                case WTIOProcessor.SystemBRV
                    re = WTIOProcessor.SystemBRVImportFileRe;
                otherwise
                    WTException.badArg('Unknown system: %s', WTCodingUtils.ifThenElse(ischar(system), system, '?')).throw();
            end
        end

        % This function is extracted from EEGlab readlocs()
        function fileType = getChannelsLocationsFileType(fileExt)
            fileExt = fileExt(1,2:end);

            switch lower(fileExt)
                case {'loc' 'locs' 'eloc'}
                    fileType = 'loc';
                case 'xyz' 
                    fileType = 'xyz'; 
                case 'sph'
                    fileType = 'sph';
                case 'ced'
                    fileType = 'chanedit';
                case 'elp'
                    % 2 options here: 'besa' 'polhemus'
                    fileType = 'besa'; 
                case 'asc'
                    fileType = 'asc';
                case 'dat'
                    fileType = 'dat';
                case 'elc'
                    fileType = 'elc';
                case 'eps'
                    fileType = 'besa';
                case 'sfp'
                    fileType = 'sfp';
                case 'tsv'
                    fileType = 'tsv';
                case 'mat'
                    fileType = 'mat';
                otherwise
                    fileType =  ''; 
            end
        end

        % filterAndRenameEGITrialFields() filter out data fields which do not refer to the list of 
        % selected 'conditions' or 'trials' set. When 'conditions' is empty, all conditions are 
        % selected. When 'trials' is empty, all trials are selected. 'trials' maybe a list of numbers
        % or a struct with 2 fields Min and Max, in which case it represents a range.
        function [success, dataOut] = filterAndRenameEGITrialFields(dataIn, conditions, trials)
            wtLog = WTLog();
            success = false;
            dataOut = struct();
        
            wtLog.pushStatus().contextOn('EGIDataFieldsFilterAndRename');
        
            try
                dataOut = struct(); 
                % fields should be normally ordered and we keep the same order
                dataFields = fieldnames(dataIn);
                % find the <condition>_Segment<#> fields
                reResult = regexp(dataFields, WTIOProcessor.EGIConditionSegmentFldRe, 'once', 'tokens');
                selected = ~cellfun(@isempty, reResult); 
                selectedIdxs = find(selected);
                % extract conditions name
                matches = reResult(selected);
                cndSeg = cat(1, matches{:});  % {{'cnd'}, {'seg'}}
                conditions = unique(cndSeg(:,1));
                % create a counters for each condition
                counters = cell2struct(repmat({zeros(1)}, 1, length(conditions)), conditions, 2);

                for i = 1:length(selectedIdxs)
                    fldIdx = selectedIdxs(i);
                    cndName = reResult{fldIdx}{1};
                    if ~isempty(conditions) && ~any(strcmp(cndName, conditions)) % ignore unselected conditions
                        wtLog.dbg('Removed excluded condition field: %s', dataFields{fldIdx});
                        continue
                    end
                    if ~isempty(trials) 
                        segNum = WTNumUtils.str2double(reResult{fldIdx}{2});
                        if (isstruct(trials) && (segNum < trials.Min || segNum > trials.Max)) || ...
                           (~isstruct(trials) && isvector(trials) && any(trials == segNum)) % ignore unselected trials
                            wtLog.dbg('Removed excluded trial field: %s', dataFields{fldIdx});
                            continue
                        end
                    end
                    newSegNum = counters.(cndName)+1;
                    counters.(cndName) = newSegNum;
                    newFieldName = [cndName '_Segment' num2str(newSegNum)];
                    dataOut.(newFieldName) = dataIn.(dataFields{fldIdx});
                    wtLog.dbg('Renamed data field %s => %s', dataFields{fldIdx}, newFieldName);
                end
        
                invariantFields = dataFields(~selected);
        
                for i = 1:length(invariantFields)
                    dataOut.(invariantFields{i}) = dataIn.(invariantFields{i});
                    wtLog.dbg('Unaffected data field %s', invariantFields{i});
                end
        
                success = true;
            catch me
                wtLog.except(me);
                wtLog.err('Failed to perform trial ajustments');
            end
        
            wtLog.popStatus();
        end

        function [success, EEG] = restoreEGICz(EEG) 
            wtLog = WTLog();
            success = false;

            wtLog.info('Restoring Cz channel data to allow channels re-referencing...');

            if ~isfield(EEG, 'chaninfo') || ...
               ~isfield(EEG.chaninfo, 'nodatchans') || ...
               ~isfield(EEG, 'chanlocs') || ...
               ~isfield(EEG, 'urchanlocs')
                wtLog.err('Cannot channels info details!');
                return
            end

            noDataChans = EEG.chaninfo.nodatchans;
            
            if isempty(noDataChans) || ~strcmp(noDataChans(end).labels, 'Cz')
                wtLog.err('Cannot find Cz channel location data!');
                return
            end

            ref = zeros(1, size(EEG.data, 2), size(EEG.data, 3)); 
            EEG.data = cat(1, EEG.data, ref);
            EEG.nbchan = size(EEG.data, 1);
            EEG.chanlocs(end+1) = EEG.chaninfo.nodatchans(end);
            EEG.urchanlocs(end+1) = EEG.chaninfo.nodatchans(end);
            EEG.chaninfo.nodatchans(end) = [];
            [success, EEG] = WTEEGLabUtils.eeglabRun(WTLog.LevelInf, true, 'eeg_checkset', EEG);
        end
    end

    methods(Static,Access=public)
        function systems = getSystemTypes() 
            systems = { ...
                WTIOProcessor.SystemEGI, ...
                WTIOProcessor.SystemEEP, ...
                WTIOProcessor.SystemBRV, ...
                WTIOProcessor.SystemEEGLab};
        end

        function filePath = getEEGLabRawFile(subjectFilePath)
            [dir, name, ~] = fileparts(subjectFilePath);
            filePath = fullfile(dir, [name '.fdt']);
        end  

        function filePath = getEEPRejectionFile(subjectFilePath)
            [dir, name, ~] = fileparts(subjectFilePath);
            filePath = fullfile(dir, [name 'fr.rej']);
        end  

        function extension = getSystemImportFileExtension(system)           
            switch system
                case WTIOProcessor.SystemEEP
                    extension = 'cnt';
                case WTIOProcessor.SystemEEGLab
                    extension = 'set';
                case WTIOProcessor.SystemEGI
                    extension = 'mat';
                case WTIOProcessor.SystemBRV
                    extension = 'mat';
                otherwise
                    WTException.badArg('Unknown system: %s', WTCodingUtils.ifThenElse(ischar(system), system, '?')).throw();
            end
        end

        function in = isSubjectInImportFileName(subject, importFileName)
            in = contains(importFileName, subject);
        end

        function [success, meshFile] = getMeshFileFromSplineFile(splineFile) 
            [~, fileName, fileExt] = fileparts(splineFile);
            success = strcmp(fileExt, WTIOProcessor.SplineFileExt);
            meshFile = WTCodingUtils.ifThenElse(success, @()fullfile(WTLayout.getSplinesDir(), [fileName WTIOProcessor.MeshFileExt]), []); 
        end

        function [wType, extension] = getGrandAverageFileTypeAndExtension(perSubject, evokedOscillation)
            wType = WTCodingUtils.ifThenElse(evokedOscillation, ...
                WTIOProcessor.WaveletsAnalisys_evWT, WTIOProcessor.WaveletsAnalisys_avWT);
            extension = WTCodingUtils.ifThenElse(perSubject, ...
                WTIOProcessor.PerSbjGrandAvgFileExt,  WTIOProcessor.GrandAvgFileExt);
        end

        function fileNames = getSystemExtraImportFiles(system, subjectFilePath)           
            switch system
                case WTIOProcessor.SystemEEP
                    fileNames = { WTIOProcessor.getEEPRejectionFile(subjectFilePath) };
                case WTIOProcessor.SystemEEGLab
                    fileNames = { WTIOProcessor.getEEGLabRawFile(subjectFilePath) };
                case WTIOProcessor.SystemEGI
                    fileNames = {};
                case WTIOProcessor.SystemBRV
                    fileNames = {};
                otherwise
                    WTException.badArg('Unknown system: %s', WTCodingUtils.ifThenElse(ischar(system), system, '?')).throw();
            end
        end

        function extensions = getSystemChansLocationFileExtension(system) 
            switch system
                case WTIOProcessor.SystemEEP
                    extensions = {WTIOProcessor.ChansLocationCEDFileExt};
                case WTIOProcessor.SystemEEGLab
                    extensions = {WTIOProcessor.ChansLocationSFPFileExt, WTIOProcessor.ChansLocationELPFileExt};
                case WTIOProcessor.SystemEGI
                    extensions = {WTIOProcessor.ChansLocationSFPFileExt};
                case WTIOProcessor.SystemBRV
                    extensions = {WTIOProcessor.ChansLocationSFPFileExt, WTIOProcessor.ChansLocationELPFileExt};
                otherwise
                    WTException.badArg('Unknown system: %s', WTCodingUtils.ifThenElse(ischar(system), system, '?')).throw();
            end
        end

        function [subject, condition, wType] = splitBaselineCorrectedFileName(fileName)
            subject = [];
            condition = [];
            wType = [];
            match =regexp(fileName, WTIOProcessor.BaselineCorrectedFileNameRe, 'once', 'names');
            if isempty(match)
                return
            end
            if isfield(match, 'subject')
                subject = match.subject;
            end
            condition = match.condition;
            wType = match.measure;
        end

        function [conditions, emptyConditionFiles] = getConditionsFromBaselineCorrectedFileNames(fileNames)
            conditions = cell(1, length(fileNames));
            emptyConditionFiles = {};
            for i = 1:length(fileNames) 
                [~, condition] = WTIOProcessor.splitBaselineCorrectedFileName(fileNames{i});
                if isempty(condition)
                    emptyConditionFiles = [emptyConditionFiles fileNames(i)];
                    continue
                end
                conditions{i} = condition;
            end
        end
    end

    methods(Access=private)
        function default(o)
            o.RootDir = '';
            o.LogDir = '';
            o.ConfigDir = '';
            o.SupportDir = '';
            o.ImportDir = '';
            o.AnalysisDir = '';
            o.GrandAvgDir = '';
            o.StatisticsDir = '';
            o.TemporaryDir = '';
        end 

        function [success, data] = loadEGIImport(o, fileToImport, sampleRate, triggerLatency, conditions, trials) 
            wtLog = WTLog();
            success = false;
            data = [];
            
            wtLog.pushStatus().contextOn('LoadEGIImport');
            wtLog.warn('Attempt to import data in EEGLab...');

            try
                [success, data] = WTEEGLabUtils.eeglabRunQuiet(true, 'pop_importegimat', ...
                    fileToImport, sampleRate, triggerLatency);
            catch
            end
        
            if success
                [success, data] = WTIOProcessor.restoreEGICz(data);
                wtLog.popStatus();
                return
            end
        
            wtLog.warn('Attempt to import EGI data in EEGLab failed: retrying by fixing trials name...');
        
            [ok, data] = WTIOUtils.loadFrom(fileToImport, '-mat');
            if ~ok 
                wtLog.err('Cannot import EGI data in any way');
                wtLog.popStatus();
                return
            end
        
            [ok, data] = WTIOProcessor.filterAndRenameEGITrialFields(data, conditions, trials);
            if ~ok
                wtLog.popStatus(); 
                return
            end
                
            tmpFile = o.getTemporaryFile('', ['_' WTIOUtils.getPathTail(fileToImport)]);
            wtLog.info('Creating temporary file for adjusted import data: ''%s''', tmpFile);
        
            if ~WTIOUtils.saveTo([], tmpFile, '-struct', 'data')
                wtLog.err('Failed to save temporary data file with trial ajustments (%s)', tmpFile);
                wtLog.popStatus();
                return
            end
        
            [success, data] = WTEEGLabUtils.eeglabRun(WTLog.LevelInf, true, 'pop_importegimat', ...
                tmpFile, sampleRate, triggerLatency);
            
            wtLog.info('Deleting temporary file created to adjust import data: ''%s''', tmpFile);
            delete(tmpFile);

            [success, data] =  WTIOProcessor.restoreEGICz(data);
            wtLog.popStatus();
        end
    end

    methods
        function o = WTIOProcessor()
            o.default();
        end

        function success = setRootDir(o, rootDir, mustExist) 
            success = false;
            o.RootDir = WTIOUtils.getAbsPath(rootDir);
            o.LogDir = fullfile(o.RootDir, o.LogSubDir);
            o.ConfigDir = fullfile(o.RootDir, o.ConfigSubDir);
            o.SupportDir = fullfile(o.RootDir, o.SupportSubDir);
            o.ImportDir = fullfile(o.RootDir, o.ImportSubDir);
            o.AnalysisDir = fullfile(o.RootDir, o.AnalysisSubDir);
            o.GrandAvgDir = fullfile(o.AnalysisDir, o.GrandAvgSubDir);
            o.StatisticsDir = fullfile(o.RootDir, o.StatisticsSubDir);
            o.TemporaryDir = fullfile(o.RootDir, o.TemporarySubDir);
            wtLog = WTLog();
            
            if mustExist
                if ~isfolder(o.RootDir)
                    wtLog.err('Root directory doesn''t exist or it''s not a directory: %s', o.RootDir);
                elseif ~isfolder(o.ConfigDir)
                    wtLog.err('Config directory doesn''t exist or it''s not a directory: %s', o.ConfigDir); 
                elseif ~isfolder(o.ImportDir)
                    wtLog.err('Import directory doesn''t exist or it''s not a directory: %s', o.ImportDir); 
                elseif ~isfolder(o.AnalysisDir)
                    wtLog.err('Analysis directory doesn''t exist or it''s not a directory: %s', o.AnalysisDir); 
                else 
                    success = true;
                end
            elseif ~WTIOUtils.mkdir(o.RootDir) 
                wtLog.err('Failed to create root directory: %s', o.RootDir);
            elseif ~WTIOUtils.mkdir(o.ConfigDir)
                wtLog.err('Failed to create config directory: %s', o.ConfigDir);
            elseif ~WTIOUtils.mkdir(o.ImportDir)
                wtLog.err('Failed to create import directory: %s', o.ImportDir);
            elseif ~WTIOUtils.mkdir(o.AnalysisDir)
                wtLog.err('Failed to create analysis directory: %s', o.AnalysisDir);
            else
                success = true;
            end
            if ~success
                o.default();
            end
        end

        function defined = rootDirDefined(o) 
            defined = ~isempty(o.RootDir);
        end

        function [fullPath, filePath] = getLogFile(o, prefix)
            time = char(datetime('now','TimeZone','local','Format', 'yyyyMMdd.HHmmss'));
            fileName = sprintf('%s.%s.log', prefix, time);
            filePath = o.LogDir;
            fullPath = fullfile(filePath, fileName);
        end

        function configFile = getConfigFile(o, fName) 
            configFile = fullfile(o.ConfigDir, fName);
        end
        
        function [success, varargout] = configRead(o, cfgFile, varargin) 
            varargout = cell(nargout-1, 1);
            [success, varargout{:}] = WTIOProcessor.readModule(o.ConfigDir, cfgFile, varargin{:});
        end

        function success = configWrite(o, cfgFile, varargin) 
            success = WTIOProcessor.writeTxtFile(o.ConfigDir, cfgFile, varargin{:});
        end

        function success = statsWrite(o, statsFile, varargin) 
            success = WTIOProcessor.writeTxtFile(o.StatisticsDir, statsFile, varargin{:});
        end

        function [fName, fileExist] = configExist(o, shouldExist, cfgFile)
            [fName, fileExist] = WTIOProcessor.exist(shouldExist, o.ConfigDir, cfgFile);
        end

        function [fullPath, filePath] = getTemporaryFile(o, fileNamePrefix, fileNamePostfix)
            filePath = o.TemporaryDir;
            if nargin < 2 
                fileNamePrefix = '';
            end
            if nargin < 3 
                fileNamePostfix = '';
            end
            fileName = [fileNamePrefix WTIOUtils.getPathTail(tempname('.')) fileNamePostfix];
            fullPath = fullfile(filePath, fileName);
        end  

        function [fullPath, filePath, fileName] = getSupportFile(o, fileName, supportDir)
            filePath = WTCodingUtils.ifThenElse(nargin > 2 && ~isempty(supportDir), supportDir, o.SupportDir);
            fullPath = fullfile(filePath, fileName);
        end

        function [fullPath, filePath, fileName] = getChannelsLocationsFile(o, fileName, local)
            if nargin > 2 && local
                [~, fileName, fileExt] = fileparts(fileName);
                fileName = [ fileName '.Modified' fileExt];
            end
            [fullPath, filePath, fileName] = o.getSupportFile(fileName, WTCodingUtils.ifThenElse(local, [], WTLayout.getChannelsLayoutsDir));
        end

        function [success, chansLocations] = readChannelsLocations(o, fileName, local)
            fullPath = o.getChannelsLocationsFile(fileName, local);
            [success, chansLocations] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'readlocs', fullPath, 'filetype', 'autodetect');
        end

        % Channels locations files can only be written in the project support dir
        function success = writeChannelsLocations(o, chanLocs, fileName)
            success = false;
            fullPath = o.getChannelsLocationsFile(fileName, true);
            [fileDir, ~, fileExt] = fileparts(fullPath);
            if ~WTIOUtils.dirExist(fileDir) && ~WTIOUtils.mkdir(fileDir)
                return
            end
            fileType = WTIOProcessor.getChannelsLocationsFileType(fileExt);
            success = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'writelocs', chanLocs, fullPath, 'filetype', fileType);
        end

        function [fullPath, filePath, fileName] = getSplineFile(o, fileName, local)
            if nargin > 2 && local
                [~, fileName, fileExt] = fileparts(fileName);
                fileName = [ fileName '.Modified' fileExt];
            end
            [fullPath, filePath, fileName] = o.getSupportFile(fileName, WTCodingUtils.ifThenElse(local, [], WTLayout.getSplinesDir));
        end

        function [success, spline] = readSpline(o, fileName, local)
            fullPath = o.getSplineFile(fileName, local);
            [success, spline] = WTIOUtils.loadFrom(fullPath, '-mat');
        end

        % Spline files can only be written in the project support dir
        function success = writeSpline(o, spline, fileName)
            success = false;
            fullPath = o.getSplineFile(fileName, true);
            success = WTIOUtils.saveTo([], fullPath, '-struct', 'spline');
        end

        % In this case fileName can be either scalar or a cell array of strings
        function [subjects, sbjFiles] = getSubjectsFromImportFiles(o, system, varargin)
            fileNameFmtRe = WTIOProcessor.getSystemImportFileNameFmtRe(system);
            [subjects, sbjFiles] = WTIOProcessor.getSbjsFromImportFiles(fileNameFmtRe, varargin{:});
        end

        function [subjFiles, subjects] = enumImportFiles(o, system) 
            fileNameFmtRe =  WTIOProcessor.getSystemImportFileNameFmtRe(system);
            extensionFlt = ['*.' WTIOProcessor.getSystemImportFileExtension(system)];
            dirContent = dir(fullfile(o.ImportDir, extensionFlt));
            subjFiles = cell(length(dirContent), 1);
            subjects = cell(length(dirContent), 1);
            nValid = 0;

            for i = 1:length(dirContent)
                if dirContent(i).isdir
                    continue
                end
                subject = WTIOProcessor.getSbjsFromImportFiles(fileNameFmtRe, dirContent(i).name);
                if ~isempty(subject)
                    nValid = nValid + 1;
                    subjFiles{nValid} = dirContent(i).name;
                    subjects{nValid} = subject;
                end
            end

            if nValid > 0
                subjFiles = subjFiles(1:nValid);
                subjects = subjects{1:nValid};
            end
        end

        function [success, sbjDir] = makeAnalysisSubjectDir(o, subject)
            sbjDir = fullfile(o.AnalysisDir, subject);
            success = WTIOUtils.mkdir(sbjDir);
        end

        function count = countImportFiles(o)
            dirContent = dir(fullfile(o.ImportDir, '*'));
            count = 0;
            for i = 1:length(dirContent)
                if dirContent(i).isdir 
                    continue
                end
                if ~isempty(regexp(dirContent(i).name, WTIOProcessor.AnyImportFileRe, 'once'))
                    count = count + 1;
                end
            end
        end

        function [fullPath, filePath] = getImportFile(o, fileName)
            filePath = o.ImportDir;
            fullPath = fullfile(filePath, fileName);
        end

        % loadImport() loads data from import source files. It takes as input the system type, the fileName
        % and a struct (possibly empty depending on the system) which stores extra params necessary to the 
        % import procedure. The structure must contain a field named after the 'system' which store a sub
        % structure. For EGI system, such sub-structure should either be empty for a "raw" import (just 
        % load the file as .mat) or have both the 2 fields SampleRate & TriggerLatency to run the eeglab import.
        % In the latter case, the structure might have 2 extra optional fields 'Conditions' and 'Trials' to
        % filter out some of the import data fields (check filterAndRenameEGITrialFields() for more details).
        % For system other than EGI, at the moment there are no specific parameters, so 'params' is ignored.
        function [success, data] = loadImport(o, system, fileName, params)
            wtLog = WTLog();
            success = false;
            data = [];

            [fullPath, filePath] = o.getImportFile(fileName);
            params = WTCodingUtils.ifThenElse(isfield(params, system), @()getfield(params, system), struct());
  
            switch system
                case WTIOProcessor.SystemEGI
                    if isfield(params, 'SampleRate') && isfield(params, 'TriggerLatency')
                        conditions = WTCodingUtils.ifThenElse(isfield(params, 'Conditions'), @()params.Conditions, []);
                        trials =  WTCodingUtils.ifThenElse(isfield(params, 'Trials'), @()params.Trials, []);
                        [success, data] = o.loadEGIImport(fullPath, params.SampleRate, params.TriggerLatency, conditions, trials);
                    else
                        [success, data] = WTIOUtils.loadFrom(fullPath, '-mat');
                    end
                case WTIOProcessor.SystemEEGLab
                    [success, data] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                case WTIOProcessor.SystemEEP
                    [success, data] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_loadeep_v4', fullPath, 'triggerfile', 'on');
                case WTIOProcessor.SystemBRV
                    [success, data] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, true, 'pop_loadbva', fullPath);
                otherwise
                    wtLog.err('Unknown system: %s', WTCodingUtils.ifThenElse(ischar(system), system, '?'));
            end
        end

        function [success, conditions, data] = getConditionsFromImport(o, system, fileName)
            wtLog = WTLog();
            conditions = {};

            [success, data] = o.loadImport(system, fileName, struct());
            if ~success 
                return
            end

            try 
                switch system
                    case WTIOProcessor.SystemEGI
                        fieldNames = fieldnames(data);
                        result = regexp(fieldNames, o.EGIConditionSegmentFldRe, 'once', 'tokens');
                        match = result(~cellfun(@isempty, result));
                        cndSeg = cat(1, match{:});
                        conditions = unique(cndSeg(:,1));
                        success = ~isempty(conditions);
                    case WTIOProcessor.SystemEEGLab
                        conditions = sort(unique({ data.event.type }));
                    case WTIOProcessor.SystemEEP
                        wtLog.err('Unsupported system: %s', system);
                    case WTIOProcessor.SystemBRV
                        conditions = sort(unique({ data.event.type }));
                    otherwise
                        wtLog.err('Unknown system: %s', WTCodingUtils.ifThenElse(ischar(system), system, '?'));
                end
            catch me
                wtLog.excpet(me);
                success = false;
            end
        end

        function [fullPath, filePath, fileName] = getProcessedImportFile(o, filePrefix, subject)
            fileName = strcat(filePrefix, '_', subject, '.set');
            filePath = fullfile(o.AnalysisDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        function [success, EEG, ALLEEG] = loadProcessedImport(o, filePrefix, subject, updateALLEEG)
            success = false;
            ALLEEG = [];
            EEG = [];
            
            try
                updateALLEEG = nargin < 4 || updateALLEEG;
                [~, filePath, fileName] = o.getProcessedImportFile(filePrefix, subject);

                if ~updateALLEEG
                    EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                else
                    [ALLEEG, ~, ~, ~] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false);
                    EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                    [ALLEEG, EEG, ~] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, 0);
                    EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
                end
                success = true;
            catch 
                WTLog().except(me);
            end 

            if ~success 
                WTLog().err('Failed to load processed import related to subject ''%s''', subject);
            end
        end

        function [success, fullPath, EEG] = writeProcessedImport(o, filePrefix, subject, EEG)
            success = false;
            
            [fullPath, filePath, fileName] = o.getProcessedImportFile(filePrefix, subject);
            dirExist = WTIOUtils.dirExist(filePath);

            if ~dirExist && ~WTIOUtils.mkdir(filePath)
                WTLog().err('Failed to make dir ''%s''', filePath);
                return
            end

            try
                EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
                EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_saveset', EEG,  'filename', fileName, 'filepath', filePath);
                success = true;
            catch me
                if ~dirExist
                    WTIOUtils.rmdir(filePath, true);
                else
                    delete(fullPath)
                end
                WTLog().except(me);
            end
        end

        function setName = getConditionSet(~, filePrefix, subject, condition)
            setName = strcat(filePrefix, '_', subject, '_', condition);
        end

        function [fullPath, filePath, fileName] = getConditionFile(o, filePrefix, subject, condition)
            fileName = strcat(o.getConditionSet(filePrefix, subject, condition), '.set');
            filePath = fullfile(o.AnalysisDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        function [success, EEG] = loadCondition(o, filePrefix, subject, condition, updateALLEEG)
            success = false;
            EEG = [];
            
            try
                updateALLEEG = nargin < 5 || updateALLEEG;
                [~, filePath, fileName] = o.getConditionFile(filePrefix, subject, condition);

                if ~updateALLEEG
                    EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                else
                    [ALLEEG, ~, ~, ~] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false);
                    EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'pop_loadset', 'filename', fileName, 'filepath', filePath);
                    [~, EEG, ~] = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_store', ALLEEG, EEG, 0);
                    EEG = WTEEGLabUtils.eeglabRun(WTLog.LevelDbg, false, 'eeg_checkset', EEG);
                end
                success = true;
            catch me
                WTLog().except(me);
            end 
        end

        function [fullPath, filePath, fileName] = getBaselineCorrectionFile(o, subject, condition, wType)
            switch wType
                case WTIOProcessor.WaveletsAnalisys_evWT
                case WTIOProcessor.WaveletsAnalisys_avWT
                otherwise
                    fullPath = [];
                    filePath = [];
                    fileName = [];
                    WTLog().err('Unknown file type %s', wType);
                    return
            end
            fileName = strcat(subject, '_', condition, '_bc-', wType, '.mat');
            filePath = fullfile(o.AnalysisDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeBaselineCorrection(o, subject, condition, wType, varargin)
            success = false;
            fullPath = [];
           
            try
                [fullPath, filePath, fileName] = o.getBaselineCorrectionFile(subject, condition, wType);
                if ~isempty(fullPath)
                    argsName = [{filePath fileName} varargin];
                    argsName = WTStringUtils.quoteMany(argsName{:});
                    cmd = sprintf('WTIOUtils.saveTo(%s);', char(join(argsName, ',')));
                    evalin('caller', cmd);
                    success = true;
                end
            catch me
                WTLog().except(me);
            end
        end

        function [success, varargout] = loadBaselineCorrection(o, subject, condition, wType, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getBaselineCorrectionFile(subject, condition, wType);
            if ~isempty(fullPath)
                [success, varargout{:}] = WTIOUtils.loadFrom(fullPath, '-mat', varargin{:});
            end
        end

        function [fullPath, filePath, fileName] = getGrandAverageFile(o, condition, wType, perSubject)
            switch wType
                case WTIOProcessor.WaveletsAnalisys_evWT
                case WTIOProcessor.WaveletsAnalisys_avWT
                otherwise
                    fullPath = [];
                    filePath = [];
                    fileName = [];
                    WTLog().err('Unknown file type %s', wType);
                    return
            end
            extension = WTCodingUtils.ifThenElse(perSubject, ...
                WTIOProcessor.PerSbjGrandAvgFileExt,  WTIOProcessor.GrandAvgFileExt);
            fileName = strcat(condition, '_bc-', wType, extension);
            filePath = o.GrandAvgDir;
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeGrandAverage(o, condition, wType, perSubject, varargin)
            success = false;
            fullPath = [];
           
            try
                [fullPath, filePath, fileName] = o.getGrandAverageFile(condition, wType, perSubject);
                if ~isempty(fullPath)
                    args = {filePath fileName};
                    args = [args varargin];
                    args = WTStringUtils.quoteMany(args{:});
                    cmd = sprintf('WTIOUtils.saveTo(%s);', char(join(args, ',')));
                    evalin('caller', cmd);
                    success = true;
                end
            catch me
                WTLog().except(me);
            end
        end

        function [success, varargout] = loadGrandAverage(o, condition, wType, perSubject, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getGrandAverageFile(condition, wType, perSubject);
            if ~isempty(fullPath)
                [success, varargout{:}] = WTIOUtils.loadFrom(fullPath, '-mat', varargin{:});
            end
        end

        function [fullPath, filePath, fileName] = getDifferenceFile(o, subject, condA, condB, wType)
            switch wType
                case WTIOProcessor.WaveletsAnalisys_evWT
                case WTIOProcessor.WaveletsAnalisys_avWT
                otherwise
                    fullPath = [];
                    filePath = [];
                    fileName = [];
                    WTLog().err('Unknown file type %s', wType);
                    return
            end
            fileName = strcat(subject, '_', condA, '-', condB, '_bc-', wType, '.mat');
            filePath = fullfile(o.AnalysisDir, subject);
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeDifference(o, subject, condA, condB, wType, varargin)
            success = false;
            fullPath = [];
            try
                [fullPath, filePath, fileName] = o.getDifferenceFile(subject, condA, condB, wType);
                if ~isempty(fullPath)
                    argsName = [{filePath fileName} varargin];
                    argsName = WTStringUtils.quoteMany(argsName{:});
                    cmd = sprintf('WTIOUtils.saveTo(%s);', char(join(argsName, ',')));
                    evalin('caller', cmd);
                    success = true;
                end
            catch me
                WTLog().except(me);
            end
        end

        function [success, varargout] = loadDifference(o, subject, condA, condB, wType, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getDifferenceFile(subject, condA, condB, wType);
            if ~isempty(fullPath)
                [success, varargout{:}] = WTIOUtils.loadFrom(fullPath, '-mat', varargin{:});
            end
        end

        function [fullPath, filePath, fileName] = getWaveletAnalysisFile(o, subject, condition, wType)
            fullPath = [];
            filePath = [];
            fileName = [];

            switch wType
                case WTIOProcessor.WaveletsAnalisys
                    fileName = strcat(subject, '_' , condition, '.mat'); 
                case WTIOProcessor.WaveletsAnalisys_ITLC
                case WTIOProcessor.WaveletsAnalisys_ITPC 
                case WTIOProcessor.WaveletsAnalisys_ERSP
                case WTIOProcessor.WaveletsAnalisys_evWT
                case WTIOProcessor.WaveletsAnalisys_avWT
                case WTIOProcessor.WaveletsAnalisys_WTav
                case WTIOProcessor.WaveletsAnalisys_Induced
                otherwise
                    WTLog().err('Unknown file type %s', wType);
                    return
            end
            if isempty(fileName)
                fileName = strcat(subject, '_' , condition, '-', wType, '.mat');
            end
            filePath = fullfile(o.AnalysisDir, subject, o.WaveletsSubDir, condition);
            fullPath = fullfile(filePath, fileName);
        end

        % varargin must be char array: the names of the variable to save
        function [success, fullPath] = writeWaveletsAnalysis(o, subject, condition, wType, varargin)
            success = false;
            fullPath = [];
            try
                [fullPath, filePath, fileName] = o.getWaveletAnalysisFile(subject, condition, wType);
                if ~isempty(fullPath)
                    argsName = [{filePath fileName} varargin];
                    argsName = WTStringUtils.quoteMany(argsName{:});
                    cmd = sprintf('WTIOUtils.saveTo(%s);', char(join(argsName, ',')));
                    evalin('caller', cmd);
                    success = true;
                end
            catch me
                WTLog().except(me);
            end
        end

        function [success, varargout] = loadWaveletsAnalysis(o, subject, condition, wType, varargin)
            success = false;
            varargout = cell(1, nargout-1);
            fullPath = o.getWaveletAnalysisFile(subject, condition, wType);
            if ~isempty(fullPath)
                [success, varargout{:}] = WTIOUtils.loadFrom(fullPath, '-mat', varargin{:});
            end
        end

        function [fullPath, filePath, fileName] = getStatisticsFile(o, filePrefix, logFlag, timeMin, timeMax, freqMin, freqMax, freqPace, wType)
            dt = datetime();
            dtStr = sprintf('%d%02d%02d.%02d%02d%02d', year(dt), month(dt), day(dt), hour(dt), minute(dt), ceil(second(dt)));
            logStr = WTCodingUtils.ifThenElse(logFlag, '_[log10]_', '_');
            timeStr = WTCodingUtils.ifThenElse(timeMin ~= timeMax, ...
                @()sprintf('[%s,%s]ms', num2str(timeMin), num2str(timeMax)), ...
                @()sprintf('[%s]ms',  num2str(timeMin)));
            freqStr = WTCodingUtils.ifThenElse(freqMin ~= freqMax, ...
                @()WTCodingUtils.ifThenElse(freqPace > 0, ...
                    @()sprintf('[%s,+%s,%s]Hz', num2str(freqMin), num2str(freqPace), num2str(freqMax)), ...
                    @()sprintf('[%s,%s]Hz', num2str(freqMin), num2str(freqMax))), ...
                @()sprintf('[%s]Hz',  num2str(freqMin)));
            fileName =  [filePrefix logStr timeStr '_' freqStr '_bc_' wType '.' dtStr '.tsv'];
            filePath = o.StatisticsDir;
            fullPath = fullfile(filePath, fileName);
        end

        function is = isGrandAvgDir(o, path)
            [analysisDir, grandAvgSubDir] = WTIOUtils.splitPath(path, 1);
            analysisAbsPath = WTIOUtils.getAbsPath(analysisDir);
            is = strcmp(analysisAbsPath, o.AnalysisDir) && ...
                 strcmp(grandAvgSubDir, o.GrandAvgSubDir);
        end

        function subject = getSubjectFromPath(o, path) 
            [analysisDir, subjectSubDir] = WTIOUtils.splitPath(path, 1);
            analysisAbsPath = WTIOUtils.getAbsPath(analysisDir);
            subject = [];
            if ~strcmp(analysisAbsPath, o.AnalysisDir) 
                return
            end
            match = regexp(subjectSubDir, o.SubjAnalysisSubDirRe, 'once', 'names');
            if isempty(match)
                return
            end
            subject = match.subject;
        end

        function subjects = getImportedSubjects(o)
            dirContent = dir(fullfile(o.AnalysisDir, '*'));
            subjects = cell(length(dirContent), 1);
            nValid = 0;

            for i = 1:length(dirContent)
                if ~dirContent(i).isdir
                    continue
                end
                if ~isempty(regexp(dirContent(i).name, o.SubjAnalysisSubDirRe, 'once')) 
                    nValid = nValid + 1;
                    subjects{nValid} = dirContent(i).name;
                end
            end

            subjects = subjects(1:nValid);
        end 
    end
end
