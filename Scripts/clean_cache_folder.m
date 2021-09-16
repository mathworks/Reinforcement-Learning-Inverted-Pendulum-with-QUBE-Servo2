% Copyright 2021 The MathWorks, Inc.
function clean_cache_folder(proj)

cd(proj.RootFolder + filesep + "Cache");
delete('*.*');
try
    rmdir('*','s');
catch
    % Do Nothing
end

cd(proj.RootFolder);

end