function rawData = checkImarisOrientation(rawData,expData,movie_path)

reps = fieldnames(rawData(:));
plotRows = 2;
plotCols = ceil(length(reps)/plotRows);


uis = expData.ui{:,1};
pixRow = find(strcmp(uis(:),'Pixel Size') == 1);
pixUnit = expData.ui{pixRow,2}{1};
expRow =  find(strcmp(uis(:),'ID') == 1);
expID = expData.ui{expRow,2}{1};

% Create input arguments for dialog box
group = 'Source_detection';
pref = 'Flip';
Title = 'Check source locations';
quest = {'Flip source orientations?'};
pbtns = {'Yes','No'};

% Create inputs for source plots

subNum = 0;
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

pval = uigetpref(group,pref,Title,quest,pbtns);
%pval = input('Flip source lines? ');
switch pval
case 'yes'
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
saveas(gcf,[movie_path expID '_Source_Locations_' datestr(date,'yyyy-mm-dd')],'png');
close(gcf)
end % function