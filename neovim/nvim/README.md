# NeoVim Shared Config

## Todo

-   [ ] review and lazy load plugins
-   [ ] Change Telescope mapping `<M-q>` to something else, as it is already mapped to `<Esc`>
    -   it is to send only selection to the quickfix list, `<C-q>` sends everything
-   [ ] Create my Own Sheet Sheet of commands and remaps
-   [ ] Check if I need to use a local TSServer or if it is smart enough to pick up the one from the open project
    -   and I can check https://github.com/pmizio/typescript-tools.nvim
-   [x] Learn how to use quickfix
    -   [x] map `[q` and `]q` to navigate through errors
-   [x] Compare the plugin vimspector with the DAP plugin [name](https://github.com/puremourning/vimspector)
    -   VimSpector seems to be more mature, but DAP seems to be the future, I'm skipping this for now
-   [x] Install plugin `trouble` to show errors and warnings
-   [x] Disable float term
-   [x] Install toggle terminal plugin (I have the float-term, but I would prefer to have them in a split)
    -   [x] no, it cant: Or maybe Kitty can open a new terminal in the same CWD?
    -   [x] learn more about the Toggle term functionality
    -   [ ] check the async tasks plugin https://github.com/skywind3000/asynctasks.vim
-   [x] make `null` and `true`, and `false` highlight as normal blue types
-   [ ] Install multi-line plugin
-   [x] How to auto-complete search command? `/ `
    -   It was just a missing config on nvim-cmp
-   [ ] Clean up unused plugins
-   [ ] Setup debugger for Chrome
-   [ ] Setup debugger for node-terminal
-   [x] Syntax highlight for `*.md` files and my Darcula config
-   [ ] Add my surround config from VSCode for markdown bold, inline-code, etc
    -   this might need an attach function to the markdown file-type only
-   [x] Maybe I should start my own Darcula theme repository? it seems to much to keep overriding stuff, and other plugins highlights are not working properly
    -   It was just a matter of not using `Normal`, because it was adding a black background to everything, `NormalFg` is good