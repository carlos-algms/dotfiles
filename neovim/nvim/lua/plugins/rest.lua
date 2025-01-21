return {
    {
        -- I replaced rest.nvim because it has too many dependencies,
        -- and luarocks was failing to install in the remote machines
        "mistweaverco/kulala.nvim",

        ft = "http",

        keys = {
            {
                "<leader>rc",
                function()
                    require("kulala").scratchpad()
                end,
                desc = "Open REST client scratchpad Kulala",
                silent = true,
            },
        },

        init = function()
            vim.filetype.add({
                extension = {
                    ["http"] = "http",
                },
            })
        end,

        config = function()
            -- Setup is required, even if you don't pass any options
            local kulala = require("kulala")
            kulala.setup({
                additional_curl_options = { "--insecure", "-L" },
                default_view = "headers_body",
                -- Display mode, possible values: "split", "float"
                display_mode = "split",
            })

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("kulala", { clear = true }),
                desc = "Set HTTP file keybindings",
                pattern = { "http" },
                callback = function(ev)
                    vim.keymap.set("n", "[r", function()
                        kulala.jump_prev()
                    end, {
                        desc = "Jump to previous request",
                        silent = true,
                        buffer = ev.buf,
                    })

                    vim.keymap.set("n", "]r", function()
                        kulala.jump_next()
                    end, {
                        desc = "Jump to next request",
                        silent = true,
                        buffer = ev.buf,
                    })

                    vim.keymap.set("n", "<leader>rt", function()
                        kulala.toggle_view()
                    end, {
                        desc = "Toggle response view body and headers",
                        silent = true,
                        buffer = ev.buf,
                    })

                    vim.keymap.set("n", "<leader>ry", function()
                        kulala.copy()
                    end, {
                        desc = "Copy current request as curl command",
                        silent = true,
                        buffer = ev.buf,
                    })

                    vim.keymap.set("n", "R", function()
                        kulala.run()
                    end, {
                        desc = "Run request",
                        silent = true,
                        buffer = ev.buf,
                    })

                    -- I've tried with "K", but the LSP bind is taking precedence
                    vim.keymap.set("n", "<leader>ri", function()
                        kulala.inspect()
                    end, {
                        desc = "Inspect current request",
                        silent = true,
                        buffer = ev.buf,
                    })
                end,
            })
        end,
    },
}
