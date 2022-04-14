function expData = export_for_R(expData, processedData)

prerequisiteCheck(expData,7)

% ----------------- BEGIN SETUP ----------------------------------------
masterPath = expData.masterPath;
dirs = unique(expData.lut{:,2},'stable');
varPath = expData.outputPaths{1};
expID = expData.ui{1,2}{1};
warnNum = 0;
Groups = fieldnames(processedData);
tEnd = 0;
dates = {};
stats = processedData;
LUT = expData.processedDataLUT;
heads = ["day","slide","position","cell_line","stimulus","id","track_length",...
    "cumul_distance","net_displacement","tortuosity","mean_velocity",...
    "mean_theta","mean_CI","num_pauses","pause_duration","confinement_radius",...
    "confined_vel","free_vel","super_vel"];

T = table(nan,nan,{'pos'},{'cellLine'},{'stim'},nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,'VariableNames',heads);

warning('off','MATLAB:table:RowsAddedExistingVars')

% ----------------- END SETUP ------------------------------------------

for iGroup = 1:length(Groups) % for every Group
    
    % Identify stimulus
    cellLine = {Groups{iGroup}(1:regexp(Groups{iGroup},'_')-1)};
    stimulus = {Groups{iGroup}(regexp(Groups{iGroup},'_')+1:end)};
    
    % Identify number of days for group
    days = fieldnames(stats.(Groups{iGroup}).cellMeans);
    
    for iDay = 1:length(days)
        day = days{iDay}(regexp(days{iDay},'20[1-2][0-9]'):end);
        if sum(contains(dates,day) == 1) == 0
            dates{length(dates)+1,1} = day;
        end
    end % for iDay
    
    numDays = length(days);
    counter = 0;
    
    for iDir = 1:numDays% for every replicate
        
        % ID day for current experiment
        day =  find(strcmp(dates(:),days{iDir}(regexp(days{iDir},'20[0-9]'):end)) == 1);
        
        for iSlide = 1:length(stats.(Groups{iGroup}).cellMeans.(days{iDir}))
            counter = counter+1;
            % ID slide
            slide = iSlide;
            % Determine positions
            position = LUT.(Groups{iGroup})(iSlide,2);
            
            % Add some data from single-cell data
            scData = processedData.(Groups{iGroup}).singleCell.(days{iDir}){iSlide};
            if ~isempty(scData)
            
            cellIDs = unique(scData.cell_ID,'stable');
            T{tEnd+length(cellIDs),1} = nan;
            % cellMeans structure
            data = processedData.(Groups{iGroup}).cellMeans.(days{iDir}){iSlide};
            cellIDs = unique(data.cell_ID,'stable');
            
            for iCell = 1:length(cellIDs)
    
                cellIdx = find(scData.cell_ID == cellIDs(iCell));
                track_i = scData(cellIdx,:);
                id = cellIDs(iCell);
                meanCellDat = data(find(data.cell_ID == id),:);
                
                T{tEnd+iCell,1} = day;
                T{tEnd+iCell,2}  = slide;
                T{tEnd+iCell,3}  = position;
                T{tEnd+iCell,4}  = cellLine;
                T{tEnd+iCell,5}  = stimulus;
                T{tEnd+iCell,6}  = id;
                T{tEnd+iCell,7}  = meanCellDat.track_length;
                T{tEnd+iCell,8}  = meanCellDat.cumul_distance;
                T{tEnd+iCell,9}  = meanCellDat.net_displacement;
                T{tEnd+iCell,10}  = meanCellDat.tortuosity;
                T{tEnd+iCell,11}  = meanCellDat.mean_velocity;
                T{tEnd+iCell,12}  = meanCellDat.mean_theta;
                T{tEnd+iCell,13}  = meanCellDat.mean_CI;
                T{tEnd+iCell,14}  = meanCellDat.num_pauses;
                T{tEnd+iCell,15}  = meanCellDat.duration;
                T{tEnd+iCell,16}  = mean(track_i.confinement_radius, 'omitnan');
                T{tEnd+iCell,17}  = meanCellDat.mean_vel_confined;
                T{tEnd+iCell,18}  = meanCellDat.mean_vel_free;
                T{tEnd+iCell,19}  = meanCellDat.mean_vel_super;

            end % for iCell
            
            clear data
            clear scData
            clear cellIDs
            clear chemotaxisStats
            
            tEnd = tEnd+iCell;
            else
            end
        end % for iSlide
        
    end % for iDir
end % for iGroup

writetable(T,[varPath expID '_formatted4R.csv']);

% Save processed stats data

if varPath(end)~=filesep
    varPath(end+1) = filesep;
end % if masterPath

expData.statusTracker{8,4} = warnNum;
expData.statusTracker{8,3} = {'Complete'};

expData.R = T;
save([varPath 'expData_Final'],'expData')
expData.statusTracker
end % function