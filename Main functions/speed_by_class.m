function vel_by_class = speed_by_class(scData,cellMeans)
    
% Rename input variables
scOut = scData;
% Find all unique cellIDs (aka TrackID)
cellIDs = unique(cellMeans.cell_ID,'stable');
vbc = [];
for iCell = 1:length(cellIDs) % for every Cell
    trackID = cellIDs(iCell); % Track ID
    cellIdx = find(scOut.cell_ID == trackID); % find rows corresponding to trackID

        % row 11, 12
        iClass = scOut.Class(cellIdx); % track classifications
        iVel = scOut.velocity(cellIdx); % instantaneous velocity
        classes = 1:3; % all possible classes
        vClass = [nan,nan,nan];
        for iC = 1:length(classes)
            classIdx = find(iClass == classes(iC));
            if ~isempty(classIdx)
                vClass(iC) = mean(iVel(classIdx),'omitnan');
            end
        end % for length(classes)
        vbc = [vbc; vClass]; % velocity by class

end

vel_by_class = table(nan,nan,nan,'VariableNames',["mean_vel_confined","mean_vel_free","mean_vel_super"]);
vel_by_class{1:length(cellIDs),:} = vbc;
    
end % function