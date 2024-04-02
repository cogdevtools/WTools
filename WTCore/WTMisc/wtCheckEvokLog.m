% wtCheckEvokLog.m
% Created by Eugenio Parise
% CDC CEU 2012

function [log, wtEvok, bsEvok, bsLog] = wtCheckEvokLog()
    wtProject = WTProject();
    
    log = 0;
    wtEvok = 0;
    bsEvok = 0; 
    bsLog= 0;

    if ~wtProject.checkIsOpen() 
        return
    end

    waveletTransformParams = wtProject.Config.WaveletTransform;
    baselineChopParams = wtProject.Config.BaselineChop;

    if waveletTransformParams.exist()
        log = waveletTransformParams.LogarithmicTransform;
        wtEvok = waveletTransformParams.EvokedOscillations;
    end
    
    if baselineChopParams.exist()
        % Get evok value after baseline correction
        bsEvok = baselineChopParams.EvokedOscillations;
        % Get log value after averaging
        bsLog = baselineChopParams.Log10Enable;
        log = log || bsLog;
    end
end