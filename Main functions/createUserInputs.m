function expData = createUserInputs(masterPath, timeInSec, numFrames, pixUnit, src_type, process_all, dataOrganization, min_track_length)


% ------------- STEP 1 ---------------------
% Store user inputs
% If expData is successfully created, Step 1 is marked as complete
masterPath = formatPath(masterPath); % make sure path ends in filesep
expData.masterPath = masterPath;
warnNum = 0;


% Turn off expected warning
warning('off','MATLAB:table:ModifiedAndSavedVarnames')

% Write table for storing inputs:
T = cell(6,2);
T{2,1} = 'Time in Sec';
T{2,2} = timeInSec;
T{3,1} = 'Number of Frames';
T{3,2} = numFrames;
T{4,1} = 'Pixel Size';
T{4,2} = pixUnit;
T{5,1} = 'Source Type';
T{5,2} = src_type;
T{6,1} = 'Process Option';
if process_all == 1
    T{6,2} = 'TRUE';
else
    T{6,2} = 'FALSE';
end % if
T{7,1} = 'Imaris File Type';
T{7,2} = dataOrganization;
T{8,1} = 'Min Track Length';
T{8,2} = min_track_length;

heads = ["Step","ID","Status","Num_Errors"];

%Step           ID                                              Status
P{1,1} = 1;     P{1,2} = 'Store user inputs';                   P{1,3} = 'Incomplete';  P{1,4} = 0;
P{2,1} = 2;     P{2,2} = 'Import Imaris Data';                  P{2,3} = 'Incomplete';  P{2,4} = 0;
P{3,1} = 3;     P{3,2} = 'Save Raw Data structure';             P{3,3} = 'Incomplete';  P{3,4} = 0;
P{4,1} = 4;     P{4,2} = 'Measure CI';                          P{4,3} = 'Incomplete';  P{4,4} = 0;
P{5,1} = 5;     P{5,2} = 'Classify Tracks';                     P{5,3} = 'Incomplete';  P{5,4} = 0;
P{6,1} = 7;     P{6,2} = 'Store processed data structure';      P{6,3} = 'Incomplete';  P{6,4} = 0;
P{7,1} = 8;     P{7,2} = 'Quantify velocity by class';          P{7,3} = 'Incomplete';  P{7,4} = 0;
P{8,1} = 9;     P{8,2} = 'Export Data to csv file';             P{8,3} = 'Incomplete';  P{8,4} = 0;



expData.statusTracker = cell2table(P,'VariableNames',heads);

% ---------------- BEGIN USER INPUT PROCESSING ---------------------------
% Prompts user to select the data key file, creates folders for data
% processing outputs and stores all user input values for reference.


% Adding a check to see if key file is already in workspace
% Check to see if file and path exist
eP = exist('path');
eF = exist('file'); 

if eP ~= 1 && eF ~= 1
    [file, path] = uigetfile('*.xlsx','Select Key File');
else
    path = formatPath(path)
    quest = strcat('Data Key path already in workspace.', 'Use: ',path,file,' ?')
    dlgtitle = 'Use existing key'
    answer = questdlg(quest,dlgtitle)
    if strcmp(answer,'No') == 1
        [file, path] = uigetfile('*.xlsx','Select Key File');
    end % if answer
end % exist(path)
path = formatPath(path);
sheets = [];

% I noticed there are two different versions of this function that work
% to varying degrees depending on which version of MATLAB is installed.
% As a workaround, I am trying them in sequence in case the user doesn't
% have either or.

try % first function
    sheets = sheetnames([path file]);
catch
end % try

if isempty(sheets) % if that doesn't work
    try
        [~, sheets] = xlsfinfo([path file]);
    catch
    end
end

% --------------- INTERACTIVE FILE PICKER --------------------------------
% Prints a numbered list to the command-line including all sheetnames
if ~isempty(sheets)
    list = sheets;
    sheetNum = listdlg('PromptString',{'Select a dataset to be processed'},'SelectionMode','single','ListString',list,'CancelString','Cancel');
    %     %fprintf('\n')
    %     for iSheet = 1:length(sheets)
    %         %fprintf('\n%d)    %s',iSheet,sheets{iSheet})
    %     end
    %     %fprintf('\n')
    %     sheetNum = input('Input sheet number: \n');
    if isempty(sheetNum)
        warnNum = warnNum + 1;
        warning('\nNo dataset selected. : ');
        expData.statusTracker{1,4} = warnNum;
    else
        expID = sheets{sheetNum};
    end
else % if ~isempty
    warnNum = warnNum + 1;
    expID = input('\nCould not read in data. Please manually enter experiment ID: ');
    expData.statusTracker{1,4} = warnNum;
end % if ~isempty

% ------------- END INTERACTIVE FILE PICKER ------------------------------

T{1,1} = 'ID';
T{1,2} = expID;

expData.ui = cell2table(T); % initualize table for storing user inputs
clear T

% TO-DO - next section will not work with manual entry of expID
lut = readtable([path file],'Sheet',sheetNum);
lutHeads = lut.Properties.VariableNames;
% assert(sum(contains(lut{:,2},masterPath)) ~= 0, ...
%     'WARNING - double check masterPath and look-up table to confirm experiment ID matches')

% Defines all experimental directories - info obtained from key

if sum(contains(lut{:,2},masterPath)) > 0
    lut{:,2} = strrep(lut{:,2},masterPath,'');
end % if sum
dirs = unique(lut{:,2},'stable');
expData.lut = lut;

% create paths for storing outputs
varPath = [masterPath 'Variables' filesep];
graphPath = [masterPath 'Graphs' filesep];
errorPath = [masterPath 'Error Logs' filesep];

if ~exist(varPath)
    mkdir(varPath);
end

if ~exist(graphPath)
    mkdir(graphPath);
end %

if ~exist(errorPath)
    mkdir(errorPath);
end

fullFileName = strcat('createUserInputs - Error_Log_', datestr(date,'yyyy-mm-dd'), '_', '.txt');
expData.outputPaths = {varPath; graphPath; errorPath}; % store output paths

% STEP 1 Status Tracker update
expData.statusTracker{1,3} = {'Complete'};

% ----------------------- END USER INPUT PROCESSING -----------------------


% ----------------------- BEGIN IMPORTING IMARIS DATA ---------------------

warnNum = 0; % tally for warnings encountered

c = clock;
timeStamp = strcat(num2str(c(4)),"_",num2str(c(5)),"_",(num2str(floor(c(6)))));
clear c

if iscell(lut) == 0
    lut = table2cell(lut);
end

%fprintf('\n...Importing Data...\n');

for iDir = 1:length(dirs) % for every directory
    
    if ~isempty(dirs{iDir}) % make sure directory contains files
        
        dirIdx = []; % initialize
        
        if dirs{iDir}(end) == filesep
            dirs{iDir} = dirs{iDir}(1:end-1);
        end % if dirs
        
        
        dirIdx = find(contains(lut(:,2),dirs{iDir})); % Index rows from look-up-table (lut)
        
        reps = []; % ensure reps is cleared
        reps = unique(lut(dirIdx,3),'stable'); % Stores position name
        movie_path = [masterPath dirs{iDir}]; % stores path to Imaris files
        
        if movie_path(end) ~= filesep
            movie_path(end+1) = filesep;
        end % if movie_path
        
        %fprintf('\nFound %d files: \n', length(reps))
        
        for iFile = 1:length(reps) % print numbered list of replicates in folder
            %fprintf('\n %d: %s',iFile,reps{iFile})
        end % for iFile
        
        %fprintf('\n');
        
        if process_all ~=1 % Select which reps to process
            N = input('\n Enter file numbers you would like to process in vector format (Ex: [1 3 5] or [1:5]): ');
            %fprintf('\n');
        else
            N = 1:length(reps);
        end
        
        for i = N
            try
                iN = N(i); % in case files to be processed are not consecutive
                %fprintf('Reading Imaris Files...\n');
                
                rep = reps{iN};
                %rep = strrep(rep,' ','_');
                
                %  ------------------------  BEGIN READING AND STORING IMARIS DATA
                ID = rep;
                %try both csv and xlsx in sequence (should be on or the other)
                iFilenames = getFilenames(movie_path,'csv');
                
                if ~isempty(iFilenames)
                    fileFormat = 'csv';
                end % ~isempty
                
                if isempty(iFilenames)
                    % try .xls file
                    iFilenames = getFilenames(movie_path,'xls');
                    fileFormat = 'xls';
                end % if isempty
                
                if isempty(iFilenames)
                    warning('Unable to detect Imaris files... attempting to solve...')

                    if iDir > 1
                        worth_a_try = dirs{iDir - 1};
                    else
                        worth_a_try = dirs{iDir+1};
                    end
                    
                    str1 = worth_a_try(regexp(worth_a_try,expID):length(expID)+1);
                    str2 = dirs{iDir}(regexp(dirs{iDir},expID):length(expID)+1);
                    
                    if str1 ~= str2
                        newString = strrep(str2,str2(end),str1(end));
                    end
                    
                    newDir = [newString dirs{iDir}(length(expID)+2:end)];
                    movie_path = [masterPath newDir];
                    
                    iFilenames = getFilenames(movie_path,'csv');
                    if ~isempty(iFilenames)
                        fileFormat = 'csv';
                    end % ~isempty
                    
                    if isempty(iFilenames)
                        % try .xls file
                        iFilenames = getFilenames(movie_path,'xls');
                        fileFormat = 'xls';
                    end % if isempty
                    
                    if ~isempty(iFilenames)
                        dirs{iDir} = newDir;
                        for iL = 1:length(dirIdx)
                            lut{dirIdx(iL),2} = newDir;
                        end
                    else
                    end
                end % if isempty
                
                % ------- END INPUT CHECKS ------------------------------------------------
                % ------------ BEGIN IMPORTING DATA ---------------------------------------
                repFiles = []; 
                repFiles = iFilenames([find(contains(iFilenames,ID)>0)],1);
                
                [rawData.(rep) failedReps] = importImarisData(movie_path, dataOrganization, repFiles, rep, expData);
                
                if ~isempty(failedReps)
                    for iF = 1:size(failedReps,1)
                        failedRep = failedReps(iF,length(masterPath)+1:end);
                        lutIdx = find(contains(lut(:,2),failedRep));
                        for iL = 1:length(lutIdx)
                            lut{lutIdx(iL),1} = 'Error';
                        end % for iL
                    end
                end
                
            catch err % try (within N)
                warnNum = warnNum + 1;
                warnID = 'Error during data import'
                fid = fopen([errorPath fullFileName], 'at');
                %fprintf(fid, 'Step 2:\n     %i: %s\n%s  -- %s --%s\n',warnNum, warnID, err.getReport('extended', 'hyperlinks','off'), movie_path,rep);
           end % try (within N)
        end % for iN
        
        %fprintf('.......................................\n');
        %fprintf('All replicates imported...\n');
        
        if ~isempty(repFiles)
            try
                % ------------------- USER CONFIRMS PRE-CODED SOURCE --------------
                % If using interactive source selector, comment out
                % this block.
                
                rawData = checkImarisOrientation(rawData,expData,movie_path);
                
                % -------- END SOURCE CONFIRMATION --------------------
                
                % Save raw-data structure, updated lut and other variables in directory folder
                save([movie_path expID '_Raw_Data_' datestr(date,'yyyy-mm-dd') '.mat'], 'rawData');
                clear rawData
                %fprintf('\n\nExperiment Data saved in movie source folder: \n %s\n',dirs{iDir});
                clear movie_path
            catch
                warnNum = warnNum + 1;
                warning('Error generating and/or storing source input...');
                %fprintf(': %s\n',dirs{iDir});
                warnID = 'Source Data not stored'
                fid = fopen([errorPath fullFileName], 'at');
                %fprintf(fid, 'Step 1:\n     %i: %s\n%s  -- %s --%s\n',warnNum, warnID, movie_path, rep);
                fclose(fid);
            end
        end % isempty repfiles
    else
        warnNum = warnNum + 1;
        %fprintf('No data files found for %s... this rep will not be processed.\n',ID)
        lut{dirIdx(iN),1} = 'Error';
        %dirs{dirIdx(iN),1} = 0;
        warnID = 'Missing data files'
        fid = fopen([errorPath fullFileName], 'at');
        %fprintf(fid, 'Step 2:\n     %i: %s\n%s  -- %s --%s\n',warnNum, warnID, err.getReport('extended', 'hyperlinks','off'), movie_path,rep);
        fclose(fid);
    end % make sure dirs is not empty
    
    if warnNum == 0
        %fprintf('Dataset stored without errors...\n');
        expData.statusTracker{2,3} = {'Complete'};
    else
        %fprintf('\n\n WARNING - some data files were rejected! Check error log for details...\n')
        save([varPath expID '_expData_' datestr(date,'yyyy-mm-dd') '.mat'],'expData','dirs');
        expData.statusTracker{2,3} = {'Completed with errors'};
        expData.statusTracker{2,4} = warnNum;
    end
end % for iDir

expData.lut = cell2table(lut,'VariableNames',lutHeads);
expData.statusTracker{3,3} = {'Complete'};
expData.statusTracker{3,4} = warnNum;
save([varPath expID '_expData_' datestr(date,'yyyy-mm-dd') '.mat'],'expData','dirs');

% Prints full filename for user-input storage
%fprintf('\nAll user inputs stored in:\n%s\n',[varPath expID '_expData_' datestr(date,'yyyy-mm-dd') '.mat']);
clear ui

expData.statusTracker
end % function
