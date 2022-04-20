function [smoothed_tracks] = vis_Imaris_tracks(rep,IMS,tracks_in,dframe,ps,movie_save_path,make_movie)

% masterPath = '/Users/jonschrope/Desktop/Huttlab/cell_tracking'; % Jon Desktop
% addpath(genpath(masterPath)); % Add all subfolders to the path
% masterPath = formatPath(masterPath); % add filesep to end of path
% save_path = '/Users/jonschrope/Desktop/Huttlab/cell_tracking/output/vids';

% v = VideoReader(rep '.avi');
% numFrames = v.NumFrames;
% C = cell(numFrames,1);
% 
% for t = 1:numFrames
%        frame = read(v,t);
%        C{t,1} = frame(:,:,3);
% end

%movie_path = '/Users/jonschrope/Desktop/Huttlab/cell_tracking/2D_example_data/2D 2019-01-29/Movie 1/';
%expFile = getFilenames(movie_path,'Raw_Data');
%file = expFile{1};
%load([movie_path file]); % loads tracks as "rawData"
%input_tracks = table2array(rawData.s1.ImarisData);

%% start
% tracks = input_tracks;
% IMS = C;
% dframe = 1; % number of frames to average over (filter)
um2pix = ps; % 1 pix = 1.27 uM Imaris conversion factor (roughly)

tic

% T = max(tracks(:,2)); % max time
smoothed_tracks = zeros(size(tracks_in));
cntr1 = 1; % counter
f1 = figure('Renderer', 'painters', 'Position', [0 0 696 520],'visible','off');
disp_image1 = imshow(IMS{1});

% f2 = figure(2);
cmap = colormap(lines(900));
% disp_image2 = imshow(IMS(1).orig);

t_list = unique(tracks_in(:,2)); % vector of time points

% for idx = 1:length(t_list)
%     TRACKS_time{idx,1} = tracks_in(tracks_in(:,2) == t_list(idx),:);
% %scatter(TRACKS_time{t,1}(:,1), TRACKS_time{t,1}(:,2));
% end

% apply smoothing filter over tracks of length = dFrame
for n = 1+dframe:length(t_list) % in frames (not seconds)
    tic
    t0 = n-dframe;
    t = n;
    t_ave = floor(mean(t0:t)); % average FRAME (not time)
    xy_t = tracks_in(tracks_in(:,2)== t_list(t_ave),:); % tracks at average frame
    xy_dt = tracks_in(tracks_in(:,2)>=t_list(t0) & tracks_in(:,2)<=t_list(t) ,:); % tracks between t0 and t
    
    nnodes = length(xy_t(:,1)); % num cells at time t
    %disp(max(xy_t(:,1)));

    smoothed_tracks_t = zeros(size(xy_dt)); % initialize smoothed tracks for time t

    for i = 1:nnodes % loop through each cell
        ID = xy_t(i,1);
        pos = xy_dt(xy_dt(:,1)==ID,:); % positions of cell i at frame t0 and t
        
        smooth = mean(pos,1); % mean position of cell i between frame t0 and t
        smooth(2) = t_ave; % FRAMES!!!
        smooth(1) = ID;
        smoothed_tracks_t(cntr1,:) = smooth; % concatenate into new smoothed tracks
        cntr1 = cntr1 + 1;
    end

    full_save_path = [movie_save_path filesep];

       if ~exist(full_save_path)
            mkdir(full_save_path);
       end
    
    if strcmp(make_movie,'TRUE') == 1 % display movie and save to output path

        figure(f1);
        set(disp_image1,'CData',IMS{n});
        colormap(gray)
        hold on;
        scatter(smoothed_tracks_t(cntr1-nnodes:cntr1-1,3)./um2pix,520-(smoothed_tracks_t(cntr1-nnodes:cntr1-1,4)/um2pix),10,...
                    cmap(smoothed_tracks_t(cntr1-nnodes:cntr1-1,1), :),'filled','MarkerFaceAlpha',1);
        hold on
        axis equal
        xlim([0,696]);
        ylim([0,520]);
        drawnow;

        print([full_save_path 'tracks_' num2str(t,'%.3d') '.tif'],'-dtiffn')
   end 
end

if strcmp(make_movie,'TRUE') == 1
print([full_save_path 'track_final' num2str(length(t_list),'%.3d') '.pdf'],'-dpdf','-r0') % save final image as pdf
end

close all


