return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        {
            "davidmh/cspell.nvim",
            -- build = "cd ~/.local/share/nvim/mason/packages/cspell && npm i @cspell/dict-pt-br",
            -- build = "mkdir -p dictionaries && cd $_ && echo '{}' > package.json && npm i @cspell/dict-pt-br",
            init = function()
                local folder_path = "~/.cache/nvim/cspell-dictionaries"

                -- Check if the folder exists
                local folder_exists = os.execute("test -d " .. folder_path)

                -- If the folder doesn't exist, create it
                if folder_exists ~= 0 then
                    vim.notify(
                        "Creating folder for cspell dictionaries",
                        vim.log.levels.INFO
                    )
                    os.execute("mkdir -p " .. folder_path)

                    local status, err = pcall(
                        os.execute,
                        "cd "
                            .. folder_path
                            .. " && echo '{}' > package.json && npm i @cspell/dict-pt-br"
                    )

                    if err ~= 0 then
                        vim.notify(
                            "Failed to install cspell dictionary " .. err,
                            vim.log.levels.ERROR
                        )
                    end
                end
            end,
        },
    },

    event = "VeryLazy",

    config = function()
        local nullLs = require("null-ls")
        local helpers = require("null-ls.helpers")
        local utils = require("null-ls.utils")
        local cmd_resolver = require("null-ls.helpers.command_resolver")

        local sources = {
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

                    local configPath =
                        utils.path.join(params.cwd, "phpstan.neon")

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

        local isCSpellInstalled = vim.fn.executable("cspell")

        if isCSpellInstalled then
            local cspell = require("cspell")

            local cSpellOpts = {
                find_json = function(_cwd)
                    return vim.fn.stdpath("config") .. "/cspell.json"
                end,

                ---@param payload AddToJSONSuccess
                on_add_to_json = function(payload)
                    -- For example, you can format the cspell config file after you add a word
                    os.execute(
                        string.format(
                            "jq -S '.words |= sort' %s > %s.tmp && mv %s.tmp %s",
                            payload.cspell_config_path,
                            payload.cspell_config_path,
                            payload.cspell_config_path,
                            payload.cspell_config_path
                        )
                    )
                end,

                --- @param payload AddToDictionarySuccess
                on_add_to_dictionary = function(payload)
                    -- For example, you can sort the dictionary after adding a word
                    os.execute(
                        string.format(
                            "sort %s -o %s",
                            payload.dictionary_path,
                            payload.dictionary_path
                        )
                    )
                end,
            }

            table.insert(
                sources,
                cspell.diagnostics.with({ config = cSpellOpts })
            )
            table.insert(
                sources,
                cspell.code_actions.with({ config = cSpellOpts })
            )
        end

        nullLs.setup({
            fallback_severity = vim.diagnostic.severity.INFO,
            sources = sources,
        })
    end,
}
