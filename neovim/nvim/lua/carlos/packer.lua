-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
-- vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
    -- Packer can manage itself
    use("wbthomason/packer.nvim")
    use("nvim-lua/plenary.nvim")

    use({ "nvim-tree/nvim-web-devicons" })
    use({ "MunifTanjim/nui.nvim" })

    use({
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        -- or                            , branch = '0.1.x',
        requires = { { "nvim-lua/plenary.nvim" } },
        -- disabled = vscode,
    })

    use({ "nvim-telescope/telescope-ui-select.nvim" })

    use({
        "doums/darcula",
        as = "darcula",
    })

    use({ "catppuccin/nvim", as = "catppuccin" })

    use({
        "nvim-treesitter/nvim-treesitter",
        { run = ":TSUpdate" },
        -- disabled = vscode,
    })

    use({
        "ThePrimeagen/harpoon",
        -- disabled = vscode,
    })

    use({
        "mbbill/undotree",
        -- disabled = vscode,
    })

    -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v2.x/doc/md/lsp.md#you-might-not-need-lsp-zero
    use({ "williamboman/mason.nvim" })
    use({ "williamboman/mason-lspconfig.nvim" })
    use({ "neovim/nvim-lspconfig" })
    use({ "hrsh7th/nvim-cmp" })
    use({ "hrsh7th/cmp-nvim-lsp" })
    use({
        "L3MON4D3/LuaSnip",
        -- follow latest release.
        tag = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
        -- install jsregexp (optional!:).
        run = "make install_jsregexp",
    })

    use({ "mfussenegger/nvim-dap" })

    use({
        "rcarriga/nvim-dap-ui",
        requires = "mfussenegger/nvim-dap",
    })

    use({
        "theHamsta/nvim-dap-virtual-text",
        requires = "mfussenegger/nvim-dap",
    })

    use({
        "nvim-telescope/telescope-dap.nvim",
        requires = "mfussenegger/nvim-dap",
    })

    use("github/copilot.vim")

    -- use("machakann/vim-sandwich")
    use("tpope/vim-surround")

    -- from: https://www.youtube.com/watch?v=J9yqSdvAKXY&list=TLPQMTkxMjIwMjMeWDFsn3jtJw&index=3
    use("tpope/vim-commentary")
    use("mattn/emmet-vim")
    -- use("nvim-tree/nvim-tree.lua")

    use("lewis6991/gitsigns.nvim")
    use("tpope/vim-fugitive")
    use("rafamadriz/friendly-snippets")
    use({
        "nvim-lualine/lualine.nvim",
        requires = {
            "nvim-tree/nvim-web-devicons",
            opt = true,
        },
    })

    use({
        "mhartington/formatter.nvim",
        -- event = "VeryLazy", -- Packer doeesn't seem to have this event
        -- opts = function()
        --     return require "custom.configs.formatter"
        -- end
    })

    use({
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        requires = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
            -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        },
    })
end)
