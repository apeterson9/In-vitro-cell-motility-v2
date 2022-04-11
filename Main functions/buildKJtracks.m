function tracksKJ = buildKJtracks(allData)

numFrames = length(unique(allData(:,2)));
cellIDs = unique(allData(:,1),'stable');
tracksKJ = [];

for iCell = 1:length(cellIDs)
    cellID = cellIDs(iCell);
    idx = find(allData(:,1) == cellID);
    track_i = nan(numFrames,2);
    track_i(1:length(idx),1:2) = allData(idx,3:4);
    frame = 1;
    track = zeros(1,numFrames*8);
        for iStep = 1:numFrames%length(track_i(:,1))
            % Construct Row
            if iStep <= length(track_i(:,1))
                track(1,frame:frame+1) = track_i(iStep,1:2);
            else
                track(1,frame:frame+1) = [nan nan];
            end
            frame = frame+8;
        end % for iStep
        tracksKJ = [tracksKJ;track];
        clear track
end % for iCell

end % function