local set = vim.keymap.set

vim.filetype.add({
    extension = {
        zsh = "sh",
        sh = "sh", -- force sh-files with zsh-shebang to still get sh as filetype
        alloy = "hcl", -- Grafana Alloy language, not perfect, better than no highlighting
        mdx = "markdown",
        mdc = "markdown", -- Cursor AI markdown instructions
        avanterules = "markdown",
    },
    filename = {
        [".zshrc"] = "sh",
        [".zprofile"] = "sh",
        [".zshenv"] = "sh",
        ["composer.lock"] = "json",
        ["phpstan.neon"] = "yaml",
        [".env"] = "confini",
    },
    pattern = {
        ["%.vscode/.*%.json"] = "jsonc",
        [".*%.gitconfig"] = "gitconfig",
        ["%.env%..*"] = "confini",
    },
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.avanterules" },
    callback = function()
        vim.cmd("setlocal syntax=markdown")
    end,
})

set("n", "<leader>vm", "<CMD>Mason<CR>", { desc = "Open Mason modal" })

-- note: diagnostics are not exclusive to lsp servers
-- so these can be global keybindings
set(
    "n",
    "gl",
    vim.diagnostic.open_float,
    { desc = "Open problems in a floating window" }
)

vim.schedule(function()
    vim.pack.add({
        "https://github.com/mason-org/mason.nvim",
        "https://github.com/mason-org/mason-lspconfig.nvim",
        "https://github.com/neovim/nvim-lspconfig",
        "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
        "https://github.com/b0o/schemastore.nvim",
        "https://github.com/yioneko/nvim-vtsls",
    })

    require("mason").setup({
        -- In case I want to test a new registry I need to clone my fork of mason-registry
        -- registries = {
        --     "file:~/projects/mason-registry",
        -- },
    })

    --- Using a single ensureInstalled list as mason-tool-installer supports it
    local ensureInstalled = {
        "cspell",
        "lua_ls",
        "stylua",
        "tree-sitter-cli",
        -- "black",
    }

    if vim.g.has_node then
        -- These need npm to be installed, not to run, most have a binary
        vim.list_extend(ensureInstalled, {
            "bashls",
            "docker_compose_language_service",
            "dockerls",
            "jsonls",
            "prettier",
            "shfmt",
            "yamlls",
        })
    end

    if not vim.g.is_ssh then
        if vim.g.has_node then
            vim.list_extend(ensureInstalled, {
                "js-debug-adapter",
                "vtsls",
                -- "phpactor", -- requires PHP in PATH, and doesn't seem as good as intelephense
                "intelephense",
                -- "emmet_language_server", -- it was taking too much precedence over other servers, messing with auto-completion
                "html",
                "cssls",
                "eslint",
                "tailwindcss",
            })
        end
    end

    if vim.fn.executable("go") == 1 then
        vim.list_extend(ensureInstalled, {
            "gopls",
            "goimports",
            -- "goimports-reviser", -- disabled as it requires go.mod to exist
        })
    end

    require("mason-tool-installer").setup({
        ensure_installed = ensureInstalled,
    })

    require("lspconfig.configs").vtsls = require("vtsls").lspconfig

    vim.lsp.log.set_level("error")

    require("mason-lspconfig").setup({
        ensure_installed = nil,
        automatic_enable = {
            exclude = {
                "ts_ls",
                "tsserver",
            },
        },
    })

    vim.diagnostic.config({
        virtual_text = false,
        severity_sort = true,
        float = {
            header = nil,
            border = "rounded",
            focusable = true,
        },
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = "",
                [vim.diagnostic.severity.WARN] = "",
                [vim.diagnostic.severity.HINT] = "",
                [vim.diagnostic.severity.INFO] = "",
            },
        },
    })
end) -- vim.schedule
