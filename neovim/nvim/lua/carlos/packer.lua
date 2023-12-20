-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
    -- Packer can manage itself
    use("wbthomason/packer.nvim")

    use({
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        -- or                            , branch = '0.1.x',
        requires = { { "nvim-lua/plenary.nvim" } },
        disabled = vscode,
    })

    use({
        "doums/darcula",
        as = "darcula",
        config = function()
            vim.cmd("colorscheme darcula")
        end,
    })

    use({ "catppuccin/nvim", as = "catppuccin" })

    use({
        "joshdick/onedark.vim",
        as = "onedark",
        config = function()
            -- vim.cmd('colorscheme onedark')
        end,
    })

    use({
        "nvim-treesitter/nvim-treesitter",
        { run = ":TSUpdate" },
        disabled = vscode,
    })

    use("nvim-lua/plenary.nvim")

    use({
        "ThePrimeagen/harpoon",
        diabled = vscode,
    })

    use({
        "mbbill/undotree",
        disabled = vscode,
    })

    -- use({
    --     "VonHeikemen/lsp-zero.nvim",
    --     branch = "v3.x",
    --     diabled = vscode,
    --     requires = {
    --         --- Uncomment these if you want to manage LSP servers from neovim
    --         { "williamboman/mason.nvim" },
    --         { "williamboman/mason-lspconfig.nvim" },

    --         -- LSP Support
    --         { "neovim/nvim-lspconfig" },
    --         -- Autocompletion
    --         { "hrsh7th/nvim-cmp" },
    --         { "hrsh7th/cmp-nvim-lsp" },
    --         { "L3MON4D3/LuaSnip" },
    --     },
    -- })

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

    use({
        "mfussenegger/nvim-dap",
    })

    use({
        "rcarriga/nvim-dap-ui",
        dependencies = "mfussenegger/nvim-dap",
    })

    use({
        "theHamsta/nvim-dap-virtual-text",
        dependencies = "mfussenegger/nvim-dap",
    })

    use({
        "nvim-telescope/telescope-dap.nvim",
        dependencies = "mfussenegger/nvim-dap",
    })

    use("github/copilot.vim")

    -- use("machakann/vim-sandwich")
    use("tpope/vim-surround")

    -- from: https://www.youtube.com/watch?v=J9yqSdvAKXY&list=TLPQMTkxMjIwMjMeWDFsn3jtJw&index=3
    use("tpope/vim-commentary")
    use("mattn/emmet-vim")
    use("nvim-tree/nvim-tree.lua")
    use("lewis6991/gitsigns.nvim")
    use("tpope/vim-fugitive")
    use("hrsh7th/nvim-cmp")
    use("hrsh7th/cmp-nvim-lsp")
    use("L3MON4D3/LuaSnip")
    use("saadparwaiz1/cmp_luasnip")
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
end)
