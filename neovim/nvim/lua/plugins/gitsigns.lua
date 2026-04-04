local set = vim.keymap.set
local loaded = false

local function load_gitsigns()
    if loaded then
        return
    end
    loaded = true

    vim.pack.add({
        "https://github.com/lewis6991/gitsigns.nvim",
    })

    local function jumpToNextHunk()
        if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
        else
            vim.cmd("Gitsigns next_hunk")
        end
    end

    local function jumpToPrevHunk()
        if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
        else
            vim.cmd("Gitsigns prev_hunk")
        end
    end

    -- I'm remapping parens, as I never use them to navigate paragraphs
    set("n", ")", jumpToNextHunk, { desc = "next change hunk" })
    set("n", "]c", jumpToNextHunk, { desc = "next change hunk (same as ]c)" })
    set("n", "[c", jumpToPrevHunk, { desc = "prev change hunk" })
    set("n", "(", jumpToPrevHunk, { desc = "prev change hunk (same as [c)" })

    require("gitsigns").setup({
        diff_opts = {
            -- https://github.com/lewis6991/gitsigns.nvim/blob/main/doc/gitsigns.txt
            internal = true,
            algorithm = "histogram",
            indent_heuristic = true,
            ignore_whitespace = true,
            ignore_whitespace_change = true,
            ignore_whitespace_change_at_eol = true,
            ignore_blank_lines = false,
        },
        current_line_blame = false, -- I don't think he virtual text is useful
        current_line_blame_opts = {
            ignore_whitespace = true,
        },

        ---@type vim.api.keyset.win_config
        preview_config = {
            style = "minimal",
            relative = "cursor",
            row = -1,
            col = 2,
            border = "rounded",
        },

        on_attach = function(bufnr)
            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                set(mode, l, r, opts)
            end

            map("n", "<leader>gv", ":Gitsigns preview_hunk<CR>", { desc = "Show hunk preview", silent = true })
            map({ "n", "v" }, "<leader>g-", ":Gitsigns reset_hunk<CR>", { desc = "Reset hunk", silent = true })
            map({ "n", "v" }, "<leader>g=", "<cmd>Gitsigns stage_hunk<CR>", { desc = "Stage hunk", silent = true })
        end,
    })
end

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        load_gitsigns()
    end,
    once = true,
})
