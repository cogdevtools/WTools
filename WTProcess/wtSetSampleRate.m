function success = wtSetSampleRate(system, subjFileName, saveConfig)
    wtProject = WTProject();
    saveConfig = nargin < 3 || any(logical(saveConfig));

    [success, samplingRate] = readSampleRate(system, subjFileName);
    if ~success
        return 
    end

    samplingPrms = copy(wtProject.Config.Sampling);

    if samplingRate > 0
        samplingPrms.SamplingRate = samplingRate;
    elseif ~WTConvertGUI.defineSamplingRate(samplingPrms)
        return
    end
    
    if saveConfig && ~samplingPrms.persist()
        wtProject.notifyErr([], 'Failed to save sampling params');
        return
    end
    
    wtProject.Config.Sampling = samplingPrms;
    success = true;
end

function [success, sampleRate] = readSampleRate(system, subjFileName)
    wtProject = WTProject();
    ioProc = wtProject.Config.IOProc;
    sampleRate = 0.;

    [success, data] = ioProc.loadImport(system, subjFileName);
    if ~success 
        wtProject.notifyErr('Read sample rate', 'Failed to read data file: ''%s''', subjFileName)
        return
    end

    switch system
        case WTIOProcessor.SystemEGI
            if isfield(data, 'samplingRate') % Netstation 4.4.x
                sampleRate = data.samplingRate;
            elseif isfield(data, 'EEGSamplingRate') % Netstation 5.x.x
                sampleRate = data.EEGSamplingRate;
            end
            % if no samplig rate is defined, leave to 0 
        case WTIOProcessor.SystemEEGLab
            sampleRate = data.srate;
        case WTIOProcessor.SystemBRV
            % TODO...
            success = false;
        case WTIOProcessor.SystemEEP
            % TODO...
            success = false;
    end
end