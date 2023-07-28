function changefontsize(FigureType, newvalue)
%changefontsize.m
%Created by Eugenio Parise
%CDC CEU 2011
%Auxiliary function for plotting (it changes the font size).

if strcmp(FigureType,'ERP')
    %Uncomment below to change legend labels and position
    %legend('Freq','Infreq','Location', [0.64 0.82 0.2 0.05]);
    set(gca,'FontSize',newvalue);
    xlabel('Time (ms)','FontSize',newvalue);
    ylabel('Potential (\muV)','FontSize',newvalue);
elseif strcmp(FigureType,'TF')
    set(gca,'FontSize',newvalue);
    xlabel('Time (ms)','FontSize',newvalue);
    ylabel('Frequency (Hz)','FontSize',newvalue);
else
    fprintf('Plese, enter ''ERP'' or ''TF'' as Figure Type! \n');
    fprintf('Try again!\n');
    return
end

end