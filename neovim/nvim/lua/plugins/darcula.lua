return {
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

            -- Misspell on purpose: saci

            vim.defer_fn(function()
                vim.cmd([[ hi clear SpellBad ]])
                vim.cmd([[ hi! SpellBad guisp=#CC666E gui=undercurl ]])
            end, 100)

            -- Fix cursor line overriding other highlights
            vim.cmd(
                [[ call darcula#Hi('CursorLine', darcula#palette.null, darcula#palette.cursorLine, 'NONE') ]]
            )
            vim.cmd([[ call darcula#Hi('Constant', darcula#palette.constant) ]]) -- remove italic from constants
            vim.cmd([[ call darcula#Hi('Type', darcula#palette.number) ]])
            vim.cmd([[ call darcula#Hi('SpellBad', darcula#palette.errorMsg) ]])
            vim.cmd([[ hi! link Delimiter NormalFg ]])
            vim.cmd([[ hi! link @label.json Constant ]]) -- fix JSON properties

            vim.cmd([[ hi! link @identifier.lua NormalFg ]])

            -- TS / TSX
            vim.cmd([[ hi! link @type.tsx @identifier ]]) -- Fix default imports colored as types
            vim.cmd([[ hi! link @type.typescript Type ]])
            vim.cmd([[ hi! link @lsp.type.enum.typescriptreact @identifier ]])
            vim.cmd([[ hi! link @lsp.type.enum.typescript @identifier ]])
            vim.cmd([[ hi! link @lsp.type.type.typescript Type ]])
            vim.cmd([[ hi! link @lsp.type.typeParameter.typescript Type ]])
            vim.cmd([[ hi! link @property.tsx Constant]])
            vim.cmd([[ hi! link @property.typescript Constant]])
            vim.cmd([[ hi! link @lsp.type.property.typescriptreact Constant]])
            vim.cmd([[ hi! link @lsp.type.property.typescript Constant]])
            vim.cmd([[ hi! link @constant.builtin.tsx Keyword]])
            vim.cmd([[ hi! link @constant.builtin.typescript Keyword]])
            vim.cmd([[ hi! link @constant.builtin.javascript Keyword]])
            vim.cmd([[ hi! link @include.tsx Keyword ]]) -- Fix import colors
            vim.cmd([[ hi! link @include.typescript Keyword ]]) -- Fix import colors
            vim.cmd([[ hi! link @boolean.typescript Keyword ]])
            vim.cmd([[ hi! link @boolean.tsx Keyword ]])

            -- Docs Popup
            vim.cmd([[ hi! link typescriptImport Keyword ]])
            vim.cmd([[ hi! link typescriptVariable Keyword ]])
            vim.cmd([[ hi! link typescriptVariableDeclaration @identifier ]])
            vim.cmd([[ hi! link typescriptTypeReference @type ]])
            vim.cmd([[ hi! link typescriptArrayMethod @function ]])
            vim.cmd([[ hi! link typescriptCall @identifier ]])
            -- vim.cmd([[ hi! link typescriptFuncCallArg @identifier ]])
            vim.cmd([[ hi! clear typescriptFuncCallArg ]])
            vim.cmd([[ hi! link typescriptArrowFuncArg @identifier ]])
            vim.cmd([[ hi! link typescriptIdentifierName Keyword ]])

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
            vim.cmd([[ hi! link @selector Function ]])
            vim.cmd([[ hi! link @color Constant ]])
            vim.cmd([[ hi! link @unit Keyword ]])

            -- SCSS
            vim.cmd([[ hi! link @include.scss Keyword ]])

            -- PHP
            vim.cmd([[ hi! link @tag.php Error ]])
            vim.cmd([[ hi! link @type.qualifier.php Keyword ]])
            vim.cmd([[ hi! link @variable.builtin.php Keyword ]]) -- $this
            vim.cmd([[ hi! link @constant.builtin.php Keyword ]])
            vim.cmd([[ hi! link @class.php @variable ]])
            vim.cmd([[ hi! link @constructor.php @function ]])
            vim.cmd([[ hi! link @operator.php NormalFg ]])
            vim.cmd([[ hi! link @property.php Constant ]])
            vim.cmd([[ hi! link @property.declaration.php Identifier ]])

            -- Lua
            vim.cmd(
                [[ hi! link @lsp.typemod.function.defaultLibrary.lua Keyword ]]
            )
            vim.cmd([[ hi! link @punctuation.bracket.lua NormaFg ]])
            vim.cmd([[ hi! link @constructor.lua NormaFg ]])
            vim.cmd([[ hi! link @lsp.mod.global.lua ErrorMsg ]])
            vim.cmd([[ hi! link @function.builtin.lua Keyword ]])
            vim.cmd([[ hi! link @boolean.lua Keyword ]])
            vim.cmd([[ hi! link @unit.css Keyword ]])
            vim.cmd([[ hi! link @type.qualifier.css Keyword ]])
            vim.cmd([[ hi! link @field.lua Constant ]])
            vim.cmd([[ hi! link @lsp.type.property.lua Constant ]])

            -- bash
            vim.cmd([[ hi! link @function.builtin.bash Function ]])
        end,
    },
    {
        enabled = false,
        "briones-gabriel/darcula-solid.nvim",
        dependencies = {
            "rktjmp/lush.nvim",
        },
        lazy = false,
        priority = 1000,
        -- config = function()
        --         --     vim.o.background = "dark"
        --                 --     vim.cmd.colorscheme("darcula-solid")
        --                         --     vim.opt.termguicolors = true
        --                                 -- end,
    },
}

-- { call darcula#Hi('Constant', darcula#palette.constant) }
