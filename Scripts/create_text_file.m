% Copyright 2021 The MathWorks, Inc.
function create_text_file(dist_dir, file_name, file_text)
%%
current_dir = pwd;
cd(dist_dir);

%%
writematrix(file_text, file_name);

%%
cd(current_dir);

end