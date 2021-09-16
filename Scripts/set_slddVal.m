% Copyright 2021 The MathWorks, Inc.
function set_slddVal(sldd_name, val_name, val)

sldd_obj = Simulink.data.dictionary.open(sldd_name);
data_set_obj = getSection(sldd_obj, 'Design Data');
data_entry = getEntry(data_set_obj, val_name);

valObj = getValue(data_entry);
if ischar(val)
    valObj.Value = slexpr(val);
else
    valObj.Value = val;
end
setValue(data_entry, valObj);

saveChanges(sldd_obj);

end