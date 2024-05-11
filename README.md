
# WTools
WTools is a Matlab® based toolbox & EEGLab plugin for wavelet based time-frequency analysis.
It provides also a variety of plotting and data export utilities.

## Dependencies
WTools requires [EEGLab](https://eeglab.org) to be installed. 

## Installation
WTools can be used as a standalone application or can be copied in the plugins directory
of EEGLab from which it will be then available under [Tools]->[WTools (wavelet analysis)].

## Execution as standalone application
From the Matlab®'s Command Window, change directory to the WTools project and run 'wtools'.
Typing 'wtools help' will display the following information:

> WTools v2.0.0 - December 2023
>
> Usage: wtools [ no-splash | configure | close | help ]
>
>        no-splash : do not display splash screen on start
>                    (when the relative configuration option is enabled)
>        configure : configure the application
>        close     : force close the application
>        help      : display this help

## Documentation
A tutorial is available on this [page](https://github.com/cogdevtools/WTools/wiki/WTools-tutorial).

## Project Structure
+ WTCore: core wtools modules
  + WTConfiguration: project configuration management
  + WTGraphicUI: GUI management (dialogs)
  + WTProcess: data processing
    + WTImport: data import
    + WTPlots: data plot
    + WTProject: project management (new, open)
    + WTSignalsProcessing: specific signal processing
    + WTStatistics: statistc reports
    + WTSubjectsManager: subjects management
  + WTStorageManager: global storage manager
  + WTBasicUtilities: general utilities
+ WTExternal: external (3rd party) code
  + WTModified: code that have been improved
  + WTOriginal: non modified code
+ WTResources: general project resources
  + WTDevices: data specific to the various measurement devices
  + WTPictures: picture files (used for example in the splash screen) 
+ WTSplash: splash screen module   
