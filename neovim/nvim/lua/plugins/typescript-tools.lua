return {
    {
        "dmmulroy/tsc.nvim",

        cmd = { "TSC" },

        opts = {
            auto_open_qflist = true,
            auto_close_qflist = true,
            auto_focus_qflist = false,
            use_trouble_qflist = true,
        },
        config = function(_, opts)
            require("tsc").setup(opts)
            require("tsc.utils").find_nearest_tsconfig = function()
                local tsconfig = vim.fn.findfile("tsconfig.json", ".;")

                if tsconfig ~= "" then
                    return { tsconfig }
                end

                tsconfig = vim.fn.findfile("jsconfig.json", ".;")

                if tsconfig ~= "" then
                    return { tsconfig }
                end

                return {}
            end
        end,
    },
}
