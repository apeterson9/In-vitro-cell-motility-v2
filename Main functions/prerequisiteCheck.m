function prerequisiteCheck(expData,stepNums)
    if sum(contains(expData.statusTracker{stepNums,3}{1},'Incomplete')) > 0 ...
       || sum(contains(expData.statusTracker{stepNums,3}{1},'Failed')) > 0
       error('Error! One or more prerequisite steps is incomplete or has failed. Can not proceed!')
    end 
end % function