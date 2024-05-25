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

                    if status ~= 0 then
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
        local cspell = require("cspell")

        -- local codeActions = nullLs.builtins.code_actions

        local cSpellOpts = {
            find_json = function(_cwd)
                return vim.fn.expand("~/.config/nvim/cspell.json")
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

            ---@param payload AddToDictionarySuccess
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

        nullLs.setup({
            fallback_severity = vim.diagnostic.severity.INFO,
            sources = {
                -- disabled, as I'm not using from the code actions
                -- codeActions.gitsigns,

                cspell.diagnostics.with({ config = cSpellOpts }),
                cspell.code_actions.with({ config = cSpellOpts }),
            },
        })
    end,
}
