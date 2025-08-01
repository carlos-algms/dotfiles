return {
    "nvim-treesitter/nvim-treesitter",
    -- tag = "v0.9.1",

    dependencies = {
        "nvim-treesitter/nvim-treesitter-context",
        "nvim-treesitter/nvim-treesitter-textobjects",
        "windwp/nvim-ts-autotag",
    },

    build = ":TSUpdate",

    event = "VeryLazy",

    config = function()
        require("nvim-treesitter.configs").setup({
            -- A list of parser names, or "all" (the five listed parsers should always be installed)
            ensure_installed = {
                "css",
                -- "dap_repl", -- it seems to doesn't exist
                "html",
                "javascript",
                "jsdoc",
                "json",
                "jsonc",
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
            },

            -- Install parsers synchronously (only applied to `ensure_installed`)
            sync_install = false,

            -- Automatically install missing parsers when entering buffer
            -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
            auto_install = true,

            highlight = {
                enable = true,

                -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                -- Using this option may slow down your editor, and you may see some duplicate highlights.
                -- Instead of true it can also be a list of languages
                additional_vim_regex_highlighting = false,
            },
            indent = {
                enable = true,
            },
            ignore_install = {},
            modules = {},

            textobjects = {
                select = {
                    enable = true,

                    -- Automatically jump forward to textobj, similar to targets.vim
                    lookahead = true,

                    include_surrounding_whitespace = false,

                    keymaps = {
                        -- You can use the capture groups defined in textobjects.scm
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",

                        ["ac"] = "@class.outer",

                        ["ic"] = "@class.inner",

                        -- You can also use captures from other query groups like `locals.scm`
                        ["as"] = {
                            query = "@local.scope",
                            query_group = "locals",
                            desc = "Select language scope",
                        },

                        ["ab"] = "@block.outer",
                        ["ib"] = "@block.inner",

                        ["ii"] = "@conditional.inner",
                        ["ai"] = "@conditional.outer",
                    },
                },

                move = {
                    enable = true,
                    set_jumps = true, -- whether to set jumps in the jumplist
                    goto_next_start = {
                        ["]m"] = "@function.outer",
                        -- ["]b"] = {
                        --     query = "@fold",
                        --     query_group = "folds",
                        --     desc = "Next fold",
                        -- },
                    },
                    goto_next_end = {
                        ["]M"] = "@function.outer",
                    },
                    goto_previous_start = {
                        ["[m"] = "@function.outer",
                        -- ["[b"] = {
                        --     query = "@fold",
                        --     query_group = "folds",
                        --     desc = "Previous fold",
                        -- },
                    },
                    goto_previous_end = {
                        ["[M"] = "@function.outer",
                    },
                },
            },
        })

        vim.treesitter.language.register("markdown", "mdx")

        -- https://github.com/nvim-treesitter/nvim-treesitter-context?tab=readme-ov-file#configuration
        require("treesitter-context").setup({
            max_lines = 6,
            multiline_threshold = 3, -- Maximum number of lines to show for a single context
        })

        require("nvim-ts-autotag").setup({
            opts = {
                enable_close_on_slash = true,
            },
        })

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
    end,
}
