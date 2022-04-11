function fpath = formatPath(path)
    if path(end) ~= filesep
        path(end+1) = filesep;
    end
    fpath = path;
end % function