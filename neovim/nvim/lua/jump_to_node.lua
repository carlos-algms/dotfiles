local function_node_types = {
    "arrow_function",
    "function_declaration",
    "function_definition",
    "function_expression",
    "method_definition",
    "method_declaration",
}

local function is_function_node(node)
    return vim.tbl_contains(function_node_types, node:type())
end

--- @param node TSNode|nil
--- @param types string[]
--- @return TSNode|nil
local function find_parent(node, types)
    if node == nil then
        return nil
    end

    if is_function_node(node) then
        return node
    end

    return find_parent(node:parent(), types)
end

--- @param current_node TSNode|nil
--- @param to_end? boolean
local function jump_to_node(current_node, to_end)
    if not current_node then
        return
    end

    local function test_node(node)
        --
        --
    end

    --- @type TSNode|nil
    local function_node

    if is_function_node(current_node) then
        function_node = current_node
    else
        function_node = find_parent(
            current_node:parent(), -- getting parent to avoid being stuck in the same function
            function_node_types
        )
    end

    if not function_node then
        return
    end

    local start_row, start_col, end_row, end_col = function_node:range()
    local current_row, current_col = unpack(vim.api.nvim_win_get_cursor(0))

    local dest_row = (to_end and end_row or start_row) + 1
    local dest_col = to_end and (end_col - 1) or start_col

    if current_row == dest_row and current_col == dest_col then
        jump_to_node(function_node:parent(), to_end)
        return
    end

    vim.cmd("normal! m'") -- set jump list so I gan jump back
    vim.api.nvim_win_set_cursor(0, { dest_row, dest_col })
end

vim.keymap.set("n", "[f", function()
    local current_node = vim.treesitter.get_node({ ignore_injections = false })
    jump_to_node(current_node, false)
end, {
    desc = "Jump to the start of the current function",
})

vim.keymap.set("n", "]f", function()
    local current_node = vim.treesitter.get_node({ ignore_injections = false })
    jump_to_node(current_node, true)
end, {
    desc = "Jump to the end of the current function",
})
