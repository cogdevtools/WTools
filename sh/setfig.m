function [DEFAULT_COLORMAP, clabel, Rotation, xclabel] = setfig(enable_uV)
%setfig.m
%Created by Eugenio Parise
%CDC CEU 2011
%Auxiliary function for plotting.

%take info from icadefs.m
icadefs;
DEFAULT_COLORMAP;
VERS;

%for older version of EEGLAB with no info in icadefs.m
if ~exist('DEFAULT_COLORMAP','var') || ~exist('VERS','var')    
    DEFAULT_COLORMAP = 'jet';    
    vers = version;
    indp = find(vers == '.');
    if str2num(vers(indp(1)+1)) > 1, vers = [ vers(1:indp(1)) '0' vers(indp(1)+1:end) ]; end
    indp = find(vers == '.');
    VERS = str2num(vers(1:indp(2)-1));    
end

if strcmp(enable_uV,'on')
    clabel = '\muV';
    Rotation = 0;
else
    clabel = '% change';
    Rotation = 90;
end

if VERS < 8.04
    xclabel = 5;
else
    xclabel = 2;
end
    
end