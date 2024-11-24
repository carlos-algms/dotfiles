local M = {}

M.cache = {}

--- @param key string: The key to group the caching.
--- @param cb function: The callback function to execute if the cache is empty.
M.cacheByKey = function(key, cb)
    if M.cache[key] == nil then
        M.cache[key] = {}
    end

    --- @param path string: The buffer path.
    --- @param params table: The parameters to pass to the callback function.
    return function(path, params)
        if M.cache[key][path] == nil then
            M.cache[key][path] = cb(params) or false
        end
        return M.cache[key][path]
    end
end

--- @param key string: The key to reset the cache.
M.reset = function(key)
    if key then
        M.cache[key] = {}
        return
    end
end

return M
