local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local i = ls.insert_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local d = ls.dynamic_node
local c = ls.choice_node
local r = ls.restore_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s(
        { trig = "/**", snippetType = "autosnippet" },
        fmt(
            [[
/**
 * {comment}
 */
        ]],
            {
                comment = isn(0, {
                    i(1),
                }, "$PARENT_INDENT *"),
            }
        )
    ),
}
