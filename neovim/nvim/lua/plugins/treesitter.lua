return {
    "nvim-treesitter/nvim-treesitter",
    -- tag = "v0.9.1",

    dependencies = {
        "nvim-treesitter/nvim-treesitter-context",
        -- "nvim-treesitter/nvim-treesitter-textobjects",
        "windwp/nvim-ts-autotag",
    },

    build = ":TSUpdate",

    event = "VeryLazy",

    config = function()
        require("nvim-treesitter.configs").setup({
            -- A list of parser names, or "all" (the five listed parsers should always be installed)
            ensure_installed = {
                "lua",
                "javascript",
                "jsdoc",
                "typescript",
                "tsx",
                "json",
                "jsonc",
                "rust",
                "python",
                "css",
                "scss",
                "styled",
                "html",
                "vim",
                "vimdoc",
                "markdown",
                "markdown_inline",
                "php",
                "phpdoc",
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
            -- textobjects = {
            --     select = {
            --         enable = true,

            --         -- Automatically jump forward to textobj, similar to targets.vim
            --         lookahead = true,

            --         keymaps = {
            --             -- You can use the capture groups defined in textobjects.scm
            --             ["af"] = "@function.outer",
            --             ["if"] = "@function.inner",
            --             ["ac"] = "@class.outer",
            --             -- You can optionally set descriptions to the mappings (used in the desc parameter of
            --             -- nvim_buf_set_keymap) which plugins like which-key display
            --             ["ic"] = {
            --                 query = "@class.inner",
            --                 desc = "Select inner part of a class region",
            --             },
            --             -- You can also use captures from other query groups like `locals.scm`
            --             ["as"] = {
            --                 query = "@scope",
            --                 query_group = "locals",
            --                 desc = "Select language scope",
            --             },
            --             ["ab"] = "@block.outer",
            --         },
            --     },
            --     move = {
            --         enable = true,
            --         set_jumps = true, -- whether to set jumps in the jumplist
            --         goto_next_start = {
            --             ["]m"] = "@function.outer",
            --             ["]b"] = {
            --                 query = "@fold",
            --                 query_group = "folds",
            --                 desc = "Next fold",
            --             },
            --         },
            --         goto_next_end = {
            --             ["]M"] = "@function.outer",
            --         },
            --         goto_previous_start = {
            --             ["[m"] = "@function.outer",
            --             ["[b"] = {
            --                 query = "@fold",
            --                 query_group = "folds",
            --                 desc = "Previous fold",
            --             },
            --         },
            --         goto_previous_end = {
            --             ["[M"] = "@function.outer",
            --         },
            --     },
            -- },
            autotag = {
                enable = true,
            },
        })

        -- https://github.com/nvim-treesitter/nvim-treesitter-context?tab=readme-ov-file#configuration
        require("treesitter-context").setup({
            max_lines = 6,
            multiline_threshold = 2, -- Maximum number of lines to show for a single context
        })

        require("nvim-ts-autotag").setup({
            opts = {
                enable_close_on_slash = true,
            },
        })
    end,
}
