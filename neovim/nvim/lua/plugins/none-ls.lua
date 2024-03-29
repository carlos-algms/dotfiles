return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        {
            "davidmh/cspell.nvim",
            build = "cd ~/.local/share/nvim/mason/packages/cspell && npm i -g @cspell/dict-pt-br",
        },
    },
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
