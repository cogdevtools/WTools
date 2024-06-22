function [success, pathsContext] = wtInit
    warning('off', 'all');
    success = true;
    crntDir = pwd();
    pathsContext = [];

    try
        wtoolsRootDir = fileparts(mfilename('fullpath'));
        pathsContext = path();
        addpath(genpath(wtoolsRootDir));
        rehash();
    catch me
        try
            wtLog = WTLog();
            wtLog.except(me);
            wtLog.info('WTools bailed out due to internal error...');
        catch
            display(getReport(me, 'extended'));
            fprintf(2, ['\n+------------------------------------------+\n' ...
                          '|WTools bailed out due to internal error...|\n' ...
                          '+------------------------------------------+\n']);
        end
        if ~isempty(pathsContext)
            path(pathsContext);
            rehash();
        end
        success = false;
    end

    cd(crntDir);
end