-- Manages per-project ShaDa files for isolated history and cursor positions
-- Self-initializes on require - all setup happens at module load time
--
-- Each project directory gets its own ShaDa file, providing complete isolation of:
-- - Command history (:)
-- - Search history (/, ?)
-- - Jump list (Ctrl-o, Ctrl-i)
-- - Global marks (mA-mZ)
-- - Registers ("a-"z, etc.)
-- - Recent files (:oldfiles)
-- - Cursor positions per file

-- Configure ShaDa options with increased limits
-- ! = Save/restore global variables (uppercase names)
-- '50 = Remember marks + :oldfiles for up to X files (recent files list)
-- <50 = Store up to N lines per register (cross-session persistence only)
-- s10 = Max 10KB per register item
-- /50 = Remember 50 search patterns
-- :100 = Store 100 command-line history items
-- @50 = Store 50 input-line history items
-- h = Disable hlsearch when loading ShaDa
vim.opt.shada = "!,'50,<50,s10,/50,:100,@50,h"

--- Generate project-specific ShaDa file path
--- Uses absolute path with / replaced by -- for unique, readable filenames
local function get_project_shada_path()
    local cwd = vim.fn.getcwd()

    -- Normalize path to handle symlinks - resolves to canonical path
    local normalized_path = vim.loop.fs_realpath(cwd) or cwd

    -- Replace / with -- to create filesystem-safe filename
    -- Remove leading / to avoid starting with --
    local filename = normalized_path:gsub("^/", ""):gsub("/", "--") .. ".shada"

    return vim.fn.stdpath("state") .. "/shada/" .. filename
end

-- Load project ShaDa immediately
local project_shada_path = get_project_shada_path()

-- Ensure parent directory exists
local parent_dir = vim.fn.fnamemodify(project_shada_path, ":h")
vim.fn.mkdir(parent_dir, "p")

-- Set custom ShaDa file path
vim.o.shadafile = project_shada_path

-- Load the project-specific ShaDa file
-- silent! suppresses E195 error when file doesn't exist yet (first run in new project)
-- File will be automatically created on exit by Neovim
-- I disabled to test if is necessary to force load
-- vim.cmd("silent! rshada!")

-- Set up cursor restoration for per-project, per-file cursor positions
vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*",
    callback = function()
        -- Skip special buffers (help, terminal, plugin buffers, etc.)
        if vim.bo.buftype ~= "" then
            return
        end

        local current_pos = vim.api.nvim_win_get_cursor(0)

        -- Only restore if cursor is at line 1 (default position, not explicitly set)
        -- If cursor is elsewhere, user/LSP already positioned it
        if current_pos[1] ~= 1 then
            return
        end

        -- Get last cursor position from '"' mark (stored in ShaDa)
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local line_count = vim.api.nvim_buf_line_count(0)

        if mark[1] > 0 and mark[1] <= line_count then
            -- Use keepjumps to restore cursor without adding to jump list
            -- Prevents initial position from polluting jump history
            vim.cmd(
                string.format("keepjumps call cursor(%d, %d)", mark[1], mark[2])
            )
        end
    end,
    desc = "Restore cursor position from ShaDa (per-project, per-file)",
})

-- Register debug command to show current project's ShaDa path
vim.api.nvim_create_user_command("ProjectShadaPath", function()
    local path = get_project_shada_path()
    vim.notify(path, vim.log.levels.INFO)
end, {
    desc = "Show current project's ShaDa file path",
})
