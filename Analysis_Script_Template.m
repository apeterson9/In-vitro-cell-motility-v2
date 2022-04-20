% Revamp of the Arpc1b processing code

% 
% Step 1: User inputs
% Step 2: Import and organize raw data
% Step 3: Save raw data structure
% Step 4: Use raw data from Imaris to perform chemotaxis analysis
% Step 5: Classify cell tracks into motility states
% Step 6: Organize and save processed data into data structure 
% Step 7: Quantify velocity by motility state
% Step 8: Export processed data for statistics and visualization in R
% Step 9: Create plots and data summary in R Studio

% ------------ STEP 1 -------------------
% ------------User Inputs----------------

%masterPath = 'E:\Downloads\movies\movies\C5a movies\Arpc1b lines\2D'; % home
%masterPath = 'C:\Users\anpet\Desktop\2D_exp'; % home
%masterPath = 'D:\Huttenlocher Lab\Ashley\C5a movies\Arpc1b lines\2D\';
%masterPath = 'C:\Users\bxr007\OneDrive - UW-Madison\Data In Progress\Rescue lines'; % work

masterPath = '/Users/jonschrope/Desktop/Huttlab/cell_tracking'; % Jon Desktop
addpath(genpath(masterPath)); % Add all subfolders to the path
masterPath = formatPath(masterPath); % add filesep to end of path

src_type = 'line';
process_all = 1;
smooth_frame_step = 0; % number of frames to smooth tracks over
make_tracks_movie = 0; % 1 if you want to save tracking movie, 0 if no
timeInSec = 30; % frequency in seconds of images
pixUnit = 1.27; % size of 1 pixel in uM NOTE: Nikon 10X = 0.788 %1.27
numFrames = 91; % added functionality to automatically determine number of frames - has not been extensively tested.
dataOrganization = 'individual'; %Enter 'compound' if you have one excel file with measurements on individual sheets, 
                                 % enter 'individual' if each measurement was exported
                                 % to its own file
min_track_length = 10;
masterPath = formatPath(masterPath);

% Read-in, organize Imaris Data, store user-inputs, create directories for variables, error logs and graphs

expData = createUserInputs(masterPath,timeInSec,numFrames,pixUnit,src_type,process_all,dataOrganization,min_track_length,make_tracks_movie,smooth_frame_step);

% Load experiment data inputs
varPath = formatPath([masterPath filesep 'output' filesep 'variables']); % Variables subfolder path
expFile = getFilenames(varPath, 'expData'); % get files that contain 'expData' text

if ~isempty(expFile)
    load([varPath expFile{end}]); % create processeddedData and R fields
    % (if aready there... skip this part)
else
    error('No data file found. Please check the path');
end

expData.masterPath = masterPath;
expData.statusTracker % print status

%% Analyze Imaris-generated tracks

expData = analyzeImarisData(expData);

%% Compile processed data into organized data structure, save to varPath

[processedData, expData, L] = compile_processed_data(expData);

%% Organize Data into a .csv file for R studio

expData = export_for_R(expData,processedData);