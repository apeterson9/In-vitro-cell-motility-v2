function expData = analyzeImarisData(expData)

% This function completes steps 4-6
%         4: 'Measure CI'
%         5: 'Classify Tracks'
%         6: 'Quantify velocity by class'


% Pre-requisite check
% Prior to this step, user inputs and rawData files should all be saved
% This function picks up at Step 4
prerequisiteCheck(expData,[1:3])

% Initialize timeStamp for error log
c = clock;
timeStamp = strcat(num2str(c(4)),"_",num2str(c(5)),"_",(num2str(floor(c(6)))));
clear c

% Setup of pre-requisite variables
fullFileName = strcat('analyzeImarisData - Error_Log_', datestr(date,'yyyy-mm-dd'), '_', timeStamp, '.txt');
warnNum4 = 0; % Measure CI
warnNum5 = 0; % Classify tracks
warnNum6 = 0; % velocity by speed

expData.statusTracker{4,3} = {'Incomplete'};        expData.statusTracker{4,4} = 0;
expData.statusTracker{5,3} = {'Incomplete'};        expData.statusTracker{5,4} = 0;
expData.statusTracker{6,3} = {'Incomplete'};        expData.statusTracker{6,4} = 0;

lut = expData.lut;
if strcmp(class(lut),'cell') == 0
    lut = table2cell(lut);
end

dirs = unique(lut(:,2));
masterPath = expData.masterPath;
graphPath = expData.outputPaths{2};
errorPath = expData.outputPaths{3};
varPath = expData.outputPaths{1};
cCode = [0,0,1;0,1,1;1,0,1];



uis = expData.ui{:,1};
expRow =  find(strcmp(uis(:),'ID') == 1);
expID = expData.ui{expRow,2}{1};

% ---------------------- BEGIN PROCESSING STEPS -----------------------

for iDir = 1:length(dirs) % For each directory (movie)
    
    % Setup
    dirIdx = [];
    dirIdx = find(contains(lut(:,2),dirs{iDir})); % Index rows from look-up-table (lut)
    reps = []; % ensure reps is cleared
    reps = unique(lut(dirIdx,3),'stable'); % Stores position name
    movie_path = [masterPath dirs{iDir}]; % stores path to Imaris files
    movie_path = formatPath(movie_path);
    
    repID = dirs{iDir}(regexp(dirs{iDir},'20[1-2][0-9]'):end);
    repID = strrep(repID,filesep,'_');
    
    % Inform user of progress
    fprintf('\nExperiment %i of %i...\n',iDir, length(dirs));
    
    % Load raw data from current movie
    expFile = getFilenames([movie_path],'Raw_Data'); % Load in raw data file for particular directory
    
    if ~isempty(expFile) % Make sure data isn't missing
        % If the folder contains more than one experiment file, use the most recent one
        if length(expFile)>1
            expFile = expFile{end};
        else
            expFile = expFile{1};
        end % if length
        
        load([movie_path expFile]); % load raw data file
        fields = fieldnames(rawData); % correspond to wells captured
        
        % ---------------------- TRACK CLASSIFICATION SETUP -----------
        % Automatically allocate the subplot size
        
        %fh = figure;
        tiledlayout('flow')
        %set(fh,'Units','inches','Position',[0 0 8 11]); % paper size            
         
        num = 0;
        
        % ------------------- END FIGURE SETUP ------------------------
        % ------------------- BEGIN WELL-LEVEL PROCESSING -------------
        for iWell = 1:length(fields) % for every well
            try
                nexttile %call nexttile ONLY before we switch to a new well
                num = num+1; % keeps track of subplot number
                clear frames
                rep = fields{iWell}; % well
                % Update user on progress
                fprintf('Processing movie %i of %i: %s...\n',num,length(fields),rep)
                
                % ----------------------LOAD IMAGE SEQUENCE-----------------------
                
                if strcmp(class(rawData.(rep).source), 'double')  == 1
                    source =  rawData.(rep).source;
                elseif strcmp(class(rawData.(rep).source), 'cell')  == 1
                    source = rawData.(rep).source{1};
                end
                
                allData = rawData.(rep).ImarisData;
                
                % Test for and handle cases where Imaris has added tracks out of order
                % at end (likely from filling in data? Don't always map appropriately
                % to track)
                
                tPoints = unique(allData(:,2),'stable');
                tMax = max(tPoints{:,1});
                
                if allData{end,2}~=tMax
                    tIdx = find(allData{:,2} == tMax);
                    t = [];
                    for iT = 2:length(tIdx)
                        t(iT-1) = tIdx(iT)-tIdx(iT-1);
                    end
                    if sum(t) == length(tIdx)-1
                        stop = tIdx(end);
                    else
                        stop = find(t~=1,1)-1;
                    end % if sum
                    allData = allData(1:stop,:);
                end %
                
                
               % ----------------- BEGIN CALCULATE CI ------------------- 
                
                % Perform CI, angle, distance etc. calculations
                try
                    min_track_length = expData.ui{find(strcmp(expData.ui{:,1},'Min Track Length') == 1),2}{1};
                    [cellMeans, scData] = calculate_CI_in_vitro(allData,source,min_track_length);
                    
                    scData = [allData, scData];
                    allData = allData{:,:};
                catch err
                    warnNum4 = warnNum4 + 1;
                    warnID = 'Error occurred while calculating chemotaxis stats'
                    fid = fopen([errorPath fullFileName{:}], 'at');
                    if exist('err') ~= 0
                    fprintf(fid, '\n\nStep 4:\n     %i: %s\n%s  -- %s --%s\n',warnNum4, warnID, err.getReport('extended', 'hyperlinks','off'), movie_path,rep);
                    else
                                            fprintf(fid, '\n\nStep 4:\n     %i: %s\n%s  -- %s --%s\n',warnNum4, warnID, movie_path,rep);

                    end %if exist('err')
                    % close file
                    fclose(fid);
                end
                
                if iWell == length(fields) && warnNum4 == 0
                    % Status update - step 4
                    expData.statusTracker{4,3} = {'Complete'};
                    expData.statusTracker{4,4} = warnNum4;
                elseif iWell == length(fields) && warnNum4 > 0 
                    expData.statusTracker{4,3} = {'Completed with errors'};
                    expData.statusTracker{4,4} = warnNum4;
                end % if iWell
                % --------------------- END CALCULATE CI-------------------
                
                
                % -------------- BEGIN SEGMENT CLASSIFICATION -------------
                % This section utilizes code from the Jaqaman lab
                % Vega et al., Biophys. J. 2018. 
                % Multistep Track Segmentation and Motion Classification for Transient Mobility Analysis. 
                % https://pubmed.ncbi.nlm.nih.gov/29539390/.
                try
                    
                    cellIDs = unique(allData(:,1),'stable');
                    tracksKJ = buildKJtracks(allData); % prepare tracks for input into function
                    
                    % Perform classification
                    [transDiffAnalysisRes,errFlag] = basicTransientDiffusionAnalysisv1(tracksKJ,2,0,[]);
                 

                    classes = table(nan,nan,nan,'VariableNames',["Class","diff_coeff","confinement_radius"]);
                    trackCounter = 0;
                    hold on
                    
                    for iCell = 1:length(cellIDs) % for every cell
                        idx = find(allData(:,1) == cellIDs(iCell)); % pull track info
                        track_i = allData(idx,:);
                        class_out = nan(size(track_i,1), 3); % pre-allocating
                        if length(track_i(:,1)) > min_track_length % arbitrarily set to exclude shorter track fragments from visualization
                            
                            trackCounter = trackCounter+1;
                            cellClass = transDiffAnalysisRes(trackCounter).segmentClass.momentScalingSpectrum;
                            numClasses = length(cellClass(:,1));
                            
                            
                            plot(track_i(:,3),track_i(:,4),'k'); % track initially plotted in black
                            hold on
                            
                            % overlay color-coding according to motion type
                            % where blue is confined, cyan is free, magenta
                            % is super and black is unclassified
                            
                            for iClass = 1:numClasses
                                startFrame = cellClass(iClass,1);
                                endFrame = cellClass(iClass,2);
                                if endFrame>length(idx)
                                    endFrame = length(idx);
                                end
                                class_out(startFrame:endFrame,1) = cellClass(iClass,3);
                                class_out(startFrame:endFrame,2) = cellClass(iClass,19);
                                class_out(startFrame:endFrame,3) = cellClass(iClass,20);
                                if cellClass(iClass,3)>0
                                    try
                                    
                                    plot(track_i(startFrame:endFrame,3),track_i(startFrame:endFrame,4),...
                                        'Color',cCode(cellClass(iClass,3),:));
                                    title(rep)
                                    catch
                                        warning('Work-in-progress to expand subplot sizes... not all wells plotted')
                                    end
                                end
                            end % for iClass
                        else % if length
                        end % if length
                        classes{idx,1:3} = class_out;
                        clear track_i, clear class_out
                    end % for iCell
                    scData = [scData, classes];
                    hold off
                    
                    if iWell == length(fields) && warnNum5 == 0
                        % Status update - Step 5
                        expData.statusTracker{5,3} = {'Complete'};
                        expData.statusTracker{5,4} = warnNum5;
                    elseif iWell == length(fields) && warnNum5 > 0
                        expData.statusTracker{5,3} = {'Completed with errors'};
                        expData.statusTracker{5,4} = warnNum5;
                    end
                    
                catch err % KJ Segment
                    
                    warnNum5 = warnNum5 + 1;
                    warnID ='Error occurred during motiity classifiction. No classifications were stored'
                    fid = fopen([errorPath fullFileName{:}], 'at');
                    fprintf(fid, '\n\nStep 5:\n     %i: %s\n%s  -- %s --%s\n',warnNum5, warnID, err.getReport('extended', 'hyperlinks','off'), movie_path,rep);
                    % close file
                    fclose(fid);
                    
                    % Status update - Step 5
                    expData.statusTracker{5,3} = {'Failed'};
                    expData.statusTracker{5,4} = warnNum5;
                    
                end % try KJ segment
                
                % ----------- END KJ SEGMENT CLASSIFICATION -----------
                
                % ----------- CONSTRUCT AND FORMAT STATS TABLE ------------
                
                % ----------- BEGIN SUMMARIZING SPEED by MOTILITY TYPE ----
                
                try
                    vel_by_class = speed_by_class(scData,cellMeans);
                    cellMeans = [cellMeans, vel_by_class];
                    rawData.(rep).chemotaxisStats = scData;
                    rawData.(rep).cellMeans = cellMeans;
                    
                    expData.statusTracker{6,3} = {'Complete'};
                    expData.statusTracker{6,4} = warnNum6;
                    
                catch err
                    warnNum6 = warnNum6 + 1;
                    warnID = 'Error occurred in speed_by_class analysis'
                    fullFileName = strcat('analyzeImarisData - Error_Log_', datestr(date,'yyyy-mm-dd'), '_', timeStamp, '.txt');
                    fid = fopen([errorPath fullFileName{:}], 'at');
                    fprintf(fid, '\n\nStep 6:\n     %i: %s\n%s  -- %s --%s\n\nNum rows cellMeans: %i\nNum rows vel_by_class: %i\n',warnNum6, warnID, err.getReport('extended', 'hyperlinks','off'), movie_path,rep,size(cellMeans,1),size(vel_by_class,1));
                    % close file
                    fclose(fid);
                end
                
                clear allData
                
                repID = dirs{iDir}(regexp(dirs{iDir},'20[1-2][0-9]'):end);
                repID = strrep(repID,filesep,'_');
                
                % ------------------------ BEGIN HANDLING WARNINGS---------
                % warnings are displayed in the command window and added to
                % an error log text file saved in the master Directory in a
                % folder titled 'Error Logs'
            catch err
                warnNum4 = warnNum4 + 1;
                warnID = 'Error during chemotaxis analysis'
                fid = fopen([errorPath fullFileName{:}], 'at');
                fprintf(fid, '\n\nStep 4:\n     %i: %s\n%s  -- %s --%s\n',warnNum4, warnID, err.getReport('extended', 'hyperlinks','off'), movie_path,rep);
                % close file
                fclose(fid)
                expData.statusTracker{4,3} = {'Failed'};
                expData.statusTracker{4,4} = warnNum4;
            end % try compute chemotaxis stats
        end % for iWell
        
        saveas(gcf,[graphPath expID '_' repID '_Classified_tracks.png'],'png');
    else
        % if ~isempty
        warnNum4 = warnNum4 + 1;
        warningMessage = 'WARNING: No Raw Data File found';
        warning(warningMessage)
        for idx = 1:length(dirIdx)
            lut{dirIdx(idx),1} = 'Error';
        end
        fprintf('\n%s: \n',movie_path)
        
        % Open error log file for appending
        warnID = 'Missing Raw Data File';
        fid = fopen([errorPath fullFileName{:}], 'at');
        
        fprintf(fid, '\n\nStep 4:\n     %i: %s\n%s  -- %s --%s\n',warnNum4, warnID, movie_path,rep);
        try
            fprintf(fid,err.getReport('extended', 'hyperlinks','off'), movie_path,rep);
        catch
        end
        fclose(fid);
        
    end % is empty
    if dirs{iDir}(end) ~= filesep
        dirs{iDir}(end+1) = filesep;
    end % if dirs
    
    if exist('rawData') ~= 0
        chemotaxisStats = rawData;
        save([movie_path expID '_Processed Data_'  datestr(date,'yyyy-mm-dd') '.mat'], 'chemotaxisStats')
        clear rawData
        clear chemotaxisStats
        
        fprintf('\n\nChemotaxisStats saved in movie source folder: \n %s\n',dirs{iDir});
        
        disp('Data saved')
        disp('...')
    else
        warnNum4 = warnNum4 + 1;
        warningMessage = 'WARNING: Processed data not stored!';
        warning(warningMessage)
        fprintf('\n%s: \n',dirs{iDir})
        
        % Open error log file for appending
        warnID = 'Error during data processing';
        fid = fopen([errorPath fullFileName{:}], 'at');
        if exist('err') ~= 0
        fprintf(fid, '\n\nStep 4:\n     %i: %s\n%s  -- %s --%s\n',warnNum4, warnID, err.getReport('extended', 'hyperlinks','off'), movie_path,rep);
        else
                    fprintf(fid, '\n\nStep 4:\n     %i: %s\n%s  -- %s --%s\n',warnNum4, warnID, movie_path,rep);

        fclose(fid);
    end % if exist
    close all
end % for iDir (movie directory)

fprintf('Analysis complete.\n');
save([varPath expID '_expData_' datestr(date,'yyyy-mm-dd') '.mat'],'expData');
end % function