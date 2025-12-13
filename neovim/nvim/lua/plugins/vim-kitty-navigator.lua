return {
    "knubie/vim-kitty-navigator",
    -- Disabled to avoid exploit, check the files before copying them
    -- build = not vim.g.is_ssh and "cp ./*.py ~/.config/kitty/" or nil,

    dir = vim.g.is_ssh == false and "~/projects/vim-kitty-navigator" or nil,

    event = "VeryLazy",

    config = function()
        if vim.g.is_ssh then
            -- it also requires changes to the py files
            -- https://github.com/knubie/vim-kitty-navigator/issues/42#issuecomment-2480832594
            -- https://github.com/carlos-algms/vim-kitty-navigator

            vim.system({ "kitten", "@", "set-user-vars", "IS_NVIM=true" }, {}, function(obj)
                if obj.code ~= 0 then
                    vim.schedule(function()
                        vim.notify(
                            "Error set-user-vars: " .. (obj.stderr or ""),
                            vim.log.levels.ERROR
                        )
                    end)
                end
            end)

            vim.api.nvim_create_autocmd("VimLeavePre", {
                group = vim.api.nvim_create_augroup(
                    "vim-kitty-navigator",
                    { clear = true }
                ),
                callback = function()
                    vim.system({ "kitten", "@", "set-user-vars", "IS_NVIM=false" }, {}, function(obj)
                        if obj.code ~= 0 then
                            vim.schedule(function()
                                vim.notify(
                                    "Error set-user-vars: " .. (obj.stderr or ""),
                                    vim.log.levels.ERROR
                                )
                            end)
                        end
                    end)
                end,
            })
        end
    end,
}