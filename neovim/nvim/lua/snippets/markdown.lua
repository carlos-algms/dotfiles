local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local line_begin = require("luasnip.extras.conditions.expand").line_begin

local code_blocks = {
  "ts",
  "tsx",
  "js",
  "jsx",
  "html",
  "css",
  "bash",
  "shell",
  "lua",
  "text",
  "md",
}

local snippets = {}

for _, lang in ipairs(code_blocks) do
  snippets[#snippets + 1] = s(
    { trig = lang, desc = lang .. " code block", condition = line_begin },
    { t({ "```" .. lang, "" }), i(0), t({ "", "```" }) }
  )
end

return snippets
