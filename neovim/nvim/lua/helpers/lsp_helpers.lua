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
