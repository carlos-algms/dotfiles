vim.api.nvim_create_user_command("Redir", function(ctx)
    local ouput = vim.api.nvim_exec(ctx.args, true)
    local lines = vim.split(ouput, "\n", { plain = true })
    vim.cmd("vnew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.opt_local.modified = false
end, { nargs = "+", complete = "command" })
