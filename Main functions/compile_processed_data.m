function [processedData, expData, L] = compile_processed_data(expData)
% This function assumes that there is a processed data file in each
% directory with tracks, classifications and chemotaxis stats already
% complete


% work to identify pausing:
% start with stats file and extract single-cell data

% ----------------- BEGIN SETUP ----------------------------------------
masterPath = expData.masterPath;
dirs = unique(expData.lut{:,2},'stable');
varPath = expData.outputPaths{1};
expID = expData.ui{1,2}{1};
lut = table2cell(expData.lut);
heads = ["Replicate","Status"];
L = table({''},{''},'VariableNames',heads); clear heads
warnNum = 0;
% Initialize timeStamp for error log
c = clock;
timeStamp = strcat(num2str(c(4)),"_",num2str(c(5)),"_",(num2str(floor(c(6)))));
clear c
fullFileName = strcat('compile_processed_data - Error_Log_', datestr(date,'yyyy-mm-dd'), '_', timeStamp, '.txt');
% ----------------- END SETUP ------------------------------------------

% Modify lut to indicate groups and experimental date
for iLut = 1:length(lut(:,1)) % add a column to lut indicating group name (concatenate cell line and stimulus)
    temp = strcat(lut{iLut,4}, '_', lut{iLut,5});
    %     if strcmp(class(temp),'char') == 1
    %         temp = convertCharsToStrings(temp);
    %     end
    temp = strrep(temp,' ','_');
    lut{iLut,6} = temp;
    L{iLut,1:2} = {strcat(lut{iLut,2},filesep,lut{iLut,3},' : ',temp),'Incomplete'};
    % extract date component from filename
    iDate = lut{iLut,2}(regexp(lut{iLut,2},'20[0-2][0-9]'):regexp(lut{iLut,2},'20[0-2][0-9]')+9);
    lut{iLut,7} = iDate;
    clear temp
end % for iLut

% ID unique groups and experimental dates
Groups = unique(lut(:,6));
groupDate = unique(lut(:,7));
groupDate = strrep(groupDate,'-','_');

% Construct Groups

clear LUT

% Remove any entries associated with errors in previous blocks
findErrors = [];
for iLut = 1:length(lut(:,1))
    lTemp = num2str(lut{iLut,1});
    if strcmp(lTemp,'Error') == 1;
        findErrors = [findErrors; iLut];
    end
    clear lTemp
end


%--------------------- The next section will act on all 'groups' -----

tEnd = 0;

for iGroup = 1:length(Groups)
    
    reps = [];
    reps = find(contains(lut(:,6),Groups{iGroup}));
    
    % Error check - removes any reps that weren't processed due to errors
    if ~isempty(findErrors)
        errorIdx = find(ismember(reps,findErrors));
        reps(errorIdx) = [];
        L{reps,2} = {'Excluded'}
    end
    
    groupName = Groups{iGroup};
    
    % CREATE new LUT (look-up-table)
    for iRep = 1:length(reps)
        % Do a quick check for file matching errors
        if strcmp(groupName, lut{reps(iRep),6}) == 1
            d = lut{reps(iRep),2};
            if d(end) ~= filesep
                d(end+1) = filesep;
            end % d
            
            
            p = getFilenames([masterPath d],'Processed Data');
            if ~isempty(p)
                d = strcat(d,p{end});
                LUT.(groupName){iRep,1} = d;
                LUT.(groupName){iRep,2} = lut{reps(iRep),3};
                
                %date = lut{reps(iRep),2}(regexp(d,'20[1-2][0 1 9]'):(regexp(d,'20[1-2][0 1 9]')+9));
                % I don't remember what date was for so I'm not sure if I want
                % the date data was processed, or the date it was captured
                %                 date = lut{reps(iRep),2}(regexp(lut{reps(iRep),2},'20[1-2][0-9]'):(regexp(d,'20[1-2][0-9]')+9));
                %                 dates{iRep,1} = date;
                LUT.(groupName){iRep,3} = lut{reps(iRep),7};
            else
                fprintf('Warning! One or more processed data files not found\nGroup:%s\nRep:%s\n',Groups{iGroup},lut{reps(iRep),2})
                
            end %~isempty(p)
            
        else
            warnNum = warnNum + 1;
            warnID = 'Group name mismatch! Verify file info'
            fid = fopen([errorPath fullFileName{:}], 'at');
            fprintf(fid, '\n\nStep 7:\n     %i: %s\n%s  -- %s --%s\n',warnNum, warnID, err.getReport('extended', 'hyperlinks','off'), d, lut{reps(iRep),6});
            % close file
            fprintf('%s\n',lut{reps(iRep),6})
            warning('Group name mismatch! Verify file info')
            cont = input('To continue - enter 1\n');
            if cont ~= 1
                return
            else
                fprintf(fid, 'Warning ignored by user... processing continued.\n');
            end
            fclose(fid)
        end
    end % for iRep
    
    
    % ------------------- ORGANIZE PROCESSED DATA STRUCTURE ---------------
    % Still acting at the group level
    % Determine number of experiments performed - according to date labels
    % within group
    exps = unique({LUT.(groupName){:,3}}','stable');
    
    for iExp = 1:length(exps) % for each experimental day
        
        % ID replicates performed on that day
        idx = [];
        for iInd = 1:size(LUT.(groupName),1)
            idx(iInd) = strcmp(exps{iExp},LUT.(groupName){iInd,3});
        end
        
        % ID and format date
        expInd = find(idx == 1);
        dateID = ['Date_' exps{iExp}];
        dateID = strrep(dateID,'-','_');
        dateID = strrep(dateID,' ','');
        
        
        tech = 0;
        for iTech = [expInd] % for each technical replicate
            
            % load stats file
            statFile = LUT.(groupName){iTech,1};
            statPath = [masterPath statFile];
            
            
            
            try
                load(statPath) % load chemotaxisStats
            catch err
                warnNum = warnNum + 1;
                warnID = 'Could not load stats file!'
                fid = fopen([errorPath fullFileName{:}], 'at');
                fprintf(fid, '\n\nStep 7:\n     %i: %s\n%s  -- %s\n',warnNum, warnID, err.getReport('extended', 'hyperlinks','off'), statPath);
                % close file
                fprintf('%s\n',lut{reps(iRep),6})
                L{reps,2} = {'Failed to load processed data'};
                fclose(fid)
            end % try loading stats file
            
            wells = fieldnames(chemotaxisStats); % list of all wells imaged
            well = LUT.(groupName){iTech,2}; % chooses relevant well from look-up table
            
            
            % cross-reference into L
            Lidx = reps(find(contains(L{reps,1},well))); % idxs that match well and group
            fseps = find(statFile == filesep);
            if length(fseps) > 1
                repString = statFile(1:fseps(2));
            else
                repString = statFile(1:fseps);
            end
            repID = Lidx(find(contains(L{Lidx,1},repString)));
            
            try
                if sum(contains(wells,well)) > 0
                    tech = tech+1;
                    sc.(dateID){tech,1} = chemotaxisStats.(well).chemotaxisStats;
                    cm.(dateID){tech,1} = chemotaxisStats.(well).cellMeans;
                    clear data
                    clear cellMeans
                    clear source
                    L{reps,2} = {'Complete'};
                end % if sum
            catch
                warnNum = warnNum+1;
                warning('No processed data file found for:')
                fprintf('%s, %s, %s\n',groupName,dateID,well)
                
                % Annotate L
                L{repID,2} = {'Failed - empty stat file'};
            end % try
            
        end % for iTech
        clear expInd
    end % for iExp
    
    processedData.(groupName).singleCell = sc;
    processedData.(groupName).cellMeans = cm;
    
    clear sc
    clear cm
    clear exps
end % for iGroup

expData.processedDataLUT = LUT;
save([varPath 'processedData'],'processedData');

if warnNum == 0
    expData.statusTracker{7,3} = {'Complete'};
else
    expData.statusTracker{7,3} = {'Completed with errors'};
end

expData.statusTracker{7,4} = warnNum;
save([varPath expID '_expData_' datestr(date,'yyyy-mm-dd') '.mat'],'expData');
save([varPath expID '_replicate_outcomes_' datestr(date,'yyyy-mm-dd') '.mat'],'L');
fprintf('\nProcessed data structure saved in: %s\n',varPath);
expData.statusTracker
L

end % function