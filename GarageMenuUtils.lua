GarageMenuUtils = {}
local g_currentModName = g_currentModName

function GarageMenuUtils.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[GarageMenuUtils.deepcopy(orig_key)] = GarageMenuUtils.deepcopy(orig_value)
        end
        setmetatable(copy, GarageMenuUtils.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
