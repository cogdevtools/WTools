function [enable_uV, varargout] = check_evok_log(sla, PROJECTPATH)

%check_evok_log.m
%Created by Eugenio Parise
%CDC CEU 2012

%Load previously called parameters from tf_cmor and baseline_chop (to set uV)
enable_uV='on';
tf_pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'tf_cmor_cfg.m');
bs_pop_cfgfile = strcat(PROJECTPATH,sla,'pop_cfg',sla,'baseline_chop_cfg.m');

%Initialize varargout
varargout={ 0 0 0 0 };

if exist(tf_pop_cfgfile,'file')
    
    tf_cmor_cfg;
    
    %GET log value before averaging
    if length(defaultanswer)>=10
        varargout{1}=defaultanswer{1,10};
    else
        varargout{1}=0;
    end
    
    %GET evok value after wavelet transform
    if length(defaultanswer)>11
        varargout{2}=defaultanswer{1,end-1};
    elseif length(defaultanswer)>10
        varargout{2}=defaultanswer{1,end};
    else
        varargout{2}=0
    end

end

if exist(bs_pop_cfgfile,'file')
    
    baseline_chop_cfg;
    
    %CHECK whether baseline_chop.m is the caller
    try
        isbaseline_chop = evalin('caller','baseline_chop_flag');
    catch
        isbaseline_chop = 0;
    end
    
    if ~isbaseline_chop
        %GET log value after averaging
        if length(defaultanswer)>=7
            varargout{1}=varargout{1} || defaultanswer{1,5};
        end
    end
    
    %GET evok value after baseline correction
    varargout{3}=defaultanswer{1,end};
    
    %GET log value after averaging
    varargout{4}=defaultanswer{1,5};
    
end

%Set Log checkbox on or off (default on)
if varargout{1}
    enable_uV='off';
end