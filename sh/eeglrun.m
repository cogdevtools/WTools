function run = eeglrun() 
    if ~exist('inputgui.m','file')    
        warning('wtools requires EEGLAB to be running');
        return false
    end
    return true
end