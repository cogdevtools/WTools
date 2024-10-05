
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

function success = wtImport(forceCopy)
    success = false;
    forceCopy = nargin > 0 && forceCopy;
    wtProject = WTProject();

    if ~wtProject.checkIsOpen() || ...
        ~wtProject.checkRepeatedImport()
        return
    end

    nCopied = 0;

    if forceCopy || WTEEGLabUtils.eeglabYesNoDlg('Import', 'Would you like to copy new source data files?')
        nCopied = wtCopyImport();
        if nCopied == 0 && ...
            ~WTEEGLabUtils.eeglabYesNoDlg('Import', 'No new files were copied. Continue with the import?')
            return
        end
    end

    if wtProject.checkWaveletAnalysisDone(true)
        if nCopied == 0 && ~WTEEGLabUtils.eeglabYesNoDlg('Import', ...
            'An analysis has been already initiated on the current imported data. Proceed anyway?')
            return
        end 
        if ~WTEEGLabUtils.eeglabYesNoDlg('Import', ...
            ['After data conversion, you MUST repeat the entire analysis. Data will be processed again.\n' ...
             'The parameters used in the previous analysis are saved and can be changed, but MUST be\n' ... 
             'the same for all subjects/conditions you intend to analyze. Continue?'])
            return
        end
    end

    if wtConvertImport() 
        basicPrms = wtProject.Config.Basic;
        basicPrms.ImportDone = 1;
        basicPrms.WaveletAnalysisDone = 0;
        basicPrms.ChopAndBaselineCorrectionDone = 0;
        basicPrms.ConditionsDifferenceDone = 0;
        basicPrms.GrandAverageDone = 0;

        if ~basicPrms.persist()
            wtProject.notifyErr([], 'Failed to save basic configuration params related to the processing status.');
            return
        end
        success = true;
    end
end