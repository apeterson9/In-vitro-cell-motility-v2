
function [cellMeans_out] = computeMigrationStats(data,cellMeans,source)
src_line = source;


data_out = data{:,:};

cellMeansCols = cellMeans.Properties.VariableNames;
cellMeansCols = {cellMeansCols{:}, 'CI Haynes','ECI','MI','DIS'};
cellMeans_out = cellMeans{:,:};

cellIDs = unique(data_out(:,1));

clear MI
clear CI
clear ECI
clear DIR
clear DIS
for iCell = 1:length(cellIDs)
    
    cellID = cellIDs(iCell);
    idx = find(data_out(:,1) == cellID);
    track_i = data_out(idx,:);
    
    %                 subplot(2,2,plotNum)
    %                 hold on
    %                 plot(track_i(:,3),track_i(:,4));
    %                 scatter(track_i(1,3),track_i(1,4),'c');
    %                 scatter(track_i(end,3),track_i(end,4),'m');
    
    
    % find cumulative distance
    cumDist = cellMeans_out(cellID,6);
    velocity = cellMeans_out(cellID,7);
    
    
    posI = track_i(1,3:4);
    posF = track_i(end,3:4);
    %plot([posI(1) posF(1)],[posI(2) posF(2)],'LineWidth',3);
    %axis equal
    
    intersect = proj_point_BG(src_line, posI); % project point onto line
    ct_axis = intersect - posI; % migration axis vector (perpendicular to source LINE)
    newLine = [intersect(1) intersect(2); posI(1) posI(2)];
    %line([posI(1), intersect(1)],[posI(2), intersect(2)],'Color','c','LineStyle','--')
    iS = proj_point_BG(newLine, posF);
    
    newAxis = iS-posF;
    dr = [posF(1)-posI(1) posF(2)-posI(2)];
    cosTheta = dot(dr/norm(dr),ct_axis/norm(ct_axis));
    theta = acosd(cosTheta);
    
    MI(iCell,1) =  norm(dr)/(velocity*(track_i(end,2)-track_i(1,2))); % motility index
    if MI(iCell,1) ~= inf
        
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
        
        CI(iCell,1) = xD/(sum(cumDist));
        ECI(iCell,1) = CI(iCell,1)*MI(iCell,1);
        DIR(iCell,1) = cellMeans_out(iCell,5);
        DIS(iCell,1) = cellMeans_out(iCell,6);
        
    else
        
        CI(iCell,1) = nan;
        
        ECI(iCell,1) = nan;
        DIR(iCell,1) = nan;
        DIS(iCell,1) = nan;
        CI(iCell,1) = nan;
    end % if MI(iCell)
end  % for iCell


cellMeans_out(:,end+1) = CI;
cellMeans_out(:,end+1) = ECI;
cellMeans_out(:,end+1) = MI;
cellMeans_out(:,end+1) = DIS;

cellMeans_out = array2table(cellMeans_out,'VariableNames',cellMeansCols);

end
