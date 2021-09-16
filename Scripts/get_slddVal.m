% Copyright 2021 The MathWorks, Inc.
function out = get_slddVal(sldd_name, val_name)

sldd_obj = Simulink.data.dictionary.open(sldd_name);
data_set_obj = getSection(sldd_obj, 'Design Data');
data_entry = getEntry(data_set_obj, val_name);
ts_obj = getValue(data_entry);
out = ts_obj.Value;

end