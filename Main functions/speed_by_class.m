function vel_by_class = speed_by_class(scData,cellMeans)
    
% Rename input variables
scOut = scData;
% Find all unique cellIDs (aka TrackID)
cellIDs = unique(cellMeans.cell_ID,'stable');
vbc = [];
for iCell = 1:length(cellIDs) % for every Cell
    trackID = cellIDs(iCell); % Track ID
    cellIdx = find(scOut.TrackID == trackID); % find rows corresponding to trackID

        
        % row 11, 12
        iClass = scOut.velocity(cellIdx); % track classifications
        iVel = scOut.Class(cellIdx); % instantaneous velocity
        classes = 0:3; % all possible classes
        vClass = [nan,nan,nan,nan];
        for iC = 1:length(classes)
            classIdx = find(iClass == classes(iC));
            if ~isempty(classIdx)
                vClass(iC) = nanmean(iVel(classIdx));
            end
        end % for length(classes)
        vbc = [vbc; vClass];

end
vel_by_class = table(nan,nan,nan,nan,'VariableNames',["mean_vel_UC","mean_vel_confined","mean_vel_free","mean_vel_super"]);
vel_by_class{1:length(cellIDs),:} = vbc;
    
end % function