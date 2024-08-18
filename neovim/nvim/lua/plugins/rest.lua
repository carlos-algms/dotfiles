return {
    {
        -- I replaced rest.nvim because it has too many dependencies,
        -- and luarocks was failing to install in the remote machines
        "mistweaverco/kulala.nvim",

        -- TODO: check if it works on remote machines
        enabled = not vim.g.is_ssh,
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

                    vim.keymap.set("n", "R", function()
                        kulala.run()
                    end, {
                        desc = "Run request",
                        silent = true,
                        buffer = ev.buf,
                    })
                end,
            })
        end,
    },
    {
        "rest-nvim/rest.nvim",
        -- Disabling as it fails to install deps on remote machines
        -- enabled = not vim.g.is_ssh,
        enabled = false,
        ft = "http",
        dependencies = {
            "nvim-neotest/nvim-nio",
            {
                "vhyrro/luarocks.nvim",
                priority = 1000,
                config = true,
                opts = {
                    rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
                },
            },
        },
        config = function()
            ---@diagnostic disable-next-line: missing-fields
            require("rest-nvim").setup({
                keybinds = {
                    {
                        "R",
                        "<cmd>Rest run<cr>",
                        "Run request under the cursor",
                    },
                },
            })

            -- Keep the hightlights here to only load them when the plugin is loaded
            vim.cmd([[ hi! link httpResultMethod Function ]])
            vim.cmd([[ hi! link httpResultPath String ]])
            vim.cmd([[ hi! link @string.special.url.http String ]])
        end,
    },
}
