% Copyright 2021 The MathWorks, Inc.
function open_index()
%% check locale
locale = feature('locale');
lang = split(locale.messages, '.');

%% Open suitable language file.
if strcmp(lang{1}, 'ja_JP')
    edit('quanserservo2_control_index_ja');
else
    edit('quanserservo2_control_index');
end

end
