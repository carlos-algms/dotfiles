local telescope = require("telescope")

-- https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#file-and-text-search-in-hidden-files-and-directories
local telescopeConfig = require("telescope.config")
-- Clone the default Telescope configuration
local vimgrep_arguments = { table.unpack(telescopeConfig.values.vimgrep_arguments) }

-- I want to search in hidden/dot files.
table.insert(vimgrep_arguments, "--hidden")
-- I don't want to search in the `.git` directory.
table.insert(vimgrep_arguments, "--glob")
table.insert(vimgrep_arguments, "!**/.git/*")

telescope.setup({
    defaults = {
        file_ignore_patterns = {
            "node_modules",
            "build",
            "dist",
            "yarn.lock",
        },
        vimgrep_arguments = vimgrep_arguments,
    },
    pickers = {
        find_files = {
            -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
    },
    extensions = {
        ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
        },
    },
})

telescope.load_extension("dap")
telescope.load_extension("ui-select")

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>pl", builtin.live_grep, { desc = "[pl] Live grep files in the current folder" })
vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "[pf] Find all files in the current folder" })
vim.keymap.set("n", "<leader>pg", builtin.git_files, { desc = "[C-p] Find all files in the current git repository" })
vim.keymap.set("n", "<leader>pb", builtin.buffers, { desc = "[pb] Find all open buffers" })
vim.keymap.set("n", "<leader>po", builtin.oldfiles, { desc = "[po] Find all recently opened files" })

-- GIT
vim.keymap.set("n", "<leader>Gs", builtin.git_status, { desc = "[Gs] Show git status" })
vim.keymap.set("n", "<leader>Gb", builtin.git_branches, { desc = "[Gb] Show git branches" })

vim.keymap.set("n", "<leader>ps", function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "[ps] Grep string in the current folder and open results in a Modal" })

vim.keymap.set("n", "<leader>/", function()
    -- You can pass additional configuration to telescope to change theme, layout, etc.
    builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
        winblend = 10,
        previewer = false,
    }))
end, { desc = "[/] Fuzzily search in current buffer on Modal with results" })
