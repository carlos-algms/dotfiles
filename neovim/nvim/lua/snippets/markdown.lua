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

local snippets = {}

for _, lang in ipairs(code_blocks) do
    snippets[#snippets + 1] = s(
        { trig = lang, desc = lang .. " code block", condition = line_begin },
        { t({ "```" .. lang, "" }), i(0), t({ "", "```" }) }
    )
end

return snippets
