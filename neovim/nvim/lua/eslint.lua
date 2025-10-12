local createUserCommand = vim.api.nvim_create_user_command

local function detect_package_manager()
    local root = vim.fs.root(0, {
        "pnpm-lock.yaml",
        "yarn.lock",
        "package-lock.json",
    })

    if not root then
        return "npm"
    end

    if vim.uv.fs_stat(root .. "/pnpm-lock.yaml") then
        return "pnpm"
    elseif vim.uv.fs_stat(root .. "/yarn.lock") then
        return "yarn"
    else
        return "npm"
    end
end

createUserCommand("Eslint", function()
    local pm = detect_package_manager()

    local command = { pm, "run", "lint" }

    -- To support monorepos, we run eslint from the root of the workspace
    local cwd = vim.fs.root(0, { "package.json", ".git" }) or vim.fn.getcwd()

    vim.notify(
        string.format("## Running eslint:\n`%s`", table.concat(command, " ")),
        vim.log.levels.INFO
    )

    vim.system(command, { text = true, cwd = cwd }, function(result)
        if result.code == 0 then
            vim.notify("🎉 No eslint issues found", vim.log.levels.INFO)
            return
        end

        if result.code > 1 then
            vim.notify(
                string.format(
                    table.concat({
                        "## Eslint command failed:",
                        "Code: `%d`",
                        "```\n%s\n```",
                    }, "\n"),
                    result.code,
                    result.stderr
                ),
                vim.log.levels.ERROR
            )
            return
        end

        vim.schedule(function()
            local qf_list = {}
            local current_file = nil

            for line in result.stdout:gmatch("[^\r\n]+") do
                if line:match("^/") or line:match("^%a:") then
                    local absolute_path = vim.trim(line)
                    current_file = vim.fn.fnamemodify(absolute_path, ":.")
                else
                    local lnum, col, severity, msg =
                        line:match("^%s*(%d+):(%d+)%s+(%w+)%s+(.+)$")
                    if lnum and col and severity and msg and current_file then
                        table.insert(qf_list, {
                            filename = current_file,
                            lnum = tonumber(lnum),
                            col = tonumber(col),
                            type = severity == "error" and "E" or "W",
                            text = vim.trim(msg):gsub("%s+", " "),
                        })
                    end
                end
            end

            vim.fn.setqflist(qf_list, "r")

            if #qf_list == 0 then
                vim.notify("No eslint issues found", vim.log.levels.INFO)
                return
            end

            vim.cmd("copen")
            vim.notify(
                string.format("🐞 Found %d eslint issues", #qf_list),
                vim.log.levels.ERROR
            )
        end)
    end)
end, {})