function [numPauses, duration] = find_pauses(d,minLength,minSteps)
        
        p = find(d < minLength);
        [n r] = findConsecutiveNums(p);
        
        if ~isempty(r)
            r2 = r(:,2)-r(:,1);
            r = r(r2>=minSteps-1,:);
            
            numPauses = size(r,1)/length(d); % number of pauses normalized by track length
            duration = nanmean(r(:,2)-r(:,1));    % average duration of pauses for cell
        else
            numPauses = 0;
            duration = nan;
        end

end