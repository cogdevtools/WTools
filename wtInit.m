function success = wtInit
    try 
        WTSession();
        success = true;
        return
    catch
    end

    crntDir = pwd();
    dir = fileparts(mfilename('fullpath'));
    cd(fullfile(dir, 'WTCore'));
    
    try
        WTSession().open();
        success = true;
    catch me
        display(getReport(me, 'extended'));
        success = false;
    end
    cd(crntDir);
end