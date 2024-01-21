---
--- Merge the second table into the first creating a new table, not modifying the originals.
---@param t1 table
---@param t2 table
table.shallowMerge = function(t1, t2)
    local tNew = {}
    for k, v in pairs(t1) do
        if type(k) == "number" then
            table.insert(tNew, v)
        else
            tNew[k] = v
        end
    end

    for k, v in pairs(t2) do
        if type(k) == "number" then
            table.insert(tNew, v)
        else
            tNew[k] = v
        end
    end

    return tNew
end
