return {
    {
        "vuki656/package-info.nvim",

        enabled = vim.g.has_node,

        ft = "json",

        dependencies = {
            "MunifTanjim/nui.nvim",
        },

        config = function()
            local packageInfo = require("package-info")

            packageInfo.setup({
                autostart = false,
            })
        end,

        init = function()
            vim.api.nvim_create_autocmd({ "BufNew" }, {
                desc = "Set package.json keybindings",
                pattern = { "package.json" },

                --- @param ev AutoCmdCallbackEvent
                callback = function(ev)
                    local packageInfo = require("package-info")

                    -- vim.notify(
                    --     "Setting package.json keybindings: "
                    --         .. ev.event
                    --         .. " "
                    --         .. ev.file,
                    --     "info"
                    -- )

                    -- Show dependency versions
                    vim.keymap.set({ "n" }, "<leader>ns", packageInfo.show, {
                        silent = true,
                        buffer = ev.buf,
                        desc = "Show package.json info",
                    })

                    -- Hide dependency versions
                    vim.keymap.set({ "n" }, "<leader>nc", packageInfo.hide, {
                        silent = true,
                        buffer = ev.buf,
                        desc = "Hide package.json info",
                    })

                    -- Toggle dependency versions
                    vim.keymap.set({ "n" }, "<leader>nt", packageInfo.toggle, {
                        silent = true,
                        buffer = ev.buf,
                        desc = "Toggle package.json info",
                    })

                    -- Update dependency on the line
                    vim.keymap.set({ "n" }, "<leader>nu", packageInfo.update, {
                        silent = true,
                        buffer = ev.buf,
                        desc = "Update current dependency line in package.json",
                    })

                    -- Delete dependency on the line
                    vim.keymap.set({ "n" }, "<leader>nd", packageInfo.delete, {
                        silent = true,
                        buffer = ev.buf,
                        desc = "Delete current dependency in package.json",
                    })

                    -- Install a new dependency
                    vim.keymap.set({ "n" }, "<leader>ni", packageInfo.install, {
                        silent = true,
                        buffer = ev.buf,
                        desc = "Install a new package.json dependency",
                    })

                    -- Install a different dependency version
                    vim.keymap.set(
                        { "n" },
                        "<leader>np",
                        packageInfo.change_version,
                        {
                            silent = true,
                            buffer = ev.buf,
                            desc = "Change the version of the current dependency line in package.json",
                        }
                    )
                end,
            })
        end,
    },
}
