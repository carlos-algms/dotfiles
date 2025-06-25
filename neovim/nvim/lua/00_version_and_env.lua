local semVer = vim.version()

vim.g.is_nvim_0_10 = semVer.major == 0 and semVer.minor == 10
vim.g.is_ssh = vim.fn.getenv("SSH_CLIENT") ~= vim.NIL
vim.g.is_vscode = vim.fn.getenv("VSCODE_PID") ~= vim.NIL
vim.g.has_node = vim.fn.executable("node") == 1
