local set = vim.opt_local

set.commentstring = "// %s";

(function()
    --- @param node TSNode|nil
    --- @param types string[]
    --- @return TSNode|nil
    local function find_parent(node, types)
        if node == nil then
            return nil
        end

        if vim.tbl_contains(types, node:type()) then
            return node
        end

        return find_parent(node:parent(), types)
    end

    local function jump_to_node(current_node, to_end)
        if not current_node then
            return
        end

        -- FIXIT this should work for any language, not only Ecma
        local function_node = find_parent(
            current_node:parent(), -- getting parent to avoid being stuck in the same function
            { "arrow_function", "function_declaration" }
        )
        if not function_node then
            return
        end

        local start_row, start_col, _end_row, _end_col = function_node:range()
        local current_row, current_col = current_node:range()
        if current_row == start_row and current_col == start_col then
            return jump_to_node(function_node:parent())
        end

        start_row = start_row + 1 -- +1 to accommodate for the buffer line
        vim.api.nvim_win_set_cursor(0, { start_row, start_col })
    end

    vim.keymap.set("n", "[f", function()
        local current_node =
            vim.treesitter.get_node({ ignore_injections = false })
        jump_to_node(current_node)
    end, {
        buffer = true,
    })
end)()
