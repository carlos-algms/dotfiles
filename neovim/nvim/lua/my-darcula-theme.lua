---@alias Highlight vim.api.keyset.highlight

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
    error = "#CC666E",
    errorMsg = "#BC3F3C",
    lineNumber = "#606366",
    gutter = "#313335",
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
---@field highlights table<string, Highlight>
---@field links table<string, string>
M.theme = {
    highlights = {
        Bold = { fg = M.pallet.fg, bold = true },
        Boolean = { fg = M.pallet.keyword },
        Comment = { fg = M.pallet.comment },
        Conceal = { fg = M.pallet.muted },
        Constant = { fg = M.pallet.constant },
        Cursor = { fg = M.pallet.cursor },
        DiagnosticUnderlineError = { undercurl = true, sp = "Red" },
        DiagnosticUnderlineHint = { undercurl = true, sp = "LightGrey" },
        DiagnosticUnderlineInfo = { undercurl = true, sp = "LightBlue" },
        DiagnosticUnderlineWarn = { undercurl = true, sp = "Orange" },
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
        PreProc = { fg = M.pallet.preProc },
        String = { fg = M.pallet.string },
        TabLine = { fg = M.pallet.muted, bg = M.pallet.uiBgInactive }, -- the not current tab
        TabLineSel = { fg = M.pallet.fg, bg = M.pallet.uiBgActive }, -- the current tab
        TabLineFill = { bg = M.pallet.bg }, -- the entire tabline behind tabs
        Type = { fg = M.pallet.type },
        Visual = { bg = M.pallet.selection },
        ["@markup.strong"] = { fg = M.pallet.keyword, bold = true },
        Pmenu = { bg = M.pallet.gutter },
    },

    -- TODO the CMP menu is with black background
    links = {
        Added = "DiffAdd",
        Changed = "DiffChange",
        ColorColumn = "CursorLine",
        CursorColumn = "CursorLine",
        CursorLineFold = "LineNr",
        CursorLineNr = "LineNr",
        CursorLineSign = "LineNr",
        Delimiter = "Keyword",
        DiagnosticError = "Error",
        Directory = "Type",
        dosiniHeader = "@identifier",
        dosiniLabel = "Keyword",
        editorconfigProperty = "Keyword",
        EndOfBuffer = "NonText",
        FugitiveblameNotCommittedYet = "Type",
        FugitiveblameTime = "Comment",
        fugitiveStagedHeading = "markdownH1",
        fugitiveUnstagedHeading = "markdownH1",
        LazyH1 = "Visual",
        LazyH2 = "Keyword",
        LazyReasonPlugin = "Type",
        LazySpecial = "Function",
        NormalFloat = "Pmenu",
        Number = "Type",
        Question = "MoreMsg",
        Removed = "DiffDelete",
        SignColumn = "LineNr",
        Special = "Keyword",
        Statement = "Keyword",
        StatusLine = "LineNr",
        Tag = "Function",
        TelescopeMatching = "Search",
        Variable = "Identifier",
        FloatTitle = "NormalFloat",
        SagaTitle = "FloatTitle",
        ["@constructor"] = "@function",
        ["@type.literal"] = "@type",
        ["@type.literal.string"] = "@string",
        ["@comment.documentation"] = "@string",
        ["@attribute.css"] = "@identifier",
        ["@character.special"] = "Keyword",
        ["@constant.builtin"] = "Keyword",
        ["@constant.html"] = "Function",
        ["@constructor.lua"] = "Identifier",
        ["@delimiter.markdown_inline"] = "@keyword",
        ["@function.builtin"] = "@function",
        ["@identifier"] = "Identifier",
        ["@import.identifier"] = "@identifier",
        ["@label.diff"] = "@keyword",
        ["@string.special.vimdoc"] = "@function",
        ["@label.vimdoc"] = "@string",
        ["@variable.parameter.vimdoc"] = "@type",
        ["@label.markdown"] = "@type",
        ["@lsp.type.class"] = "@identifier",
        ["@lsp.type.keyword"] = "@keyword",
        ["@lsp.type.macro.lua"] = "Type",
        ["@lsp.type.property"] = "Constant",
        ["@markup.heading"] = "Keyword",
        ["@markup.heading.html"] = "Identifier",
        ["@markup.list"] = "Keyword",
        ["@markup.raw.block.markdown"] = "Keyword",
        ["@markup.raw.delimiter.markdown"] = "Keyword",
        ["@markup.raw.markdown_inline"] = "Bold",
        ["@property"] = "Constant",
        ["@punctuation"] = "Identifier",
        ["@punctuation.bracket.lua"] = "Identifier",
        ["@punctuation.special.diff"] = "Identifier",
        ["@selector"] = "@function",
        ["@string.regexp.ssh_config"] = "String",
        ["@string.special.path.diff"] = "@identifier",
        ["@string.special.url.gitcommit"] = "@identifier",
        ["@tag"] = "@function",
        ["@tag.builtin"] = "@tag",
        ["@tag.attribute"] = "@identifier",
        ["@type.css"] = "@function",
        ["@unit"] = "@keyword",
        ["@variable"] = "Identifier",
        ["@variable.builtin"] = "Identifier",
        ["@variable.builtin.php"] = "Keyword",
        ["@variable.builtin.this"] = "Keyword",
        ["@variable.member"] = "Constant",
        ["@punctuation.special"] = "@keyword",
        ["@property.yaml"] = "@function",
    },
}

M.setup = function()
    -- I won't reset as it fix the sign column background color
    -- vim.cmd("hi clear")
    -- vim.cmd("syntax reset")

    vim.opt.termguicolors = true
    vim.o.background = "dark"

    for group, highlight in pairs(M.theme.highlights) do
        highlight.force = true
        vim.api.nvim_set_hl(0, group, highlight)
    end

    for group, link in pairs(M.theme.links) do
        vim.api.nvim_set_hl(0, group, { link = link, force = true })
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
