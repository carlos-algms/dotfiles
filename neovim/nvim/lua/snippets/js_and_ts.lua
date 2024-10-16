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

local ts_loop_fmt = [[
.{type}({async}({item}) => {{
    {body}
}})
]]

local ts_loop_snippet = function(type)
    return fmt(ts_loop_fmt, {
        type = t(type),
        async = c(1, { t(""), t("async ") }),
        item = c(
            2,
            { i(1, "item"), sn(nil, { t("{ "), i(1, "field"), t(" }") }) }
        ),
        body = i(0),
    })
end

return {
    s(
        { trig = "//f", snippetType = "autosnippet" },
        fmt([[// FIXIT: {comment}]], {
            comment = isn(0, {
                i(1),
            }, "$PARENT_INDENT *"),
        })
    ),
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

    -- array methods
    s({ trig = ".map", wordTrig = false }, ts_loop_snippet("map")),
    s({ trig = ".filter", wordTrig = false }, ts_loop_snippet("filter")),
    s({ trig = ".forEach", wordTrig = false }, ts_loop_snippet("forEach")),
    s({ trig = ".find", wordTrig = false }, ts_loop_snippet("find")),
    s({ trig = ".some", wordTrig = false }, ts_loop_snippet("some")),
    s({ trig = ".every", wordTrig = false }, ts_loop_snippet("every")),
}
