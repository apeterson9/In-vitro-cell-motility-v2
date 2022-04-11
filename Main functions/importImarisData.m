function [rawData, failedReps] = importImarisData(movie_path, dataOrganization, repFiles, rep, expData)
% This function reads data from either csv or xlsx files generated using
% Imaris for cell tracking.
%
% Inputs:
% movie_path: Input as string. Full path to the folder where Imaris Output
% file(s) are stored.
%
% dataOrganization: Input as string. Imaris exports in one of two ways:
% Enter 'individual' if you have one spreadsheet file for each metric (ex.
% Speed, Position etc.). Enter 'compound' if you have a single spreadsheet
% file with metrics on individual sheets within that file.
%
% Outputs:
% Data: cell array
%
%
% ------- BEGIN INPUT CHECKS ---------------------------------------------
movie_path = formatPath(movie_path);
warnNum = 0;
failedReps = [];
errorPath = expData.outputPaths{3};
rawData = [];

if nargin < 2
    error('Not enough input arguments. Please input movie_path and dataOrganization! For more info - type: "help importImarisData" on the command line.')
end

if strcmpi(dataOrganization,'compound') == 0 && strcmpi(dataOrganization,'individual') == 0
    error('Incorrect entry for dataOrganization. Please enter compound or individual enclosed in single quotes.')
end



if ~isempty(repFiles)
    if strcmpi(dataOrganization, 'individual') == 1
        soi = [];
        
        soi(1) = find(contains(repFiles,'Time') == 1,1);
        soi(2) = find(contains(repFiles,'Position') == 1,1);
        soi(3) = find(contains(repFiles,'Speed') == 1,1);
        
        Data = {};
        % NOTE: I noticed that some versions of Matlab are incompatible
        % with the sheetnames and/or readtable functions. Updating this
        % section to be more reliable for various versions of matlab.
        for iS = 1:length(soi)
            fp = [movie_path repFiles{soi(iS)}];
            io = detectImportOptions(fp);
            Data{iS} = readtable(fp,io);
        end % for iS
        
    elseif strcmpi(dataOrganization,'compound') == 1 && length(repFiles) == 1
        % There are some quirks to how compound data is saved in
        % Imaris - mainly that the first row contains the metric
        % label and the second row contains the data headers. This
        % section is written to deal with these cases
        soi = [];
        sheetNames = sheetnames([movie_path repFiles{1}]);
        
        soi(1) = find(contains(sheetNames,'Time') == 1,1);
        soi(2) = find(contains(sheetNames,'Position') == 1,1);
        soi(3) = find(contains(sheetNames,'Speed') == 1,1);
        
        Data = {};
        for iS = 1:length(soi)
            fp = [movie_path repFiles{soi(iS)}];
            io = detectImportOptions(fp);
            Data{iS} = readtable(fp,io);
        end % for iS
    end % if strcmp
    
    % ------------- END IMPORTING DATA ----------------------------------------
    % --------------------- END READING IMARIS DATA  -----------------
    
    % ------------------- CHECK DATA INTEGRITY --------------------
    % Do a couple checks to make sure everything in Imaris files matches as
    % expected 
    % Length Check
    d1 = Data{1}{:,find(strcmp(Data{1}.Properties.VariableNames(:),'ID') == 1)};
    d2 = Data{2}{:,find(strcmp(Data{2}.Properties.VariableNames(:),'ID') == 1)};
    d3 = Data{3}{:,find(strcmp(Data{3}.Properties.VariableNames(:),'ID') == 1)};
    
    l1 = length(d1);
    l2 = length(d2);
    l3 = length(d3);
    
    
    % first try correcting problem
    if l1 ~= l2 ||  l1 ~= l3 || l2 ~= l3 % if all of the lengths match...
        % Try correcting for possibility that some spots were not
        % tracked (only observed transiently) and were ommitted
        % from speed file
        
        % Find empty track IDs in position and time files
        timeIdx = find(isnan(Data{1}{:,find(strcmp(Data{1}.Properties.VariableNames(:),'TrackID') == 1)}));
        posIdx = find(isnan(Data{2}{:,find(strcmp(Data{2}.Properties.VariableNames(:),'TrackID') == 1)}));
        
        if sum(timeIdx == posIdx) == length(timeIdx) && length(timeIdx) == length(posIdx) % if they equal each other
            Data{1}([timeIdx],:) = [];
            Data{2}([posIdx],:) = [];
            
        end
        d1 = Data{1}{:,find(strcmp(Data{1}.Properties.VariableNames(:),'ID') == 1)};
        d2 = Data{2}{:,find(strcmp(Data{2}.Properties.VariableNames(:),'ID') == 1)};
        l1 = length(d1);
        l2 = length(d2);
    end % if lengths
    
    if l1 == l2 & l1 == l3 & l2 == l3 % if all of the lengths match...
        
        % check that row IDs match
        
        a = l1-sum(d1 == d2);
        b = l1-sum(d1 == d3);
        c = l1-sum(d2 == d3);
        
        if a+b+c ~= 0 % if rows are mismatched
            % Make an attempt to match them
            % sort by ID number
            [~, idx] = sortrows(d1,'ascend');
            Data{1} = Data{1}(idx,:);
            clear idx
            
            [~, idx] = sortrows(d2,'ascend');
            Data{2} = Data{2}(idx,:);
            clear idx
            
            [~, idx] = sortrows(d3,'ascend');
            Data{3} = Data{3}(idx,:);
            clear idx
            
        end % if a+b+c
        
        d1 = Data{1}{:,find(strcmp(Data{1}.Properties.VariableNames(:),'ID') == 1)};
        d2 = Data{2}{:,find(strcmp(Data{2}.Properties.VariableNames(:),'ID') == 1)};
        d3 = Data{3}{:,find(strcmp(Data{3}.Properties.VariableNames(:),'ID') == 1)};
        
        a = l1-sum(d1 == d2);
        b = l1-sum(d1 == d3);
        c = l1-sum(d2 == d3);
        
        if a+b+c == 0
            
            clear d1
            clear d2
            clear d3
            clear l1
            clear l2
            clear l3
            clear a
            clear b
            clear c
            
            allData = nan(height(Data{1}),1); % initialize allData
            allDataHeaders = {}; % Initialize cell for headers
            
            
            % -------------- END DATA CHECK -------------------------------
            
            % -------------- ORGANIZE DATA --------------------------------
            % Data 1 - Time
            % Data 2 - Position
            % Data 3 - Speed
            fprintf('\n...Organizing data...\n');
            % Extract ID Component
            for iCol = 1:length(Data{2}.Properties.VariableNames)
                temp(iCol,1) = strcmp(Data{2}.Properties.VariableNames{iCol},'TrackID');
            end
            
            if sum(temp) ~= 0
                
                allData(:,1) = Data{2}{:,find(temp(:,1)>0)}; % ID
                allDataHeaders{1} = 'TrackID';
                clear temp
                
                % Extract Time Component
                for iCol = 1:length(Data{1}.Properties.VariableNames)
                    temp(iCol,1) = strcmp(Data{1}.Properties.VariableNames{iCol},'Time');
                end
                allData(:,end+1) = Data{1}{:,find(temp(:,1)>0)}; % Time
                allDataHeaders{end+1} = 'Time_in_Sec';
                clear temp
                
                % Extract Position Components
                for iCol = 1:length(Data{2}.Properties.VariableNames)
                    temp(iCol,1) = strcmp(Data{2}.Properties.VariableNames{iCol},'PositionX');
                end
                allData(:,end+1) = Data{2}{:,find(temp(:,1)>0)}; % Position X
                allDataHeaders{end+1} = 'PosX';
                clear temp
                
                for iCol = 1:length(Data{2}.Properties.VariableNames)
                    temp(iCol,1) = strcmp(Data{2}.Properties.VariableNames{iCol},'PositionY');
                end
                allData(:,end+1) = Data{2}{:,find(temp(:,1)>0)}; % Position Y
                allDataHeaders{end+1} = 'PosY';
                clear temp
                
                for iCol = 1:length(Data{2}.Properties.VariableNames)
                    temp(iCol,1) = strcmp(Data{2}.Properties.VariableNames{iCol},'PositionZ');
                end
                allData(:,end+1) = Data{2}{:,find(temp(:,1)>0)}; % Position Z
                allDataHeaders{end+1} = 'PosZ';
                clear temp
                
                % Extract Speed Component
                for iCol = 1:length(Data{3}.Properties.VariableNames)
                    temp(iCol,1) = strcmp(Data{3}.Properties.VariableNames{iCol},'Speed');
                end
                allData(:,end+1) = Data{3}{:,find(temp(:,1)>0)}; % Speed in microns per second
                allDataHeaders{end+1} = 'Speed';
                clear temp
                clear Data
                
                % -------------------- END DATA ORGANIZATION -------------------
                
                
                
                % ----------- BEGIN STORING DATA IN STRUCTURE--------------
                % Raw, organized data is stored in a structure called
                % experimentData - one structure is created for each movie
                % (each well in a slide) and saved in that movie's
                % directory
                
                % Create more reasonable cell IDs
                cellIDs = unique(allData(:,1),'stable');
                
                for iCell = 1:length(cellIDs)
                    idx{iCell} = find(allData(:,1) == cellIDs(iCell));
                    allData(idx{iCell},1) = iCell;
                end
                
                allData = array2table(allData,'VariableNames',allDataHeaders);
                
                % Create a lookup table for matching cell IDs between Imaris
                % spreadsheets and IDs assigned above.
                l(:,1) = 1:length(cellIDs);
                l(:,2) = cellIDs;
                
                clear soi
                
                % Store raw data, source, look-up table in structure
                rawData.lookupID = l;
                rawData.ImarisData = allData;
                rawData.DataColumns = allDataHeaders;
                
                clear l
                clear allData
                
                
                % ------------------------ BEGIN HANDLING WARNINGS---------
                % warnings are displayed in the command window and added to
                % an error log text file saved in the master Directory in a
                % folder titled 'Error Logs'
                
            else
                warnNum = warnNum + 1;
                warningMessage = 'WARNING: One or more columns are missing from Imaris file';
                warning(warningMessage)
                fprintf('\n%s: \n',movie_path)
                failedReps = [failedReps; movie_path];
                %dirs{dirIdx(iN),1} = 0;
                
                % Open error log file for appending
                warnID = 'Missing data column in Imaris File'
                fullFileName = strcat('importImarisData - Error_Log_', datestr(date,'yyyy-mm-dd'), '_','.txt');
                fid = fopen([errorPath fullFileName], 'at');
                fprintf(fid, '%i: %s  -- %s -- %s\n',warnNum, warnID, movie_path,rep);
                fclose(fid);
            end % if sum(temp)
            
            
        else % if a+b+c
            warnNum = warnNum + 1;
            warningMessage = 'WARNING: The data rows in the Imaris files do not match! The following will be excluded from the data';
            warning(warningMessage)
            fprintf('\n%s: \n',movie_path)
            failedReps = [failedReps; movie_path];
            %dirs{dirIdx(iN),1} = 0;
            
            % Open error log file for appending
            warnID = 'Mismatched data files'
            fullFileName = strcat('importImarisData - Error_Log_', datestr(date,'yyyy-mm-dd'), '_','.txt');
            fid = fopen([errorPath fullFileName], 'at');
            fprintf(fid, '%i: %s  -- %s -- %s\n',warnNum, warnID, movie_path,rep);
            fclose(fid);
        end % a+b+c
        
    else
        warnNum = warnNum + 1;
        warning('WARNING: The length of Imaris files is inconsistent! The following will be excluded from the data')
        fprintf('\n%s: \n',movie_path)
        failedReps = [failedReps; movie_path];
        %dirs{dirIdx(iN),1} = 0;
        % Open error log file for appending
        
        warnID = 'Mismatched data files'
        fullFileName = strcat('importImarisData - Error_Log_', datestr(date,'yyyy-mm-dd'), '_','.txt');
        fid = fopen([errorPath fullFileName], 'at');
        fprintf(fid, '%i: %s  -- %s -- %s\n',warnNum, warnID, movie_path,rep);
        fclose(fid);
    end % iL
    
else % if ~isempty
    error('Did not detect any Imaris spreadsheets in the specified directory. Please check the path.')
end % ~isempty repFiles
% -------------------- END WARNING HANDLING ------------------------
end % function