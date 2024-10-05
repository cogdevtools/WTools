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

function wtSplash() 
    version = WTVersion();
    splash = SplashScreen('WTools', fullfile(WTLayout.getPicturesDir(), 'WToolsSplash.png'));
    splash.BorderColor = 'yellow';
    splash.BorderThickness = 2;
    splash.addText(30, 60, 'WTOOLS', 'FontName', 'Courier', 'FontSize', 20, 'FontAngle', 'italic', 'Color', [0.1 0.5 0.6]);
    splash.addText(30, 80, 'EEGLab extension', 'FontSize', 14, 'Color', 'white');
    splash.addText(240, 345, 'EEG Analysis & Plotting Tools' , 'FontSize', 12, 'Color', 'white');
    splash.addText(240, 357, ['Version ' ... +
        version.getVersionShortStr() ' ' version.getReleaseDateStr() ], 'FontSize', 12, 'Color', 'white')
    splash.addText(240, 369, 'CDC CEU 2003', 'FontSize', 12, 'Color', 'white');
    pause(3);
    delete(splash);
end