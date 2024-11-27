local M = {}

--- Merge the second table into the first without creating a new copy
--- @param target table
--- @param source table
function M.deep_extend(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            M.deep_extend(target[k], v)
        else
            target[k] = v
        end
    end
end

---
--- Merge the second table into the first creating a new table, not modifying the originals.
---@param t1 table
---@param t2 table
function M.shallowMerge(t1, t2)
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

return M
