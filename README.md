# WTools
A Matlab® based toolbox & an EEGLab plugin for time-frequency analysis

## Structure
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
  + WTStorage: global storage manager
  + WTUtilities: general and less general utilities
+ WTExternal: external (3rd party) code
  + Modified: code that have been improved
  + Original: non modified code
+ WTResources: general project resources
  + WTDevices: data specific to the various measurement devices
  + WTPictures: picture files (used for example in the splash screen) 
+ WTSplash: splash screen module   
