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