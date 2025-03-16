return {
    "tomasky/bookmarks.nvim",

    dependencies = {
        "nvim-telescope/telescope.nvim",
    },

    keys = {
        {
            "<leader>mt",
            function()
                require("bookmarks").bookmark_toggle()
            end,
            desc = "Bookmark toggle in current line",
            silent = true,
        },

        {
            "<leader>mi",
            function()
                require("bookmarks").bookmark_ann()
            end,
            desc = "Add or Edit bookmark annotation",
        },

        {
            "<leader>mc",
            function()
                require("bookmarks").bookmark_clean()
            end,
            desc = "Clean ALL bookmarks in current buffer",
        },

        {
            "<leader>mn",
            function()
                require("bookmarks").bookmark_next()
            end,
            desc = "Jump to next bookmark in current buffer",
        },

        {
            "<leader>mp",
            function()
                require("bookmarks").bookmark_prev()
            end,
            desc = "Jump to previous bookmark in current buffer",
        },

        {
            "<leader>ml",
            -- FIXIT: how to list bookmarks without Telescope and open the quickfix window?
            -- https://github.com/tomasky/bookmarks.nvim/blob/0540d52ba64d0ec7677ec1ef14b3624c95a2aaba/lua/bookmarks/actions.lua#L167
            "<cmd>Telescope bookmarks list<CR>",
            desc = "Show bookmarks with Telescope",
        },
    },

    config = function()
        local project_path =
            vim.fn.fnamemodify(vim.fn.getcwd(), ":p"):gsub("/", "__")

        local bookmarksPath = vim.fn.stdpath("cache") .. "/nvim-bookmarks/"

        vim.cmd("silent !mkdir -p " .. bookmarksPath)

        local bookmarksFile = bookmarksPath .. project_path .. ".json"

        require("bookmarks").setup({
            -- Save the bookmarks per project
            save_file = bookmarksFile,
            keywords = {
                ["@t"] = " ", -- mark annotation startswith @t ,signs this icon as `Todo`
                ["@w"] = " ", -- mark annotation startswith @w ,signs this icon as `Warn`
                ["@f"] = "⛏ ", -- mark annotation startswith @f ,signs this icon as `Fix`
                ["@n"] = "󰷉 ", -- mark annotation startswith @n ,signs this icon as `Note`
            },
            -- on_attach = function(bufnr)
            --     local bm = require("bookmarks")
            -- end,
        })

        require("telescope").load_extension("bookmarks")

        -- TODO: link the highlight groups to match SignColumn
        -- https://github.com/tomasky/bookmarks.nvim/blob/main/lua/bookmarks/config.lua
        local groups = {
            "BookMarksAdd",
            "BookMarksAnn",
        }

        for _, group in ipairs(groups) do
            vim.cmd("hi! link " .. group .. " SignColumn")
        end
    end,
}
