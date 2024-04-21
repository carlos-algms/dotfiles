return {
    "github/copilot.vim",
    event = { "VeryLazy" },
    keys = {
        {
            "<C-.>",
            "<Plug>(copilot-accept-word)",
            mode = "i",
            desc = "Copilot accept word",
        },
        {
            "<C-;>",
            "<Plug>(copilot-next)",
            mode = "i",
            desc = "Copilot next suggestion",
        },
        {
            "<C-,>",
            "<Plug>(copilot-suggest)",
            mode = "i",
            desc = "Copilot suggest",
        },
    },
    -- used init instead of config because copilot was holding Tab anyway
    init = function()
        -- I will use CMP mappings to have <Tab> fallback
        vim.g.copilot_no_tab_map = true
        vim.g.copilot_assume_mapped = true
        vim.g.copilot_tab_fallback = ""

        vim.g.copilot_filetypes = {
            yml = true,
            yaml = true,
            markdown = true,
            gitcommit = true,
            sagarename = false,
            spectre_panel = false,
            DressingInput = false,
            oil = false,
        }
    end,
}
