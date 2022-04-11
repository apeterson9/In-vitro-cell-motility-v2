function pauseData = quantify_pauses(allData)

% This function assumes that you have already compiled and processed the
% data

warnNum = 0;
scData = allData;
cellIDs = unique(scData(:,1),'stable');

% Pull out ct axis length, segment class and confinement radius
for iCell = 1:length(cellIDs)
    cellIdx = find(scData(:,1) == cellIDs(iCell));
    pauseData(iCell,1) = cellIDs(iCell);
    if length(cellIdx) > 10 % arbitrary track length to exclude short tracks
        temp = scData(cellIdx,:);
        % first I must calculate the distance gained for each
        % step
        % Defining pause as 1 or more consecutive steps with a
        % value of <1
        for iStep = 2:size(temp,1)
            d(iStep) = pdist([temp(iStep,3),temp(iStep,4);temp(iStep-1,3),temp(iStep-1,4)]) <1; % euclidean distance
        end % for iStep
        
        % from here, I calculate the number of pauses
        p = find(d == 1);
        
        [n r] = findConsecutiveNums(p);
        
        if ~isempty(r)
            r2 = r(:,2)-r(:,1);
            r = r(r2>0,:);
            
            numPause = size(r,1)/length(cellIdx); % number of pauses normalized by track length
            duration = nanmean(r(:,2)-r(:,1));    % average duration of pauses for cell
        else
            numPause = 0;
            duration = nan;
        end
       
        pauseData(iCell,2) = numPause;
        pauseData(iCell,3) = duration;
        
        clear numPause
        clear duration
        clear d
        clear p
        clear r
        clear r2
    else
        pauseData(iCell,2) = nan;
        pauseData(iCell,3) = nan;
    end % if length
end % for iCell
end % function
    
