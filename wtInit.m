function success = wtInit
    crntDir = pwd();
    dir = fileparts(mfilename('fullpath'));
    cd(fullfile(dir, 'WTCore'));

    try
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