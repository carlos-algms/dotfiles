return {
    {
        "briones-gabriel/darcula-solid.nvim",
        dependencies = {
            "rktjmp/lush.nvim",
        },
        enabled = false,
        lazy = false,
        priority = 1000,
        -- config = function()
        --     vim.o.background = "dark"
        --     vim.cmd.colorscheme("darcula-solid")
        --     vim.opt.termguicolors = true
        -- end,
    },
    {
        "doums/darcula",
        as = "darcula",
        enabled = true,
        lazy = false,
        priority = 1000,
        config = function()
            vim.opt.termguicolors = true
            vim.o.background = "dark"

            vim.cmd.colorscheme("darcula")

            vim.cmd([[ call darcula#Hi('Constant', darcula#palette.constant) ]]) -- remove italic from constants
            vim.cmd([[ call darcula#Hi('Type', darcula#palette.number) ]])
            vim.cmd([[ call darcula#Hi('SpellBad', darcula#palette.errorMsg) ]])
            vim.cmd([[ hi! link @type.tsx NormalFg ]]) -- Fix default imports colored as types
            vim.cmd([[ hi! link @type.typescript Type ]])
            vim.cmd([[ hi! link @lsp.type.type.typescript Type ]])
            vim.cmd([[ hi! link @lsp.type.typeParameter.typescript Type ]])
            vim.cmd([[ hi! link @property.tsx Constant]])
            vim.cmd([[ hi! link @property.typescript Constant]])
            vim.cmd([[ hi! link @lsp.type.property.typescriptreact Constant]])
            vim.cmd([[ hi! link @lsp.type.property.typescript Constant]])
            vim.cmd([[ hi! link @constant.builtin.tsx Keyword]])
            vim.cmd([[ hi! link @constant.builtin.typescript Keyword]])
            vim.cmd([[ hi! link @include.tsx Keyword ]]) -- Fix import colors
            vim.cmd([[ hi! link @include.typescript Keyword ]]) -- Fix import colors
            vim.cmd([[ hi! link @boolean.typescript Keyword ]])
            vim.cmd([[ hi! link @boolean.tsx Keyword ]])
            vim.cmd([[ hi! link @label.json Constant ]]) -- fix JSON properties
            vim.cmd([[ hi! link Delimiter Normal ]]) -- fix TSX properties

            -- JSX
            vim.cmd([[ hi! link @constructor.tsx Function ]])
            vim.cmd([[ hi! link @tag.tsx Function ]])
            vim.cmd([[ hi! link @constructor.tsx Function ]])
            vim.cmd([[ hi! link @tag.delimiter.tsx Function ]])
            vim.cmd([[ hi! link @tag.attribute.tsx NormalFg ]])

            -- HTML
            vim.cmd([[ hi! link @text.title.html @text ]])
            vim.cmd([[ hi! link @tag.html Function ]])
            vim.cmd([[ hi! link @operator.html Function ]])
            vim.cmd([[ hi! link @constant.html Function ]])
            vim.cmd([[ hi! link @tag.delimiter.html Function ]])
            vim.cmd([[ hi! link @tag.attribute.html NormalFg ]])

            -- CSS
            vim.cmd([[ hi! link @punctuation.delimiter.css Function ]])
            vim.cmd([[ hi! link @type.css Function ]])
            vim.cmd([[ hi! link @punctuation.delimiter.css NormaFg ]])

            -- SCSS
            vim.cmd([[ hi! link @include.scss Keyword ]])

            -- Lua
            vim.cmd([[ hi! link @lsp.mod.global.lua ErrorMsg ]])
            vim.cmd([[ hi! link @function.builtin.lua Keyword ]])
            vim.cmd([[ hi! link @field.lua Constant ]])
            vim.cmd([[ hi! link @lsp.type.property.lua Constant ]])
        end,
    },
}

-- { call darcula#Hi('Constant', darcula#palette.constant) }
