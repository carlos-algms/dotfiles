vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- known issue - :Inspect is not working
vim.hl = vim.highlight

require("00_version_and_env")
require("helpers")

require("settings")
require("shada-manager")
require("remap")
require("commands")
require("autocmds")
require("jump_to_node")
require("eslint")

require("plugins")
