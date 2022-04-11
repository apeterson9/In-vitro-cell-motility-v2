function [n r] = findConsecutiveNums(a)

% Given an array of integers (a), determines whether any of the integers are
% consecutive in sequence. 

% Inputs: a

% Outputs: 
% n
% r

% Requirments
% all values are integers

% more than one value in a

% sorts a in ascending order
A = sort(a,'ascend');
A(end+1) = nan;
r = [];
i = 1;
while i <= length(A)-1
    
    temp = []; % initialize variable for storing start and end frames of each range
    
    % If i doesn't exceed the length of a,
    % and the current value is part of a sequence,
    % initialize determination of ending frame.
    % Otherwise, record frame (i) as a single event
    if i ~= length(A)-1 && A(i+1)-A(i) == 1 
        
        % store starting frame
        temp = [A(i) nan];
        
        % initialize incremental counters
        ticker = 0;
 
        while ticker == 0
            % If the end of A has been reached, or the current
            % frame does not precede a consecutive integer,
            % store the sequence end frame and terminate
            if i== length(A) || A(i+1) - A(i) ~= 1 
                temp(1,2) = A(i);
                ticker = 1;
                i = i+1;
            else
                % Otherwise, increase search by 1 and
                % ensure you will not have exceeded the
                % length of A
                i = i+1;
                if i == length(A)
                    ticker = 1;
                end
            end
        end % while ticker
        r = [r; temp];
    else % record A(i) as a single event
        r = [r; A(i) A(i)]; %
        i = i+1;
    end
end

n = size(r,1);

end % function