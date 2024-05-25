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
    selection = "#273557",
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
        Bold = { fg = M.pallet.fg, bold = true },
        Boolean = { fg = M.pallet.keyword },
        Comment = { fg = M.pallet.comment },
        Conceal = { fg = M.pallet.muted },
        Constant = { fg = M.pallet.constant },
        Cursor = { fg = M.pallet.cursor },
        CursorLine = { bg = M.pallet.gutter },
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
        Pmenu = { bg = M.pallet.gutter },
        PreProc = { fg = M.pallet.preProc },
        String = { fg = M.pallet.string },
        TabLine = { fg = M.pallet.muted, bg = M.pallet.uiBgInactive }, -- the not current tab
        TabLineFill = { bg = M.pallet.bg }, -- the entire tabline behind tabs
        TabLineSel = { fg = M.pallet.fg, bg = M.pallet.uiBgActive }, -- the current tab
        Type = { fg = M.pallet.type },
        Visual = { bg = M.pallet.selection },
        ["@markup.strong"] = { fg = M.pallet.keyword, bold = true },
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
        FloatTitle = "NormalFloat",
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
        SagaTitle = "FloatTitle",
        SignColumn = "LineNr",
        Special = "Keyword",
        Statement = "Keyword",
        StatusLine = "LineNr",
        Tag = "Function",
        TelescopeMatching = "Search",
        Variable = "Identifier",
        ["@attribute.css"] = "@identifier",
        ["@attribute.diff"] = "Comment",
        ["@character.special"] = "Keyword",
        ["@comment.documentation"] = "@string",
        ["@constant.builtin"] = "Keyword",
        ["@constant.html"] = "Function",
        ["@constructor"] = "@function",
        ["@constructor.lua"] = "Identifier",
        ["@delimiter.markdown_inline"] = "@keyword",
        ["@function.builtin"] = "@function",
        ["@identifier"] = "Identifier",
        ["@import.identifier"] = "@identifier",
        ["@label.diff"] = "@keyword",
        ["@label.markdown"] = "@type",
        ["@label.vimdoc"] = "@string",
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
        ["@module.builtin.lua"] = "@identifier",
        ["@property"] = "Constant",
        ["@property.yaml"] = "@function",
        ["@punctuation"] = "Identifier",
        ["@punctuation.bracket.lua"] = "Identifier",
        ["@punctuation.special"] = "@keyword",
        ["@punctuation.special.diff"] = "Identifier",
        ["@selector"] = "@function",
        ["@string.regexp.ssh_config"] = "String",
        ["@string.special.path.diff"] = "@identifier",
        ["@string.special.url.gitcommit"] = "@identifier",
        ["@string.special.vimdoc"] = "@function",
        ["@tag"] = "@function",
        ["@tag.attribute"] = "@identifier",
        ["@tag.builtin"] = "@tag",
        ["@type.css"] = "@function",
        ["@type.literal"] = "@type",
        ["@type.literal.string"] = "@string",
        ["@unit"] = "@keyword",
        ["@variable"] = "Identifier",
        ["@variable.builtin"] = "Identifier",
        ["@variable.builtin.php"] = "Keyword",
        ["@variable.builtin.this"] = "Keyword",
        ["@variable.member"] = "Constant",
        ["@variable.parameter.vimdoc"] = "@type",
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
