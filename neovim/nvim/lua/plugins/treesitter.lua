return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",

    -- main branch does NOT support lazy-loading
    lazy = false,

    build = ":TSUpdate",

    dependencies = {
        {
            "nvim-treesitter/nvim-treesitter-textobjects",
            branch = "main",
        },
        {
            "nvim-treesitter/nvim-treesitter-context",
            opts = {
                max_lines = 6,
                multiline_threshold = 3,
            },
        },
        {
            "windwp/nvim-ts-autotag",
            opts = {
                opts = {
                    enable_close_on_slash = true,
                },
            },
        },
    },

    config = function()
        -- Parser installation (replaces ensure_installed)
        require("nvim-treesitter").install({
            "css",
            "html",
            "javascript",
            "jsdoc",
            "json",
            "lua",
            "markdown_inline",
            "markdown",
            "php",
            "phpdoc",
            "python",
            "regex",
            "rust",
            "scss",
            "styled",
            "tsx",
            "typescript",
            "vim",
            "vimdoc",
            "yaml",
        })

        -- Treesitter highlighting is NOT automatic in 0.12, enable it globally
        vim.api.nvim_create_autocmd("FileType", {
            callback = function()
                pcall(vim.treesitter.start)
            end,
        })

        vim.treesitter.language.register("markdown", "mdx")

        vim.opt.foldmethod = "expr"
        vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

        -- Enable folding code with color highlighting
        -- https://www.reddit.com/r/neovim/comments/1fzn1zt/custom_fold_text_function_with_treesitter_syntax/
        local function fold_virt_text(result, s, lnum, coloff)
            if not coloff then
                coloff = 0
            end

            local text = ""
            local hl

            for i = 1, #s do
                local char = s:sub(i, i)
                local hls =
                    vim.treesitter.get_captures_at_pos(0, lnum, coloff + i - 1)
                local _hl = hls[#hls]
                if _hl then
                    local new_hl = "@" .. _hl.capture
                    if new_hl ~= hl then
                        table.insert(result, { text, hl })
                        text = ""
                        hl = nil
                    end
                    text = text .. char
                    hl = new_hl
                else
                    text = text .. char
                end
            end
            table.insert(result, { text, hl })
        end

        function _G.custom_foldtext()
            local start = vim.fn
                .getline(vim.v.foldstart)
                :gsub("\t", string.rep(" ", vim.o.tabstop))
            local end_str = vim.fn.getline(vim.v.foldend)
            local end_ = vim.trim(end_str)
            local result = {}
            fold_virt_text(result, start, vim.v.foldstart - 1)
            table.insert(result, { " ... ", "Delimiter" })
            fold_virt_text(
                result,
                end_,
                vim.v.foldend - 1,
                #(end_str:match("^(%s+)") or "")
            )
            return result
        end

        vim.opt.foldtext = "v:lua.custom_foldtext()"

        -- Textobjects setup
        require("nvim-treesitter-textobjects").setup({
            select = {
                lookahead = true,
                include_surrounding_whitespace = false,
            },
            move = {
                set_jumps = true,
            },
        })

        local select = require("nvim-treesitter-textobjects.select")
        local move = require("nvim-treesitter-textobjects.move")

        -- Select keymaps
        vim.keymap.set({ "x", "o" }, "af", function()
            select.select_textobject("@function.outer", "textobjects")
        end, { desc = "Select outer function" })
        vim.keymap.set({ "x", "o" }, "if", function()
            select.select_textobject("@function.inner", "textobjects")
        end, { desc = "Select inner function" })
        vim.keymap.set({ "x", "o" }, "ac", function()
            select.select_textobject("@class.outer", "textobjects")
        end, { desc = "Select outer class" })
        vim.keymap.set({ "x", "o" }, "ic", function()
            select.select_textobject("@class.inner", "textobjects")
        end, { desc = "Select inner class" })
        vim.keymap.set({ "x", "o" }, "as", function()
            select.select_textobject("@local.scope", "locals")
        end, { desc = "Select language scope" })
        vim.keymap.set({ "x", "o" }, "ab", function()
            select.select_textobject("@block.outer", "textobjects")
        end, { desc = "Select outer block" })
        vim.keymap.set({ "x", "o" }, "ib", function()
            select.select_textobject("@block.inner", "textobjects")
        end, { desc = "Select inner block" })
        vim.keymap.set({ "x", "o" }, "ai", function()
            select.select_textobject("@conditional.outer", "textobjects")
        end, { desc = "Select outer conditional" })
        vim.keymap.set({ "x", "o" }, "ii", function()
            select.select_textobject("@conditional.inner", "textobjects")
        end, { desc = "Select inner conditional" })

        -- Move keymaps
        vim.keymap.set({ "n", "x", "o" }, "]m", function()
            move.goto_next_start("@function.outer", "textobjects")
        end, { desc = "Next function start" })
        vim.keymap.set({ "n", "x", "o" }, "]M", function()
            move.goto_next_end("@function.outer", "textobjects")
        end, { desc = "Next function end" })
        vim.keymap.set({ "n", "x", "o" }, "[m", function()
            move.goto_previous_start("@function.outer", "textobjects")
        end, { desc = "Previous function start" })
        vim.keymap.set({ "n", "x", "o" }, "[M", function()
            move.goto_previous_end("@function.outer", "textobjects")
        end, { desc = "Previous function end" })
    end,
}
