%function visualize_tracks_jon(input_tracks,T,filename,movie_save_path)

%% Get Image and Tracks

masterPath = '/Users/jonschrope/Desktop/Huttlab/cell_tracking'; % Jon Desktop
addpath(genpath(masterPath)); % Add all subfolders to the path
masterPath = formatPath(masterPath); % add filesep to end of path

v = VideoReader('s1.avi');
frame20 = read(v,20);
numFrames = v.NumFrames;
C = cell(numFrames,1);

for t = 1:numFrames
       frame = read(v,t);
       C{t,1} = frame(:,:,3);
end

movie_path = '/Users/jonschrope/Desktop/Huttlab/cell_tracking/2D_example_data/2D 2019-01-29/Movie 1/';
expFile = getFilenames(movie_path,'Raw_Data');
file = expFile{1};
load([movie_path file]); % loads tracks as "rawData"
input_tracks = table2array(rawData.s1.ImarisData);

%% start old code

N = max(input_tracks(:,1)); % number particle/cell tracks
T = floor(max(input_tracks(:,2))./30.0370);

t_list = unique(input_tracks(:,2)); % vector of time points

%% Position vs. Time

% initiate storage cells to separate tracks out by frame or by particle/cell
TRACKS_time = cell(T,1);
TRACKS_particle = cell(N,1);

% Group (seperate) tracks based on the time-point, so examine all particles
% at a single time (less useful imo)
count = 0;
for idx = 1:length(t_list)
    TRACKS_time{idx,1} = input_tracks(input_tracks(:,2) == t_list(idx),:);
%scatter(TRACKS_time{t,1}(:,1), TRACKS_time{t,1}(:,2));
end

%colorVec = parula(200); % Generate colormap with n points

for i = 1:N
% Group (seperate) tracks based on the particle, so follow single particle
% through time
TRACKS_particle{i,1} = input_tracks(input_tracks(:,1) == i,:);
end 

%% Generate Plots

% 1) Plot x,y position of tracks vs time
% for i = 1:N
%             color_param = round(var(TRACKS_particle{i,1}(:,2))*10);
% %             color_param(color_param > 200) = 200;
% %             color_param(color_param == 0) = 1;
%             bin_var = color_param;
%             %ncol = colorVec(bin_var,:); % Colorcode based on variance
%             
% % Plot time (on x-axis), X-position (on y-axis) and Y-Position (on z-axis)
% % Plot3(time, x,y) colorcode based on variance (or something else)
% plot3(TRACKS_particle{i,1}(:,3)*.5, TRACKS_particle{i,1}(:,1),TRACKS_particle{i,1}(:,2)); %,'Color',ncol)
% title('Tracks Position vs. Time')
% xlabel('Time (minutes')
% ylabel('X - Position (pixels)')
% zlabel('Y - Position (pixels)')
% hold on
% end
% 
figure;
for i = 1:N
    
%TRACKS_particle{i,1} = input_tracks(input_tracks(:,1) == i,:);
            
%             bin_ypos = round(TRACKS_particle{i}(1,4));
%             color_param = round(var(TRACKS_particle{i}(:,2))*10);
%             color_param(color_param > 200) = 200;
%             color_param(color_param == 0) = 1;
%             bin_var = color_param;
%             ncol1 = colorVec1(bin_ypos,:);
%             ncol2 = colorVec2(bin_var,:);
            
% Plots time (on x-axis), X-position (on y-axis) and Y-Position (on z-axis)

plot3(TRACKS_particle{i}(:,2)./60, TRACKS_particle{i}(:,4),TRACKS_particle{i,1}(:,3),'linewidth',2) %,'Color',ncol2)

title('Cell Tracks')
xlabel('Time (minutes')
ylabel('X - Position (pixels)')
zlabel('Y - Position (pixels)')
%colorbar;
hold on
end

% print([movie_save_path filesep filename '.png'],'-dpng');
% close gcf


%% Velocity vs. Time

% figure;
% storage_velx = [];
% for i = 1:N
%     
% vel_x = diff(TRACKS_particle{i,1}(:,3));
% 
% % currently in pixels/frame... convert to pixels/min
% vel_x = vel_x * 2;
% 
% storage_velx = [storage_velx; vel_x];
% 
% t_vec = TRACKS_particle{i}(:,2)*.5;
% t_vec(1) = [];
% 
% % plot3(t_vec,vel_x, vel_y);
% % xlabel('Time (mins)')
% % ylabel('X-Velocity (pixels/frame')
% % zlabel('Z-Velocity (pixels/frame')
% % hold on
% 
% plot(t_vec,vel_x)
% hold on
% xlabel('Time (mins)')
% ylabel('X-Velocity (frames/min)')
% title('Tracks X-Velocity vs. Time')
% end 
% 
% 
% figure;
% storage_vely = [];
% for i = 1:N
%     vel_y = diff(TRACKS_particle{i,1}(:,2));
%     vel_y = vel_y * 2;
%     
%     t_vec = TRACKS_particle{i,1}(:,3)*.5;
%     t_vec(1) = [];
%     
%     plot(t_vec,vel_y)
%     hold on
%     xlabel('Time (mins)')
%     ylabel('Y-Velocity (frames/min)')
%     title('Tracks Y-Velocity vs. Time')
%     ylim([-20 20])
%     
%     storage_vely = [storage_vely; vel_y];
% end 
% 
% % Histogram of velocities.. compare between phenotypes
%     % This biases towards tracks that are kept longer, consider giving each track an
%     % average velocity then histogram of those
%     
% figure;
% hist(storage_velx,100)
% xlabel('Velocity (pixels/min)')
% title('X - Velocity Histogram')
% hold on
% 
% avg = mean(storage_velx);
% variance = var(storage_velx);
% text(.75,.9,['Mean = ' num2str(round(avg,2))],'Units','normalized','FontSize',12,'Color','b')
% text(.75,.85,['SEM = ' num2str(round(sqrt(variance),2))],'Units','normalized','FontSize',12,'Color','b')
% 
% figure;
% hist(storage_vely,100)
% xlabel('Velocity (pixels/min)')
% title('Y - Velocity Histogram')
% 
% avg = mean(storage_vely);
% variance = var(storage_vely);
% text(.75,.9,['Mean = ' num2str(round(avg,2))],'Units','normalized','FontSize',12,'Color','b')
% text(.75,.85,['SEM = ' num2str(round(sqrt(variance),2))],'Units','normalized','FontSize',12,'Color','b')
% 
% 
