
# WTools
WTools is a Matlab® based toolbox & EEGLab plugin for wavelet based time-frequency analysis.
It provides also a variety of plotting and data export utilities.

## Dependencies
WTools requires [EEGLab 2019](https://eeglab.org) to be installed. 

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

## Differences with the former [version](https://github.com/cogdevtools/WTools)
WTools version 2.0 is the result of a major refactoring of the original version, an attempt to clean the code, to give it some structure and fix inconsistencies.
Unfortunately, it was not possible to ensure backward compatibility of the new version with the old one. Many things have changed although some effort has been put to minimize the differences. Here's a brief list of what's to be aware of:
+ The structure of a WTools project has a completely new layout, so old projects cannot be opened with the Wtools 2.0.
+ The configuration files of a project have kept the same name and structure (till some extent): there are some new files and some old ones stores more parameters.
+ Old projects can be converted to new ones manually (there's not yet a utility for that, sorry), but it is a delicate procedure which requires to fix both configuration and data files, besides moving them to the proper directories. It's therefore strongly advisable to re-create a project from scratch rather then try to convert it. If you still want to perform a conversion/upgrade, we can provide further details.

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

## Future
WTools can be certainly improved:
+ The processing flow (import, wavelet transform, baseline & chopping etc.) is somewhat bound to be carried out once only to avoid possible errors. In fact, WTools doesn't keep track of all the parameters that produce intermediate or final data, so if by any chance those parameters are changed inconsistently across repeated processing (meaning for some data, but not for other), that will generate incompatibilities (i.e. results that cannot be used together in the same plottings or statistics). 
+ Currently a WTools project configuration is made of multiple matlab files, whose name and content could be better defined. That's a legacy from the old tools version which should be replaced with a single well structured configuration file.

## Reference
Please cite the reference paper when you have used WTools in your study.

Ferrari A, Filippin L, Buiatti M, Parise E. (2024) **WTools: a MATLAB-based toolbox for time-frequency analysis**. *bioRxiv*.
