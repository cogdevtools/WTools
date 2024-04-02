function success = wtInit
    warning('off', 'all');
    crntDir = pwd();
    
    try
        thisFileDir = fileparts(mfilename('fullpath'));
        cd(fullfile(thisFileDir, 'WTCore'));
        WTSession().open();
        success = true;
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
        success = false;
    end
    cd(crntDir);
end