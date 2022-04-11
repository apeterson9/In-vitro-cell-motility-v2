function [cellMeans, scData] = calculate_CI_in_vitro(allData, source, min_track_length)
% NOTE: Z-dimension/3D functionality not completed - this code assumes
% there is no positional change in the Z-direction!
%
% Purpose: to calculate instantaneous chemotaxis stats including chemotactic index, angle (relative to source) and cell velocity as well 
%          as cell average statistics including overall directionality 
%
% INPUTS: 
% tracks:       mxn matrix where m = individual measurements (1 per step, per cell) and n = number of measurements
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
zCol = find(strcmp(headers,'PosZ'));
tCol = find(strcmp(headers,'Time_in_Sec')); 
iCol = find(strcmp(headers,'TrackID'));
counter = 0;

% Initialize variables
tracks = allData{:,:};
tracks_out = nan(size(tracks,1),4);
track_heads = ["cell_ID","cosin","theta","velocity","ed_src"];
scData = table(nan,nan,nan,nan,nan,'VariableNames',track_heads);
cellIDs = nonzeros(unique(tracks(:,iCol))); % list of particle ID's
heads = ["cell_ID","numSteps","cumulative_distance","net_displacement","DI","mean_velocity","cos_theta","CI_Haynes","MI","ECI","numPauses","duration"];
cellMeans = table(nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,'VariableNames',heads); % Initialize output variables

x = source(1,:);
y = source(2,:);
src_line = [x(1) y(1); x(2) y(2)]; % re-construct source-line


for track_idx = 1:length(cellIDs) % for each cell
    
    % Obtain relevant data
    cellIdx = find(tracks(:,iCol)==cellIDs(track_idx)); % rows corresponding to current cell ID
    
    track_i = tracks(cellIdx,[xCol:yCol tCol]); %  Tracks for current cell ID

    % Initialize cell-specific variables
    CI = zeros(length(cellIdx)-1,1); % chemotactic index vector
    theta = zeros(length(cellIdx)-1,1); % angle with respect to source
    cellID = zeros(length(cellIdx)-1,1); % For matching   
    dist_src = zeros(length(cellIdx)-1,1);
    ID = cellIDs(track_idx);
    
    numSteps = size(track_i,1);
    cumDist = nan;
    net_displacement = nan;
    DI = nan;
    meanV = nan;
    cos_theta = nan;
    CIH = nan;
    MI = nan;
    ECI = nan;
    numPauses = nan;
    duration = nan;
    
    % -------------------- Step-level calculations ------------------------
    if numSteps > min_track_length
        counter = counter+1;
        cellMeans{counter,:} = nan;
        velocity = [];
        displacement = zeros(length(cellIdx)-1,1); %  Initialize displacement storage vector
        
        for t = 2:numSteps % Within track_i, loop through time length of track
            
            idx = cellIdx(t); % index within tracks corresponding to current step
            posI = [track_i(t-1,1) track_i(t-1,2)]; % position of particle at time t-1
            posF = [track_i(t,1) track_i(t,2)]; % position of particle at time t
            
            intersect = proj_point_BG(src_line, posI); % project initial point 
            dist_src(t) = pdist([posI; intersect]);
            ct_axis = intersect - posI; % migration axis vector (perpendicular to source LINE)
            rdx = posF(1)-posI(1); % x displacement
            rdy = posF(2)-posI(2); % y displacement
            rdt = sqrt(rdx^2 + rdy^2); % total displacement
            displacement(t) = rdt;
            % calculate velocity and remove potential infs
            velocity(t) = rdt/(track_i(t,3)-track_i(t-1,3));
            if velocity(t) == Inf
                velocity(t) = nan;
            end 
            dr = [rdx rdy]; % displacement vector - change in x, change in y
            cos_theta = dot(dr/norm(dr), ct_axis/norm(ct_axis)); % dot displacement with unit vector representing axis of chemotaxis
            % Divide by total displacement at that step: What PERCENT of motion at that step is towards gradient source?
            % Length of the projection of dr onto ct_axis: What AMOUNT of motion is towards source??
            CI(t) = cos_theta; % percent of motion
            
            
            U = [dr 0]; % displacement vector (need 3 dimensions)
            V = [ct_axis 0]; % position vector relative to source
            N = [0 0 1]; % The v1 & v2 plane normal vector
            theta(t) = vecangle180(U,V,N); % gives angle from -180 to 180 degrees
            clear u; clear v; clear n; clear dr;
            tracks_out(idx,1:5) = [ID cos_theta theta(t) velocity(t) dist_src(t)]; 

            % tracks_out(idx,5) = norm(ct_axis);
            % *Note if a particle doesnt move in the alloted dt, the output
            % of cos_theta (thus theta) is NaN becuase norm(dr) = 0 (magnitde of dr).
            % Thus dividing by zero. Thus I simply omit NaN values from mean_theta below.
        end % for t
    % ---------------------- END STEP-LEVEL CALCULATIONS ------------------
    % ---------------------- BEGIN TRACK-LEVEL CALCULATIONS ---------------
        
    posI = track_i(1,1:2); % initial position
    posF = track_i(end,1:2); % final position
    
    % Determine relative displacement and track duration
    rdX = track_i(end,1)-track_i(1,1); % relative displacement in the X direction
    rdY = track_i(end,2)-track_i(1,2); % relative displacement in the Y direction
    %rdZ = track_i(end,3)-track_i(1,3); % relative displacement in the Z direction
    
    % relative displacement total normalized by track-length
    rdT = sqrt(rdX^2 + rdY^2)/t;
    [numPauses duration] = find_pauses(displacement,1,2);
    
    
    numSteps = t;
    cumDist = sum(displacement)/t; % Cumulative distance traveled normalized by track length
    net_displacement = rdT;
    DI = rdT/sum(displacement); clear displacement, clear rdT
    meanV = nanmean(velocity); clear velocity % mean cell velocity over entire track
    cos_theta = nanmean(theta); clear theta
    
        % -------------------------- BEGIN CI CALC HAYNES METHOD ----------
        
        intersect = proj_point_BG(src_line, posI); % project starting point onto source
        ct_axis = intersect - posI; % migration axis vector (perpendicular to source LINE)
        newLine = [intersect(1) intersect(2); posI(1) posI(2)];
        iS = proj_point_BG(newLine, posF);
        newAxis = iS-posF;
        dr = [posF(1)-posI(1) posF(2)-posI(2)]; % displacement
        cosTheta = dot(dr/norm(dr),ct_axis/norm(ct_axis));
        theta = acosd(cosTheta); % approach angle
        MI =  norm(dr)/(meanV*(track_i(end,2)-track_i(1,2))); % motility index
        if MI ~= inf
            % determine x component
            if theta>90
                %     R = [cosd(180) -sind(180); sind(180) cosd(180)];
                %     flip = dr;
                %     flip = flip*R;
                %     cosTheta = dot(flip/norm(flip),ct_axis/norm(ct_axis));
                %     iF = proj_point_BG(newLine,flip)
                theta = 180-theta;
                sense = -1;
            else
                sense = 1;
            end
            theta3 = 180-90-theta;
            xD = sind(theta3)*norm(dr)*sense;
            CIH = xD/(sum(cumDist));
            ECI = CIH*MI;
        else
            CIH = nan;
            ECI = nan;
        end % if MI(iCell)
    end % if % size of track
    
    cellMeans{counter,:} = [ID,numSteps,cumDist,net_displacement,DI,meanV,cos_theta,CIH,MI,ECI,numPauses,duration];
    clear ID, clear numSteps, clear cumDist, clear net_displacement, clear DI, clear meanV, clear cos_theta, clear CIH, clear MI, clear ECI, clear numPauses, clear duration
end % for trackIdx

scData{1:size(tracks_out,1),:} = tracks_out;

end % end function