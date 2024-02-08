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
                vim.cmd([[ hi! SpellBad guisp=#6897bb gui=undercurl ]])
            end, 100)

            -- making the BG darker, and the FG lighter
            vim.cmd([[ hi! Normal guibg=#1c1c1c guifg=#bac4cf ]])
            vim.cmd([[ hi! NormalFg guifg=#bac4cf ]])
            -- UI and nVim windows
            vim.cmd([[ hi! NormalFloat guibg=#2B2B2B guifg=#bac4cf ]])
            vim.cmd([[ hi! link LazyH2 Function ]])
            vim.cmd([[ hi! link LazyReasonStart Type ]])
            vim.cmd([[ hi! link LuaFunctionBlock Function ]])
            vim.cmd([[ hi! link LazyCommitType Constant ]])
            vim.cmd([[ hi! link @string.special.url.gitcommit NormalFg ]])

            -- Fix cursor line overriding other highlights
            vim.cmd(
                [[ call darcula#Hi('CursorLine', darcula#palette.null, darcula#palette.cursorLine, 'NONE') ]]
            )
            vim.cmd([[ call darcula#Hi('Constant', darcula#palette.constant) ]]) -- remove italic from constants
            vim.cmd([[ call darcula#Hi('Type', darcula#palette.number) ]])
            vim.cmd([[ call darcula#Hi('SpellBad', darcula#palette.errorMsg) ]])
            vim.cmd([[ hi! link Delimiter NormalFg ]])
            vim.cmd([[ hi! link @identifier NormalFg ]])
            vim.cmd([[ hi! link @label Constant ]]) -- fix JSON properties
            vim.cmd([[ hi! link @property Constant ]]) -- will it fix all properties in all languages?
            vim.cmd([[ hi! link @string.regexp Constant ]])
            vim.cmd([[ hi! link @string.escape Constant ]])
            vim.cmd([[ hi! link @boolean Keyword ]])
            vim.cmd([[ hi! link @constructor @identifier ]])
            vim.cmd([[ hi! link @variable @identifier ]])
            vim.cmd([[ hi! link @variable.member Constant ]])
            vim.cmd([[ hi! link @lsp.type.class @identifier ]])
            vim.cmd([[ hi! link @lsp.type.namespace @identifier ]])

            -- TS / TSX
            -- Review this, in previews, LSP doesn't start, so types are white instead of blue
            -- vim.cmd([[ hi! link @type.tsx @identifier ]]) -- Fix default imports colored as types
            vim.cmd([[ hi! link @lsp.type.enum.typescriptreact @identifier ]])
            vim.cmd([[ hi! link @lsp.type.enum.typescript @identifier ]])
            vim.cmd([[ hi! link @lsp.type.type.typescript Type ]])
            vim.cmd([[ hi! link @lsp.type.typeParameter.typescript Type ]])
            vim.cmd([[ hi! link @lsp.type.property Constant]])
            vim.cmd([[ hi! link @tag Function]])
            vim.cmd([[ hi! link @constant.builtin.tsx Keyword]])
            vim.cmd([[ hi! link @constant.builtin.typescript Keyword]])
            vim.cmd([[ hi! link @constant.builtin.javascript Keyword]])
            vim.cmd([[ hi! link @include.tsx Keyword ]]) -- Fix import colors
            vim.cmd([[ hi! link @include.typescript Keyword ]]) -- Fix import colors
            vim.cmd([[ hi! link @punctuation.special.typescript Keyword ]])
            vim.cmd([[ hi! link @punctuation.special.tsx Keyword ]])
            vim.cmd([[ hi! link @punctuation.special.javascript Keyword ]])
            vim.cmd([[ hi! link @type.literal Type ]])
            vim.cmd([[ hi! link @type.literal.string String ]])
            vim.cmd([[ hi! link @comment.documentation.typescript String ]])

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
            vim.cmd([[ hi! link htmlString String ]])
            vim.cmd([[ hi! link htmlSpecialChar Constant ]])
            vim.cmd([[ hi! link @text.title.html @text ]])
            vim.cmd([[ hi! link @tag.html Function ]])
            vim.cmd([[ hi! link @operator.html Function ]])
            vim.cmd([[ hi! link @constant.html Function ]])
            vim.cmd([[ hi! link @tag.delimiter.html Function ]])
            vim.cmd([[ hi! link @tag.attribute.html NormalFg ]])

            -- YAML
            vim.cmd([[ hi! link @property.yaml Function ]])

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
            -- vim.cmd([[ hi! link @property.php Constant ]])
            vim.cmd([[ hi! link @property.declaration.php Identifier ]])
            vim.cmd([[ hi! link @function.builtin.php Keyword ]])
            vim.cmd([[ hi! link @attribute.phpdoc Keyword ]])
            vim.cmd([[ hi! link @spell.phpdoc String ]])

            -- Markdown
            vim.cmd([[ hi! link markdownH1 Keyword ]])
            vim.cmd([[ hi! link markdownH1Delimiter Keyword ]])
            vim.cmd([[ hi! link markdownH2 Keyword ]])
            vim.cmd([[ hi! link markdownH2Delimiter Keyword ]])
            vim.cmd([[ hi! link markdownCodeBlock NormalFg ]])
            vim.cmd([[ hi! link markdownUrl String ]])
            vim.cmd([[ hi! link markdownCodeDelimiter Keyword ]])
            vim.cmd(
                [[ call darcula#Hi('markdownCode', darcula#palette.fg, darcula#palette.null, 'bold') ]]
            )
            vim.cmd([[ hi! link @markup.heading.1.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.2.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.3.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.4.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.5.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.6.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.1.marker.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.2.marker.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.3.marker.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.4.marker.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.5.marker.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.heading.6.marker.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.list.markdown Keyword ]])
            vim.cmd([[ hi! link @markup.raw.block.markdown Keyword ]])
            vim.cmd([[ hi! link @label.markdown @type ]])
            vim.cmd([[ hi! link @markup.raw.markdown_inline @type ]])
            vim.cmd(
                [[ call darcula#Hi('@markup.raw.markdown_inline', darcula#palette.fg, darcula#palette.null, 'bold') ]]
            )
            vim.cmd(
                [[ call darcula#Hi('@markup.italic.markdown_inline', darcula#palette.fg, darcula#palette.null, 'italic,bold') ]]
            )
            vim.cmd(
                [[ hi! link @markup.emphasis.delimiter @markup.italic.markdown_inline ]]
            )
            vim.cmd([[ hi! link @markup.strong.markdown_inline Keyword ]])
            vim.cmd([[ hi! link @delimiter.markdown_inline Keyword ]])
            vim.cmd([[ hi! link @markup.link.label.markdown_inline String ]])
            vim.cmd([[ hi! link @markup.list_item.complete.markdown Comment ]])
            vim.cmd([[ hi! link @lsp.type.class.markdown Comment ]])
            vim.cmd([[ hi! link @markup.list.checked.markdown Comment ]])
            vim.cmd([[ hi! link markdownCode Keyword ]])
            vim.cmd([[ hi! link FloatTitle NormalFg ]])

            -- Lua
            vim.cmd(
                [[ hi! link @lsp.typemod.function.defaultLibrary.lua Keyword ]]
            )
            vim.cmd([[ hi! link @punctuation.bracket.lua NormaFg ]])
            vim.cmd([[ hi! link @constructor.lua NormaFg ]])
            vim.cmd([[ hi! link @lsp.mod.global.lua ErrorMsg ]])
            vim.cmd([[ hi! link @function.builtin.lua Keyword ]])
            vim.cmd([[ hi! link @unit.css Keyword ]])
            vim.cmd([[ hi! link @type.qualifier.css Keyword ]])
            vim.cmd([[ hi! link @field.lua Constant ]])
            vim.cmd([[ hi! link @variable.member.lua Constant ]])
            vim.cmd([[ hi! link @function.lua Function ]])
            vim.cmd([[ hi! link @lsp.type.property.lua Constant ]])
            vim.cmd([[ hi! link @lsp.type.keyword.lua Keyword ]])
            vim.cmd([[ hi! link @identifier.lua NormalFg ]])

            -- bash
            vim.cmd([[ hi! link @function.builtin.bash Function ]])
            vim.cmd([[ hi! link zshFunction Function ]])
            vim.cmd([[ hi! link zshDeref Constant ]])

            -- DIFF
            vim.cmd([[ hi! DiffDelete guibg=#523939]])

            -- editor config
            vim.cmd([[ hi! link editorconfigProperty Keyword ]])
            vim.cmd([[ hi! link dosiniHeader @identifier ]])

            -- Telescope
            vim.cmd([[ hi! link TelescopeTitle Function ]])
            vim.cmd([[ hi! link TelescopeMatching IncSearch ]])
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
