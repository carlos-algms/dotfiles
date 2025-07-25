# NeoVim Shared Config

## Todo

- [ ] "K" to hover is not using lsp saga, but native Nvim buf.hover(), how?
      where?

- [ ] Remap focused bindings to use LocalLeader instead of multiple keys
- [ ] Check it worth using img-clip.nvim: copy/paste/drag images
  - https://github.com/HakonHarnes/img-clip.nvim
  - It was added as Dep from Avante, monitor if I use it
- [ ] Monitor Kulala ls and fmt to see if it is worth to use it
  - https://www.reddit.com/r/neovim/comments/1fy979o/kulala_language_server_v1_released/
- [ ] Monitor nvrh - vscode like remote access
  - https://www.reddit.com/r/neovim/comments/1fxkknj/nvrh_aims_to_be_similar_to_vscode_remote_but_for/
- [x] Monitor magazine.nvim - nvim-cmp fork - as cmp seems to be slow on
      development
  - the repo is archived as of 09/Jun/2025
- [ ] Try to auto fold JS/TS imports
  - https://www.reddit.com/r/neovim/comments/seq0q1/comment/hulbcew/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
- [ ] Idea: local history plugin: there is one, but it uses python, it should be
      pure lua
- [ ] Check which_key and add descriptions to keys that have `+prefix`
  - [ ] It's possible to fix WhichKey prefixes without descriptions by setting a
        keybind with empty right-hand side
- [x] git - list only local branches, it's listing all branches including not
      mine ones
  - Auto fixed by Snacks picker, it only shows local branches
- [ ] Bookmarks: code a way of having different named list of files by changing
      the project_path Grapple calls it "scopes" like: bookmarksPath ..
      project_path .. "-permanent-list" .. ".json", or bookmarksPath ..
      project_path .. "-ticket-XX-yyy-" .. ".json"
- [x] fix Eslint Ls crashing after going to a definition inside node_modules
  - I don't know how to fix it better, it just trows 1 error now, and keeps
    working
- [x] Make `]d` and `[d` ignore typos, aka `info`
- [x] Install multi-line plugin https://github.com/mg979/vim-visual-multi I
      installed, it's amazing, but seems slow on multiple cursors
- [x] Clean up unused plugins
- [x] Add emmet plugin (maybe not, I just need wrap and unwrap)
  - I ended up using https://github.com/olrtg/emmet-language-server
  - Its a single package and gives full emmet support via LSP and display via
    CMP
- [ ] Create my Own Cheat Sheet of commands and remaps
- [ ] Add my surround config from VSCode for markdown bold, inline-code, etc
  - this might need an attach function to the markdown file-type only
- [ ] Keep an eye on UFO - to better fold code
- [x] Lua line git branch - show current cwd instead of current file
  - I don't think it worth it, given the amount of code to write
  - this is causing branch to not be visible when editing special files
  - https://github.com/kevinhwang91/nvim-ufo
- [x] maybe test Avante.nvim to replace Copilot?
      https://github.com/yetone/avante.nvim
- [x] Enums shows white and blue depending on where they are, TS and TSX
- [x] Add oil.nvim to test if it is better than neo-tree
  - it is good to use in the current folder, but navigating seems daunting
- [x] review and lazy load plugins
- [x] Enable some plugins only locally not on SSH connections
- [x] Add my most used snippets from VSCode, like `cl` for console.log
- [x] Try to use cspell with a plugin instead of native nvim spell
- [x] `this` in TS is not highlighted as a keyword, how PHP is handling it using
      treesitter?
- [x] Setup debugger for Chrome
- [x] Setup debugger for node-terminal
- [x] hide the dapui_console window
- [x] update the `ff` command to ignore more folders, it's too slow now
- [x] Add custom code to preview images in Telescope
  - https://github.com/3rd/image.nvim/issues/183#issuecomment-2284979815
- [x] Check nesting config for Neo Tree
- [x] setup lua formatter with sane defaults to projects without a RC file
  - apparently the CLI doesn't accept format arguments
- [x] Fork the Dashboard and change file name to omit the CWD and show only
      relative path
  - here:
    https://github.com/nvimdev/dashboard-nvim/blob/63df28409d940f9cac0a925df09d3dc369db9841/lua/dashboard/theme/hyper.lua#L190
  - I created a PR https://github.com/nvimdev/dashboard-nvim/pull/416, 🤞
  - If it gets merged, I'll suggest to start the index with `0`, same as `0
- [x] Correct the sign background color, it is too dark on the numbers column
- [x] Add `jk` to send `<Esc>` in all modes, as saw everywhere on the internet
  - it is terribly slow, I'm disabling it for now
- [x] `@function.call.tsx` should have higher priority over type
- [x] use `try_node_modules` with the Formatter plugin
- [x] How to Format PHP with prettier?
- [x] adjust diffView ctrl+ b / f to scroll less, it jumps too much
- [x] Use quickfix to show TSC errors
  - https://www.reddit.com/r/neovim/comments/ylvoml/typescript_errors_into_vim_quickfix/
  - I need to find a way to look for the nearest tsconfig.json and run tsc on it
- [x] Check if Telescope cache can have ignore, so I can re-enable ui-select
  - It doesn't, I disabled the ui-select plugin for now to avoid issues
- [x] add a width limit to notify and word-wrap
- [x] Add plugin to auto pair brackets
- [x] Review highlights for `.editorconfig`, it is too blue
- [x] `@type.tsx` shows as white in DiffView, should be blue as a normal type
- [x] Change Telescope mapping `<M-q>` to something else, as it is already
      mapped to `<Esc`>
  - it is to send only selection to the quickfix list, `<C-q>` sends everything
- [x] Check if I need to use a local TSServer or if it is smart enough to pick
      up the one from the open project
  - and I can check https://github.com/pmizio/typescript-tools.nvim
- [x] Make Kitty's default title only the current directory
- [x] Learn how to use quickfix
  - [x] map `[q` and `]q` to navigate through errors
- [x] Compare the plugin vimspector with the DAP plugin
      [name](https://github.com/puremourning/vimspector)
  - VimSpector seems to be more mature, but DAP seems to be the future, I'm
    skipping this for now
- [x] Install plugin `trouble` to show errors and warnings
- [x] Disable float term
- [x] Install toggle terminal plugin (I have the float-term, but I would prefer
      to have them in a split)
  - [x] no, it cant: Or maybe Kitty can open a new terminal in the same CWD?
  - [x] lea https://github.com/skywind3000/asynctasks.vimrn more about the
        Toggle term functionality
  - [x] check the async tasks plugin
        https://github.com/skywind3000/asynctasks.vim
    - seems to much to learn its syntax, I'll skip it for now
- [x] make `null` and `true`, and `false` highlight as normal blue types
- [x] How to auto-complete search command? `/ `
  - It was just a missing config on nvim-cmp
- [x] Syntax highlight for `*.md` files and my Darcula config
- [x] Maybe I should start my own Darcula theme repository? it seems to much to
      keep overriding stuff, and other plugins highlights are not working
      properly
  - It was just a matter of not using `Normal`, because it was adding a black
    background to everything, `NormalFg` is good
