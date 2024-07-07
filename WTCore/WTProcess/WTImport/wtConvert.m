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

function success = wtConvert()
    success = false;
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;

    if ~wtProject.checkIsOpen()
        return
    end

    if ioProc.countImportFiles() == 0 
        wtProject.notifyWrn([], 'There are no imported files yet in this project');
        return
    end

    basicPrms = copy(wtProject.Config.Basic); 
    importTypePrms = copy(wtProject.Config.ImportType);

    if ~WTConvertGUI.selectImportType(importTypePrms, basicPrms, true)
        return
    end

    if ~importTypePrms.persist()
        wtProject.notifyErr([], 'Failed to save convert to EEGLAB params');
        return
    end

    wtProject.Config.ImportType = importTypePrms;

    if importTypePrms.EEPFlag 
        success = wtEEPToEEGLab();
    elseif importTypePrms.EGIFlag 
        success = wtEGIToEEGLab();
    elseif importTypePrms.BRVFlag 
        success = wtBRVToEEGLab();
    elseif importTypePrms.EEGLabFlag 
        success = wtEEGLabToEEGLab();
    end
end