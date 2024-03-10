% wtSetFigure.m
% Created by Eugenio Parise
% CDC CEU 2011
% Auxiliary function for plotting.

function [DEFAULT_COLORMAP, cLabel, rotation, xcLabel] = wtSetFigure(logFlag)
    % icadefs is an eeglab module, but can be copied locally, so here we just
    % call it assuming that either there's a local copy in WTools or eeglab is
    % in the matlab paths, as it should be if the tools have been correctly 
    % initialised
    icadefs;

    % For older version of EEGLAB with no info in icadefs.m
    if ~exist('DEFAULT_COLORMAP', 'var') 
        DEFAULT_COLORMAP = 'jet'; 
    end

    if ~exist('VERS', 'var')    
        vers = version;
        indp = find(vers == '.');
        if WTUtils.str2double(vers(indp(1)+1)) > 1 
            vers = [ vers(1:indp(1)) '0' vers(indp(1)+1:end) ]; 
        end
        indp = find(vers == '.');
        VERS = WTUtils.str2double(vers(1:indp(2)-1));    
    end

    if ~logFlag
        cLabel = '\muV';
        rotation = 0;
    else
        cLabel = '% change';
        rotation = 90;
    end

    if VERS < 8.04
        xcLabel = 5;
    else
        xcLabel = 2;
    end
end