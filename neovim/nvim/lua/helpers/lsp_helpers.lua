local M = {}

--- @param client vim.lsp.Client
--- @param bufNr number
function M.enableLspFeatures(client, bufNr)
    if client:supports_method("textDocument/completion") then
        vim.bo[bufNr].omnifunc = "v:lua.vim.lsp.omnifunc"
    end
    if client:supports_method("textDocument/definition") then
        vim.bo[bufNr].tagfunc = "v:lua.vim.lsp.tagfunc"
    end

    -- Disabled, I don't find it useful
    -- if client.server_capabilities.inlayHintProvider then
    --     vim.lsp.inlay_hint.enable(true, {
    --         bufnr = bufNr,
    --     })
    -- end
end

--- @param client vim.lsp.Client
--- @param bufNr number
function M.onLspAttach(client, bufNr)
    M.enableLspFeatures(client, bufNr)

    ---@param when string|string[]
    ---@param keyCombination string
    ---@param action function|string
    ---@param desc string|nil
    local lspKeymap = function(when, keyCombination, action, desc)
        local opts = { buffer = bufNr }
        if desc then
            opts.desc = desc
        end

        vim.keymap.set(when, keyCombination, action, opts)
    end

    if client.server_capabilities.declarationProvider then
        lspKeymap("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
    end

    lspKeymap("n", "go", function()
        local current_word = vim.fn.expand("<cword>")
        vim.cmd(
            string.format(
                "Telescope lsp_type_definitions prompt_title=%s\\ LSP\\ Type\\ definitions",
                current_word
            )
        )
    end, "Go to object type definition")

    lspKeymap("n", "gi", function()
        local current_word = vim.fn.expand("<cword>")
        vim.cmd(
            string.format(
                "Telescope lsp_implementations prompt_title=%s\\ LSP\\ Implementations",
                current_word
            )
        )
    end, "Go to implementation")

    lspKeymap("n", "gd", function()
        local current_word = vim.fn.expand("<cword>")
        vim.cmd(
            string.format(
                "Telescope lsp_definitions prompt_title=%s\\ LSP\\ Definitions",
                current_word
            )
        )
    end, "Go to definition")

    -- Not using LSPSaga as it can't be resumed and reused
    lspKeymap("n", "gr", function()
        local current_word = vim.fn.expand("<cword>")
        vim.cmd(
            string.format(
                "Telescope lsp_references prompt_title=%s\\ LSP\\ References",
                current_word
            )
        )
    end, "List references")

    lspKeymap(
        "n",
        "<leader>rw",
        "<cmd>Telescope lsp_workspace_symbols<CR>",
        "Search for symbol in workspace"
    )

    lspKeymap(
        "n",
        "<leader>rd",
        "<cmd>Telescope lsp_document_symbols<CR>",
        "Search for symbol in document"
    )

    -- Enabled this because the floating input accepts all motions, LSP Saga doesn't
    lspKeymap(
        "n",
        "<leader>rn",
        vim.lsp.buf.rename,
        "Rename symbol with native NVim lsp"
    )

    lspKeymap("i", "<C-h>", function()
        vim.lsp.buf.signature_help({
            border = "rounded",
        })
    end, "Show help for function signature")

    lspKeymap(
        { "n", "v" },
        "<C-.>",
        vim.lsp.buf.code_action,
        "Show code actions"
    )
end

return M
