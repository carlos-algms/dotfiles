-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.5',
        -- or                            , branch = '0.1.x',
        requires = { {'nvim-lua/plenary.nvim'} },
        disabled = vscode
    }

    use({
        'doums/darcula',
        as = 'darcula',
        config = function()
            vim.cmd('colorscheme darcula')
        end
    })


    use({
        'joshdick/onedark.vim',
        as = 'onedark',
        config = function()
            -- vim.cmd('colorscheme onedark')
        end
    })

    use({
        'nvim-treesitter/nvim-treesitter',
        { run = ':TSUpdate' },
        disabled = vscode
    })

    use('nvim-lua/plenary.nvim')
    use({
        'ThePrimeagen/harpoon',
        diabled = vscode
    })

    use({
        'mbbill/undotree',
        disabled = vscode
    })

    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        diabled = vscode,
        requires = {
            --- Uncomment these if you want to manage LSP servers from neovim
            {'williamboman/mason.nvim'},
            {'williamboman/mason-lspconfig.nvim'},

            -- LSP Support
            {'neovim/nvim-lspconfig'},
            -- Autocompletion
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'L3MON4D3/LuaSnip'},
        }
    }

    use('github/copilot.vim')

    use('machakann/vim-sandwich')

end)

