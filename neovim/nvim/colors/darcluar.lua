local M = {}

---@class Palette
M.pallet = {
    bg = "#1c1c1c",
    fg = "#bac4cf",

    constant = "#9876AA",
    comment = "#808080",
    callable = "#FFC66D",
    string = "#6A8759",
    type = "#6897BB",
    keyword = "#CC7832",
    preProc = "#BBB529",
    success = "#96f291",
    error = "#CC666E",
    errorMsg = "#BC3F3C",
    lineNumber = "#606366",
    gutter = "#313335",
    menu = "#262626",
    muted = "#606060",
    cursor = "#BBBBBB",
    cursorLineNr = "#A4A3A3",
    selection = "#214283",
    diffAddBg = "#294436",
    diffTextBg = "#385570",
    diffDeleteBg = "#523939",
    diffChangeBg = "#303c47",
    stdOutput = "#BBBBBB",
    uiBgActive = "#454546",
    uiBgInactive = "#353435",
}

---@class Theme
---@field highlights table<string, vim.api.keyset.highlight>
---@field links table<string, string>
M.theme = {
    highlights = {
        ["@markup.strong.markdown_inline"] = {
            bold = true,
            fg = M.pallet.keyword,
        },
        Bold = { bold = true },
        Boolean = { fg = M.pallet.keyword },
        Comment = { fg = M.pallet.comment },
        Conceal = { fg = M.pallet.muted },
        Constant = { fg = M.pallet.constant }, -- TODO: change this to identifier and add a Property highlight
        Cursor = { fg = M.pallet.cursor },
        CursorLine = { bg = M.pallet.gutter },
        DiagnosticSignError = { fg = M.pallet.errorMsg, bg = M.pallet.gutter },
        DiagnosticSignHint = { fg = M.pallet.fg, bg = M.pallet.gutter },
        DiagnosticSignInfo = { fg = M.pallet.type, bg = M.pallet.gutter },
        DiagnosticSignWarn = { fg = M.pallet.keyword, bg = M.pallet.gutter },
        DiagnosticUnderlineError = { undercurl = true, sp = M.pallet.errorMsg },
        DiagnosticUnderlineHint = { undercurl = true, sp = M.pallet.fg },
        DiagnosticUnderlineInfo = { undercurl = true, sp = M.pallet.type },
        DiagnosticUnderlineWarn = { undercurl = true, sp = M.pallet.keyword },
        DiffAdd = { bg = M.pallet.diffAddBg },
        DiffChange = { bg = M.pallet.diffChangeBg },
        DiffDelete = { bg = M.pallet.diffDeleteBg },
        DiffText = { bg = M.pallet.diffTextBg },
        Error = { fg = M.pallet.error },
        ErrorMsg = { fg = M.pallet.errorMsg },
        Function = { fg = M.pallet.callable },
        Identifier = { fg = M.pallet.fg },
        Keyword = { fg = M.pallet.keyword },
        LineNr = { fg = M.pallet.lineNumber, bg = M.pallet.gutter },
        MoreMsg = { fg = M.pallet.stdOutput },
        NonText = { fg = M.pallet.muted },
        Normal = { bg = M.pallet.bg },
        Operator = { fg = M.pallet.keyword },
        Pmenu = { bg = M.pallet.menu },
        PreProc = { fg = M.pallet.preProc },
        String = { fg = M.pallet.string },
        TabLine = { fg = M.pallet.muted, bg = M.pallet.uiBgInactive }, -- the not current tab
        TabLineFill = { bg = M.pallet.bg }, -- the entire tabline behind tabs
        TabLineSel = { fg = M.pallet.fg, bg = M.pallet.uiBgActive }, -- the current tab
        Title = { fg = M.pallet.keyword, bold = true },
        Type = { fg = M.pallet.type },
        Visual = { bg = M.pallet.selection },
        WinSeparator = { fg = M.pallet.muted },
    },

    links = {
        ["@attribute.css"] = "@identifier",
        ["@attribute.diff"] = "Comment",
        ["@attribute.phpdoc"] = "@keyword",
        ["@attribute.sql"] = "@keyword", -- ASC, DESC, etc..
        ["@character.special"] = "Keyword",
        ["@class"] = "@identifier",
        ["@comment.documentation"] = "@string",
        ["@constant.bash"] = "Constant",
        ["@constant.builtin"] = "Keyword",
        ["@constant.html"] = "Function",
        ["@constant"] = "@identifier", -- I don't like the blink between constant to variable when the LSP kicks in
        ["@constructor.lua"] = "Identifier",
        ["@constructor.php"] = "@function",
        ["@constructor"] = "@function",
        ["@delimiter.markdown_inline"] = "@keyword",
        ["@fenced_code_block.markdown"] = "Keyword", -- the ``` blocks
        ["@function.builtin.php"] = "@keyword",
        ["@function.builtin"] = "@function",
        ["@identifier"] = "Identifier",
        ["@import"] = "@identifier",
        ["@keyword.directive.xml"] = "@tag",
        ["@label.diff"] = "@keyword",
        ["@label.javascript"] = "@identifier",
        ["@label.markdown"] = "@type",
        ["@label.typescript"] = "@identifier",
        ["@label.vimdoc"] = "@string",
        ["@lsp.type.class"] = "@none",
        ["@lsp.type.enum"] = "@none",
        ["@lsp.type.enumMember.terraform"] = "@string",
        ["@lsp.type.enumMember"] = "Constant",
        ["@lsp.type.keyword"] = "@keyword",
        ["@lsp.type.macro.lua"] = "Type",
        ["@lsp.type.namespace"] = "@none",
        ["@lsp.type.parameter"] = "@none",
        ["@lsp.type.property"] = "@none",
        ["@lsp.type.type.terraform"] = "Keyword",
        ["@lsp.type.variable.dockerfile"] = "Constant",
        ["@lsp.type.variable"] = "@none",
        ["@markup.heading.1.astro"] = "@none",
        ["@markup.heading.1.html"] = "@none",
        ["@markup.heading.1.tsx"] = "@none",
        ["@markup.heading.2.astro"] = "@none",
        ["@markup.heading.2.html"] = "@none",
        ["@markup.heading.2.tsx"] = "@none",
        ["@markup.heading.3.astro"] = "@none",
        ["@markup.heading.3.html"] = "@none",
        ["@markup.heading.3.tsx"] = "@none",
        ["@markup.heading.4.astro"] = "@none",
        ["@markup.heading.4.html"] = "@none",
        ["@markup.heading.4.tsx"] = "@none",
        ["@markup.heading.5.astro"] = "@none",
        ["@markup.heading.5.html"] = "@none",
        ["@markup.heading.5.tsx"] = "@none",
        ["@markup.heading.6.astro"] = "@none",
        ["@markup.heading.6.html"] = "@none",
        ["@markup.heading.6.tsx"] = "@none",
        ["@markup.heading.astro"] = "@none",
        ["@markup.heading.html"] = "@none",
        ["@markup.heading.tsx"] = "@none",
        ["@markup.heading"] = "Keyword",
        ["@markup.link.label.markdown_inline"] = "@string",
        ["@markup.link.label"] = "@none",
        ["@markup.list_item.complete.markdown"] = "@comment",
        ["@markup.list.checked"] = "@comment",
        ["@markup.list"] = "Keyword",
        ["@markup.raw.block.markdown"] = "@none",
        ["@markup.raw.delimiter.markdown"] = "Keyword",
        ["@markup.raw.markdown_inline"] = "Bold",
        ["@markup.strong"] = "@none",
        ["@module.builtin.lua"] = "@identifier",
        ["@property.css"] = "@identifier",
        ["@property.declaration.php"] = "@identifier",
        ["@property.styled"] = "@identifier",
        ["@property.yaml"] = "@function",
        ["@property"] = "Constant",
        ["@punctuation.accessor.php"] = "@keyword",
        ["@punctuation.bracket.lua"] = "Identifier",
        ["@punctuation.delimiter.jsdoc"] = "@comment.documentation",
        ["@punctuation.special.astro"] = "@none",
        ["@punctuation.special.diff"] = "Identifier",
        ["@punctuation.special"] = "@keyword",
        ["@punctuation"] = "Identifier",
        ["@selector"] = "@function",
        ["@string.escape"] = "Constant",
        ["@string.regexp.ssh_config"] = "String",
        ["@string.regexp"] = "Constant",
        ["@string.special.path.diff"] = "@identifier",
        ["@string.special.path.gitcommit"] = "@identifier",
        ["@string.special.url.gitcommit"] = "@identifier",
        ["@string.special.url"] = "@none",
        ["@string.special.vimdoc"] = "@function",
        ["@subject.gitcommit"] = "@identifier",
        ["@tag.attribute"] = "@identifier",
        ["@tag.builtin"] = "@tag",
        ["@tag.php"] = "Error",
        ["@tag"] = "@function",
        ["@type.astro"] = "@none", -- it was flagging JSX tags as types
        ["@type.builtin"] = "@function",
        ["@type.css"] = "@function",
        ["@type.javascript"] = "Function",
        ["@type.literal.string"] = "@string",
        ["@type.literal"] = "@type",
        ["@type.qualifier.php"] = "@keyword",
        ["@type.tsx"] = "@none", -- Same as Constants, the color switches after lsp kicks in
        ["@type.typescript"] = "@none", -- Same as Constants, the color switches after lsp kicks in
        ["@unit"] = "@keyword",
        ["@variable.builtin.php"] = "Keyword",
        ["@variable.builtin.this"] = "Keyword",
        ["@variable.builtin"] = "Identifier",
        ["@variable.member"] = "Constant",
        ["@variable.parameter.vimdoc"] = "@type",
        ["@variable"] = "@identifier",
        ["phpDefine"] = "@keyword",
        ["phpStorageClass"] = "@keyword",
        ["SnacksStatusColumnMark"] = "DiagnosticSignInfo",
        Added = "DiffAdd",
        Changed = "DiffChange",
        CmpItemKindClass = "Type",
        CmpItemKindConstant = "Constant",
        CmpItemKindEnumMember = "Constant",
        CmpItemKindField = "Constant",
        CmpItemKindFunction = "Function",
        CmpItemKindInterface = "Type",
        CmpItemKindKeyword = "Keyword",
        CmpItemKindMethod = "Function",
        CmpItemKindModule = "Type",
        CmpItemKindProperty = "Constant",
        CmpItemKindSnippet = "String",
        CmpItemMenu = "Comment",
        ColorColumn = "CursorLine",
        cssBraces = "@identifier",
        cssFontProp = "@identifier",
        cssTagName = "@tag",
        cssTextProp = "@identifier",
        CursorColumn = "CursorLine",
        CursorLineFold = "LineNr",
        CursorLineNr = "LineNr",
        CursorLineSign = "LineNr",
        Delimiter = "Keyword",
        DiagnosticError = "Error",
        diffFile = "String",
        diffIndexLine = "Keyword",
        diffLine = "Comment",
        diffNewFile = "DiffAdd",
        diffOldFile = "DiffDelete",
        diffSubname = "Comment",
        Directory = "Type",
        dosiniHeader = "@identifier",
        dosiniLabel = "Keyword",
        editorconfigProperty = "Keyword",
        EndOfBuffer = "NonText",
        FloatTitle = "NormalFloat",
        FugitiveblameNotCommittedYet = "Type",
        FugitiveblameTime = "Comment",
        fugitiveStagedHeading = "markdownH1",
        fugitiveUnstagedHeading = "markdownH1",
        htmlArg = "@identifier",
        htmlEndTag = "@tag",
        htmlHead = "@none",
        htmlSpecialTagName = "@tag",
        htmlTagN = "@tag",
        htmlTagName = "@tag",
        htmlTitle = "@none",
        javaScript = "@none",
        javaScriptBraces = "@identifier",
        javaScriptFunction = "Keyword",
        jsonBoolean = "Keyword",
        jsonBraces = "Identifier",
        jsonKeyword = "Constant",
        jsonKeywordMatch = "Constant",
        jsonNull = "Keyword",
        jsonQuote = "@none",
        jsonStringMatch = "String",
        LazyH1 = "Visual",
        LazyH2 = "Keyword",
        LazyReasonPlugin = "Type",
        LazySpecial = "Function",
        markdownOrderedListMarker = "Keyword",
        markdownListMarker = "Keyword",
        ngxDirective = "Keyword",
        ngxDirectiveImportant = "Keyword",
        ngxDirectiveThirdParty = "Identifier",
        ngxGzipOn = "Keyword",
        ngxIPaddr = "Type",
        ngxListenOptions = "Identifier",
        NormalFloat = "Pmenu",
        Number = "Type",
        OctoIssueTitle = "Bold",
        Question = "MoreMsg",
        Removed = "DiffDelete",
        SagaTitle = "FloatTitle",
        SignColumn = "LineNr",
        Special = "Keyword",
        Statement = "Keyword",
        StatusLine = "LineNr",
        StatusLineNC = "Normal",
        Tag = "Function",
        TelescopeMatching = "Search",
        typescriptArrowFuncDef = "Function",
        typescriptBraces = "Identifier",
        typescriptCall = "Function",
        typescriptMember = "Constant",
        Variable = "Identifier",
        xmlAttrib = "@identifier",
        xmlProcessingDelim = "@tag",
        zshCommands = "Function",
        zshDeref = "@constant",
        zshFunction = "Function",
        zshOldSubst = "Identifier",
        zshShortDeref = "Constant",
        zshSubstDelim = "Keyword",
        zshSubstQuoted = "String",
    },
}

M.setup = function()
    -- Clearing the colors make the sign column lose the background color
    -- but otherwise, it doesn't work on nvim 0.9.x
    if not vim.g.is_nvim_0_10 then
        vim.cmd("hi clear")
        vim.cmd("syntax reset")
    end

    vim.opt.termguicolors = true
    vim.o.background = "dark"

    for group, highlight in pairs(M.theme.highlights) do
        if vim.g.is_nvim_0_10 then
            highlight.force = true
        end

        vim.api.nvim_set_hl(0, group, highlight)
    end

    for group, link in pairs(M.theme.links) do
        local hiLink = { link = link }
        if vim.g.is_nvim_0_10 then
            hiLink.force = true
        end

        vim.api.nvim_set_hl(0, group, hiLink)
    end
end

M.setup()

-- These don't work, as I need to re-source the file
-- vim.api.nvim_create_user_command("ReloadDarculaTheme", function()
--     M.setup()
-- end, {
--     desc = "Reload the Darcula theme",
-- })

-- vim.api.nvim_create_autocmd("BufWritePost", {
--     group = vim.api.nvim_create_augroup(
--         "carlos_reload_theme",
--         { clear = true }
--     ),
--     pattern = "my-darcula-theme.lua",
--     callback = function()
--         vim.notify("Reloading Darcula theme")
--         M.setup()
--     end,
-- })
