% wtCheckEvokLog.m
% Created by Eugenio Parise
% CDC CEU 2012

function [uV, varargout] = wtCheckEvokLog(caller_is_baseline_chop)
    wtProject = WTProject();

    if ~wtProject.checkIsOpen() 
        return
    end

    % Load previously called parameters from wtPerformCWT and baseline_chop (to set uV)
    uV = 'on';
    % Initialize varargout
    varargout = { 0 0 0 0 };

    waveletTransformData = wtProject.Config.WaveletTransform;
    baselineChopData = wtProject.Config.BaselineChop;

    varargout{1} = waveletTransformData.LogarithmicTransform;
    varargout{2} = waveletTransformData.EvokedOscillations;
            
    % CHECK whether baseline_chop.m is the caller
    if nargin > 1 && ~caller_is_baseline_chop
        %GET log value after averaging
        varargout{1} = varargout{1} || baselineChopData.Log10Enable;
    end
    
    % GET evok value after baseline correction
    varargout{3} = baselineChopData.EvokedOscillations;

    % GET log value after averaging
    varargout{4} = baselineChopData.Log10Enable;

    % Set Log checkbox on or off (default on)
    if varargout{1}
        uV = 'off';
    end
end