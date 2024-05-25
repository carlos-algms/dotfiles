local semVer = vim.version()

vim.g.is_nvim_0_10 = semVer.major == 0 and semVer.minor == 10
vim.g.is_ssh = os.getenv("SSH_CLIENT") ~= nil
vim.g.is_vscode = os.getenv("VSCODE_PID") ~= nil
vim.g.has_node = vim.fn.executable("node") == 1
