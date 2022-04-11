function [pt] = proj_point_BG(vector, q)
p0 = vector(1,:);
p1 = vector(2,:);

% Determine if line is vertical or horizontal
dX = p0(1)-p1(1);
dY = p0(2)-p1(2);

if abs(dX) > abs(dY)
    % Horizontal
    ind  = 1;
else
    % Vertical
    ind = 2; 
end 

% Determine if point has perpendicular

if q(ind) < max([p0(ind) p1(ind)]) && q(ind) > min([p0(ind) p1(ind)]) % q is within the bounds of the line
    
    % If point has perpendicular
    a = [-q(1)*(p1(1)-p0(1)) - q(2)*(p1(2)-p0(2)); ...
        -p0(2)*(p1(1)-p0(1)) + p0(1)*(p1(2)-p0(2))];
    b = [p1(1) - p0(1), p1(2) - p0(2);...
        p0(2) - p1(2), p1(1) - p0(1)];
    p = -(b\a);
    pt(1,1) = p(1);
    pt(1,2) = p(2);
    
else
    dp0 = abs(p0(ind)-q(ind));
    dp1 = abs(p1(ind)-q(ind));
    
    if dp0 < dp1
        pt = p0;
    else
        pt = p1;
    end
end

% else select end-point closest to q


end