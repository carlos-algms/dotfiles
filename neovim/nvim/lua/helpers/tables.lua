local M = {}

--- Merge the second table into the first without creating a new copy
--- @param target table
--- @param source table
function M.deep_extend(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            M.deep_extend(target[k], v)
        elseif type(k) == "number" then
            table.insert(target, v)
        else
            target[k] = v
        end
    end
end

return M
