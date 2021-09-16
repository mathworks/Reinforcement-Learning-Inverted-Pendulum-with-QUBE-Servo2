% Copyright 2021 The MathWorks, Inc.
%% Init
clear functions;
proj = currentProject;

%% delete temporary files
clean_cache_folder(proj);

cd(proj.RootFolder + filesep + "Cache");

create_text_file(pwd, 'readme_cache.txt', ...
    'This folder is for temporary files.');

cd(proj.RootFolder + filesep + "Source");
delete('*.*');

create_text_file(pwd, 'readme_source.txt', ...
    'This folder is for temporary files.');

%% Terminate
cd(proj.RootFolder);

allDocs = matlab.desktop.editor.getAll;
allDocs.close;
clear all;
bdclose all;
clc;
