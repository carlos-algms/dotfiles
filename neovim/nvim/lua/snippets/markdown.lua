local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local line_begin = require("luasnip.extras.conditions.expand").line_begin

local code_blocks = {
    "bash",
    "css",
    "html",
    "js",
    "json",
    "jsx",
    "lua",
    "md",
    "shell",
    "text",
    "ts",
    "tsx",
}

local code_block_aliases = {
    md = "markdown",
}

local snippets = {}

for _, lang in ipairs(code_blocks) do
    local fence_lang = code_block_aliases[lang] or lang

    snippets[#snippets + 1] = s({
        trig = lang,
        desc = fence_lang .. " code block",
        condition = line_begin,
    }, { t({ "```" .. fence_lang, "" }), i(0), t({ "", "```" }) })
end

return snippets
