vim.pack.add({
    "https://github.com/stevearc/oil.nvim",
})

require("oil").setup({
    default_file_explorer = true,

    columns = {
        "icon",
        -- "permissions",
        -- "size",
        -- "mtime",
    },

    -- https://github.com/stevearc/oil.nvim?tab=readme-ov-file#options
    view_options = {
        show_hidden = true,
        case_insensitive = false,
    },

    keymaps = {
        ["q"] = "actions.close",
        ["<C-v>"] = {
            "actions.select",
            opts = { vertical = true, close = true },
            desc = "Open the entry in a vertical split",
        },
        ["<C-s>"] = {
            "actions.select",
            opts = { horizontal = true, close = true },
            desc = "Open the entry in a horizontal split",
        },
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["R"] = "actions.refresh",
        ["`"] = false,
        ["~"] = false,
        ["gp"] = {
            callback = function()
                local oil = require("oil")
                local actions = require("oil.actions")
                local ok, ImgClipClipboard =
                    pcall(require, "img-clip.clipboard")

                if not ok then
                    vim.notify("img-cip not installed", vim.log.levels.ERROR)
                else
                    local dir = oil.get_current_dir()

                    local file_path = dir
                        .. "pasted_image_"
                        .. vim.fn.strftime("%Y%m%d_%H%M%S")
                        .. ".png"

                    local pasted = pcall(ImgClipClipboard.save_image, file_path)

                    if pasted then
                        require("oil.view").render_buffer_async(
                            0,
                            { refetch = true }
                        )
                        return nil
                    end
                end

                if actions.paste_from_system_clipboard then
                    actions.paste_from_system_clipboard.callback()
                else
                    vim.api.nvim_feedkeys("gp", "n", false)
                end
            end,
            desc = "Paste from system clipboard",
        },
    },

    confirmation = {
        border = "rounded",
    },

    progress = {
        border = "rounded",
    },

    -- Configuration for the floating SSH window
    ssh = {
        border = "rounded",
    },

    -- Configuration for the floating keymaps help window
    keymaps_help = {
        border = "rounded",
    },
})

vim.keymap.set(
    "n",
    "-",
    "<cmd>Oil<CR>",
    { desc = "Reveal current file in Oil" }
)
