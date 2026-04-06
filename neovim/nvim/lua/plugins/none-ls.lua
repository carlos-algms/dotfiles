local P = {}

local M = {
    "nvimtools/none-ls.nvim",
    dependencies = {},

    event = "VeryLazy",

    config = function()
        local nullLs = require("null-ls")

        local sources = {
            nullLs.builtins.diagnostics.selene.with({
                condition = function(utils)
                    -- Only enable selene if selene.toml exists in project
                    return utils.root_has_file({ "selene.toml" })
                end,
            }),
        }

        -- vim.list_extend(sources, P.make_phpstan_sources())

        nullLs.setup({
            -- debug = true,
            fallback_severity = vim.diagnostic.severity.INFO,
            sources = sources,
        })
    end,
}

function P.make_phpstan_sources()
    local nullLs = require("null-ls")
    local helpers = require("null-ls.helpers")
    local utils = require("null-ls.utils")
    local cmd_resolver = require("null-ls.helpers.command_resolver")

    return {
        nullLs.builtins.diagnostics.phpstan.with({
            dynamic_command = cmd_resolver.generic("vendor/bin"),
            cwd = helpers.cache.by_bufnr(function(params)
                local path = utils.root_pattern(
                    "phpstan.neon",
                    "composer.json",
                    "composer.lock"
                )(params.bufname)

                return path
            end),
            -- I had to add args, as it wasn't finding the phpstan.neon because of the root of the project
            args = function(params)
                local args = {
                    "--error-format",
                    "json",
                    "--no-progress",
                    "$FILENAME",
                }

                local configPath = utils.path.join(params.cwd, "phpstan.neon")

                if vim.fn.filereadable(configPath) then
                    table.insert(args, 1, configPath)
                    table.insert(args, 1, "--configuration")
                end

                table.insert(args, 1, "analyse")

                return args
            end,
            -- I had to duplicate this to flag it as warning
            -- from: https://github.com/nvimtools/none-ls.nvim/blob/dcc8cd4efdcb29275681a3c95786a816330dbca6/lua/null-ls/builtins/diagnostics/phpstan.lua#L26
            on_output = function(params)
                if params.err then
                    vim.notify(
                        "PHPStan diagnostics: "
                            .. vim.inspect(params.err):gsub("\\n", "\r"),
                        vim.log.levels.ERROR
                    )
                    return {}
                end

                local path = params.temp_path or params.bufname
                local parser = helpers.diagnostics.from_json({
                    diagnostic = {
                        severity = vim.diagnostic.severity.WARN,
                    },
                })
                params.messages = params.output
                        and params.output.files
                        and params.output.files[path]
                        and params.output.files[path].messages
                    or {}

                return parser({ output = params.messages })
            end,
        }),
    }
end

return M
