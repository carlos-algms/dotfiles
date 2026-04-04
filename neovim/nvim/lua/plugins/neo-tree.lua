local set = vim.keymap.set
local loaded = false

local function load_neotree()
    if loaded then
        return
    end
    loaded = true

    vim.pack.add({
        "https://github.com/nvim-lua/plenary.nvim",
        "https://github.com/MunifTanjim/nui.nvim",
        { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
    })

    require("neo-tree").setup({
        popup_border_style = "rounded",
        sources = {
            "filesystem",
            "document_symbols",
        },
        enable_git_status = false,
        enable_diagnostics = false,
        sort_case_insensitive = true,
        default_component_configs = {
            group_empty_dirs = true,
            file_size = { enabled = false },
            type = { enabled = false },
            last_modified = { enabled = false, format = "" },
        },

        filesystem = {
            filtered_items = {
                visible = false,
                hide_dotfiles = false,
                hide_gitignored = true,
            },
            group_empty_dirs = false,
            window = {
                mappings = {
                    ["F"] = "fuzzy_finder",
                    ["t"] = "toggle_node",
                    ["a"] = {
                        "add",
                        config = { show_path = "relative" },
                    },
                    ["A"] = {
                        "add_directory",
                        config = { show_path = "relative" },
                    },
                    ["m"] = {
                        "move",
                        config = { show_path = "relative" },
                    },
                },
            },
        },

        window = {
            position = "left",
            width = 40,
            mapping_options = {
                noremap = true,
                nowait = true,
            },
            mappings = {
                ["/"] = false,
            },
        },

        nesting_rules = {
            ["package.json"] = {
                pattern = "^package%.json$",
                files = {
                    "package-lock.json",
                    "yarn*",
                    "pnpm-*.yaml",
                    ".npmrc",
                },
            },
            ["tsx"] = {
                pattern = "(.+)%.tsx$",
                files = { "%1.tsx.map", "%1.*.ts", "%1.*.tsx", "%1.*.css", "%1.*.scss", "%1.*.mdx" },
            },
            ["ts"] = {
                pattern = "(.+)%.ts$",
                files = { "%1.ts.map", "%1.*.ts", "%1.*.tsx", "%1.*.css", "%1.*.scss", "%1.*.mdx" },
            },
            ["js"] = {
                pattern = "(.+)%.js$",
                files = { "%1.js.map" },
            },
            ["docker"] = {
                pattern = "^dockerfile$",
                ignore_case = true,
                files = { ".dockerignore", "docker-compose.*", "dockerfile*" },
            },
            ["tsconfig"] = {
                pattern = "(.+)%.json$",
                files = { "%1.*.json" },
            },
        },
    })

    -- Replace the bootstrap keymap with the actual command
    set({ "n", "v", "x" }, "<C-S-n>", "<cmd>Neotree filesystem reveal left<CR>", {
        desc = "Reveal current file in NeoTree",
        silent = true,
    })
end

-- Bootstrap keymap: loads the plugin on first press, then opens NeoTree
set({ "n", "v", "x" }, "<C-S-n>", function()
    load_neotree()
    vim.cmd("Neotree filesystem reveal left")
end, {
    desc = "Reveal current file in NeoTree",
    silent = true,
})
