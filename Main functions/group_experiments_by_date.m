function [Groups expData] = group_experiments_by_date(expData)

lut = expData.lut;
if strcmp(class(lut),'cell') == 0
    lut = table2cell(lut);
end

varPath = expData.outputPaths{1};

uis = expData.ui{:,1};
expRow = find(strcmp(uis(:),'ID') == 1);
expID = expData.ui{expRow,2}{1};

% Modify lut to indicate groups and experimental date
for iLut = 1:length(lut(:,1)) % add a column to lut indicating group name (concatenate cell line and stimulus)
    temp = strcat(lut{iLut,4}, '_', lut{iLut,5});
    %     if strcmp(class(temp),'char') == 1
    %         temp = convertCharsToStrings(temp);
    %     end
    temp = strrep(temp,' ','_');
    lut{iLut,6} = temp;
    % extract date component from filename
    iDate = lut{iLut,2}(regexp(lut{iLut,2},'20[0-2][0-9]'):regexp(lut{iLut,2},'20[0-2][0-9]')+9);
    lut{iLut,7} = iDate;
    clear temp
end % for iLut

% ID unique groups and experimental dates
Groups = unique(lut(:,6));
groupDate = unique(lut(:,7));
groupDate = strrep(groupDate,'-','_');

% Construct Groups
clear LUT

% Remove any entries associated with errors in previous blocks
findErrors = [];
for iLut = 1:length(lut(:,1))
    lTemp = num2str(lut{iLut,1});
    if strcmp(lTemp,'Error') == 1;
        findErrors = [findErrors; iLut];
    end
    clear lTemp
end % for iLut

% Error check - removes any reps that weren't processed due to errors
if ~isempty(findErrors)
    errorIdx = find(ismember(reps,findErrors));
    reps(errorIdx) = [];
end

expData.lut = lut;
save([varPath expID '_expData_' datestr(date,'yyyy-mm-dd') '.mat'],'expData');

end % function