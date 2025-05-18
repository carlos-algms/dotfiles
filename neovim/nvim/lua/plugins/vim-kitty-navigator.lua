return {
    "knubie/vim-kitty-navigator",
    -- Disabled to avoid exploit, check the files before copying them
    build = not vim.g.is_ssh and "cp ./*.py ~/.config/kitty/" or nil,

    dir = vim.g.is_ssh and nil or "~/projects/vim-kitty-navigator",

    enabled = true,

    config = function()
        -- https://sw.kovidgoyal.net/kitty/mapping/#conditional-mappings-depending-on-the-state-of-the-focused-window
        io.stdout:write("\x1b]1337;SetUserVar=IS_NVIM=MQo\007")

        vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
            group = vim.api.nvim_create_augroup(
                "KittySetVarVimEnter",
                { clear = true }
            ),
            callback = function()
                io.stdout:write("\x1b]1337;SetUserVar=IS_NVIM=MQo\007")
            end,
        })

        vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
            group = vim.api.nvim_create_augroup(
                "KittyUnsetVarVimLeave",
                { clear = true }
            ),
            callback = function()
                io.stdout:write("\x1b]1337;SetUserVar=IS_NVIM\007")
            end,
        })

        -- if vim.g.is_ssh then
        --     -- it also requires changes to the py files
        --     -- https://github.com/knubie/vim-kitty-navigator/issues/42#issuecomment-2480832594

        --     vim.system({ "kitten", "@", "set-user-vars", "IS_NVIM=true" }, {
        --         detached = true,
        --     }, function(out)
        --         if out.code ~= 0 then
        --             vim.notify("Error setting user vars: " .. out.stderr)
        --         end
        --     end)

        --     vim.api.nvim_create_autocmd("VimLeavePre", {
        --         group = vim.api.nvim_create_augroup(
        --             "vim-kitty-navigator",
        --             { clear = true }
        --         ),
        --         callback = function()
        --             vim.system(
        --                 { "kitten", "@", "set-user-vars", "IS_NVIM=false" },
        --                 {}
        --             )
        --         end,
        --     })
        -- end
    end,
}
