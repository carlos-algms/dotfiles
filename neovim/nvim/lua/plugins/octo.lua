return {
    "pwntester/octo.nvim",
    -- TODO: Enable it only locally, not for SSH sessions
    enabled = true,
    requires = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("octo").setup({
            enable_builtin = true,
            default_remote = { "origin", "upstream" },
            picker = "telescope",
        })
    end,
}
