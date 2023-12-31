% wtChangeFontSize.m
% Created by Eugenio Parise
% CDC CEU 2011
% Auxiliary function for plotting (it changes the font size).

function wtChangeFontSize(figureType, newFontSize)
    if strcmp(figureType,'ERP')
        % Uncomment below to change legend labels and position
        % legend('Freq','Infreq','Location', [0.64 0.82 0.2 0.05]);
        set(gca,'FontSize',newFontSize);
        xlabel('Time (ms)','FontSize',newFontSize);
        ylabel('Potential (\muV)','FontSize',newFontSize);
    elseif strcmp(figureType,'TF')
        set(gca,'FontSize',newFontSize);
        xlabel('Time (ms)','FontSize',newFontSize);
        ylabel('Frequency (Hz)','FontSize',newFontSize);
    else
        WTLog().err('Unknown figure type ''%s'': select either ''ERP'' or ''TF''', figureType);
    end
end