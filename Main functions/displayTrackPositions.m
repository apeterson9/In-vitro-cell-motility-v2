       
function fh = displayTrackPositions()

for iRep = 1:length(reps)
    subNum = subNum+1;
    rep = reps{iRep};
    x = rawData.(rep).ImarisData{:,3};
    y = rawData.(rep).ImarisData{:,4};
    subplot(plotRows,plotCols,subNum)
    scatter(x,y);
    title(num2str(subNum))
    hold on
    %source = [520 200; 520 500]*pixUnit; % right side (for fish)
    source = [200 1; 500 1]*pixUnit; % bottom (in vitro)
    line([source(1,1) source(2,1)],[source(1,2), source(2,2)],'Color','g','LineWidth',3);
    rawData.(rep).source = source;
    clear x
    clear y
    hold off
end

pval = uigetpref(group,pref,title,quest,pbtns);
pval = input('Flip source lines? ');
switch pval
case 'Yes'
    invertNums = input('Enter vector of numbers corresponding to inverted wells: ');
    %source = [1 200; 1 500]*pixUnit; % right side (fish)
    for iI = [invertNums]
        rep = reps{iI};
        subplot(plotRows,plotCols,iI)
        source = [200 520; 500 520]*pixUnit; % bottom side(in vitro)
        line([source(1,1) source(2,1)],[source(1,2), source(2,2)],'Color','r','LineWidth',3);
        rawData.(rep).source = source;
    end % for iI
    case 'No'   
end

end 