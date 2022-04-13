function [cellMeans, allTracks] = calculate_CI_in_vitro(allData, source, min_track_length)
% NOTE: Z-dimension/3D functionality not completed - this code assumes
% there is no positional change in the Z-direction!
%
% Purpose: to calculate instantaneous chemotaxis stats including chemotactic index, angle (relative to source) and cell velocity as well 
%          as cell average statistics including overall directionality 
%
% INPUTS: 
% allData (tracks):       mxn matrix where m = individual measurements (1 per step, per cell) and n = number of measurements
%               expects columns 1:2 to be position coordinates, column 3 to be frames and column 4 to be
%               cell ID
% source:       Either coordinates of a point or line that represents gradient
%               gradient source
%
% OUTPUTS:

% cellMeans:    
% allSteps: 
%
% CREDITS:
% Jon Schrope and Briana Rocha-Gregg; University of Wisconsin-Madison 2020
%
% SETUP: 

if nargin < 2
    error('Not enough input arguments. Track matrix and source coordinates required.')
end % if nargin

headers = allData.Properties.VariableNames;

xCol = find(strcmp(headers,'PosX'));
yCol = find(strcmp(headers,'PosY'));
tCol = find(strcmp(headers,'Time_in_Sec')); 
iCol = find(strcmp(headers,'TrackID'));
counter = 0;

% Initialize variables
tracks = allData{:,:};
%track_heads = ["cell_ID","CI_Jon","theta","velocity","ed_src"];
allTracks_temp = [];
cellIDs = nonzeros(unique(tracks(:,iCol))); % list of particle ID's
heads = ["cell ID", "track_length", "cumul distance", "net displacement", "tortuosity", "mean velocity", "mean theta", "mean CI", "num pauses", "duration"];
cellMeans = table(nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,'VariableNames',heads); % Initialize output variables

x = source(:,1); % x coord of source line
y = source(:,2); % y coord of source line
src_line = [x(1) y(1); x(2) y(2)]; % re-construct source-line

for track_idx = 1:length(cellIDs) % for each cell

    cellIdx = find(tracks(:,iCol)==cellIDs(track_idx)); % rows corresponding to current cell ID
    
    track_i = tracks(cellIdx,[tCol xCol yCol]); %  Tracks for current cell ID

    tracks_out_i = nan(size(track_i,1),8); % initiate storage output tracks for cell i

    % Initialize cell-specific variables, vectors of length t corresponding
    % to each cell. Will re-generate new vector as loop through each cell
    % and store this cell-specific data in matrix "tracks_out"

    ID = cellIDs(track_idx);
    
    numSteps = size(track_i,1);
%     normDist = nan;
%     net_displacement = nan;
%     tort = nan;
%     meanVel = nan;
%     meanTheta = nan;
%     CIH = nan;
%     MI = nan;
%     ECI = nan;
%     numPauses = nan;
%     duration = nan;
    
    % -------------------- Step-level calculations ------------------------
 if numSteps > min_track_length
        counter = counter+1;
        cellMeans{counter,:} = nan;
        disp_list = zeros(length(cellIdx)-1,1); %  Initialize displacement storage vector
        vel_list = zeros(length(cellIdx)-1,1);
        theta_list = zeros(length(cellIdx)-1,1);
        CI_list = zeros(length(cellIdx)-1,1);

        for t = 2:numSteps % Within track_i, loop through time length of track
            
            % idx = cellIdx(t); % index within tracks corresponding to current step
            posI = [track_i(t-1,2) track_i(t-1,3)]; % position of particle at time t-1
            posF = [track_i(t,2) track_i(t,3)]; % position of particle at time t
            
            intersect = proj_point_BG(src_line, posI); % project initial point 
            dist_src = pdist([posI; intersect]);
            ct_axis = intersect - posI; % migration axis vector (perpendicular to source LINE)
            rdx = posF(1)-posI(1); % x displacement
            rdy = posF(2)-posI(2); % y displacement
            rdtot = sqrt(rdx^2 + rdy^2); % total displacement
            disp_list(t) = rdtot; % for single track

            % calculate velocity and remove potential infs
            vel_list(t) = rdtot/(track_i(t,1)-track_i(t-1,1));
            if vel_list(t) == Inf
                vel_list(t) = nan;
            end
            
            % calculate theta, angle between true migration and "correct" migration along ct_axis
            dr = [rdx rdy]; % displacement vector = change in x, change in y
            U = [dr 0]; % displacement vector (need 3 dimensions)
            V = [ct_axis 0]; % position vector relative to source
            N = [0 0 1]; % The v1 & v2 plane normal vector
            theta_list(t) = vecangle180(U,V,N); % gives angle from -180 to 180 degrees

            % cosTheta = cosd(theta_list(t)); % equivalent to CI

            CI_list(t) = dot(dr/norm(dr), ct_axis/norm(ct_axis)); % dot normalized displacement with unit vector representing axis of chemotaxis
            % Length of the projection of dr onto ct_axis: What AMOUNT of motion is towards source??
            % Length of normalized displacement at that step (done here): What PERCENT of motion at that step is towards gradient source?
            % This is essentially just cos(theta)
            
            input_pos_vec = [track_i(t,:)]; % vector of [t x y]
            tracks_out_i(t,1:8) = [ID input_pos_vec vel_list(t) theta_list(t) CI_list(t) dist_src]; 
            clear u; clear v; clear n; clear dr; clear dist_src; 

        % *Note if a particle doesnt move in the alloted dt, the output
        % of cos_theta (thus theta) is NaN becuase norm(dr) = 0 (magnitde of dr).
        % Thus dividing by zero. I simply omit NaN values from mean_theta calculation below.

        end % for all t for given track i

        allTracks_temp = [allTracks_temp; tracks_out_i];

        %allTracks{1:size(tracks_out_i,1),:} = tracks_out_i; % store all single cell data
        % tracks_out_i(2:end,:)
    % ---------------------- END STEP-LEVEL CALCULATIONS ------------------

    % ---------------------- BEGIN TRACK-LEVEL CALCULATIONS ---------------
    
    % this section calculates means for each track over all time that the track exists

    % first get number of pauses using displacment vector from above
    [numPauses, duration] = find_pauses(disp_list,1,2);
    
    % Determine relative displacement and track duration
    rdX = track_i(end,2)-track_i(1,2); % relative displacement in the X direction
    rdY = track_i(end,3)-track_i(1,3); % relative displacement in the Y direction
    
    netDisp = sqrt(rdX^2 + rdY^2); % displacement
    cumDist = sum(disp_list); % distance traveled
    %normDisp = sqrt(rdX^2 + rdY^2)/numSteps; % total distplacement normalized by track-length
    %normDist = sum(disp_list)/numSteps; % cumulative distance traveled normalized by track length

    % calculate means for each track
    tort = netDisp/cumDist; % thus 0 < tort < 1
    meanVel = mean(vel_list,'omitnan');
    meanTheta = mean(theta_list,'omitnan');
    meanCI = mean(CI_list,'omitnan');
    
    cellMeans{counter,:} = [ID, numSteps, cumDist, netDisp, tort, meanVel, meanTheta, meanCI, numPauses, duration];
    clear ID, clear numSteps, clear cumDist, clear netDisp, clear tort, ...
        clear meanVel, clear meanTheta, clear numPauses, clear duration

    end % if numSteps > track_length
end % for track_Idx

allTracks = allTracks_temp(all(~isnan(allTracks_temp),2),:); % remove rows that are all nan

end % end function