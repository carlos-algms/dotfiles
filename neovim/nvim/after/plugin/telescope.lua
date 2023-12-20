local telescope = require("telescope")

telescope.setup({
    defaults = {
        file_ignore_patterns = {
            "node_modules",
        },
    },
})

telescope.load_extension("dap")

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>pl", builtin.live_grep, { desc = "[pl] Live grep files in the current folder" })
vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "[pf] Find all files in the current folder" })
vim.keymap.set("n", "<leader>pg", builtin.git_files, { desc = "[C-p] Find all files in the current git repository" })
vim.keymap.set("n", "<leader>pb", builtin.buffers, { desc = "[pb] Find all open buffers" })
vim.keymap.set("n", "<leader>po", builtin.oldfiles, { desc = "[po] Find all recently opened files" })

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
