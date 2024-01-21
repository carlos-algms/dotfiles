vim.g.format_on_save = true

vim.g.format_on_save_exclude =
    table.shallowMerge(vim.g.format_on_save_exclude, {})
