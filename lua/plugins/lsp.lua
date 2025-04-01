return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'hrsh7th/cmp-nvim-lsp',
      'j-hui/fidget.nvim',
    },
    config = function()
      -- Setup diagnostic signs with more prominent symbols
      local signs = {
        Error = "󰅚 ", -- Error symbol
        Warn = "󰀪 ",  -- Warning symbol
        Hint = "󰌶 ",  -- Hint symbol
        Info = "󰋽 ",  -- Info symbol
      }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      -- Configure diagnostics display
      vim.diagnostic.config({
        virtual_text = {
          prefix = '●', -- Could be '■', '▎', 'x'
          severity = {
            min = vim.diagnostic.severity.HINT,
          },
          spacing = 4,
          format = function(diagnostic)
            local icon = {
              [vim.diagnostic.severity.ERROR] = "󰅚 ",
              [vim.diagnostic.severity.WARN] = "󰀪 ",
              [vim.diagnostic.severity.INFO] = "󰋽 ",
              [vim.diagnostic.severity.HINT] = "󰌶 ",
            }
            return string.format("%s %s", icon[diagnostic.severity] or "", diagnostic.message)
          end,
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = 'rounded',
          source = 'always',
          header = '',
          prefix = function(diagnostic, i, total)
            local icon = {
              [vim.diagnostic.severity.ERROR] = "󰅚 Error",
              [vim.diagnostic.severity.WARN] = "󰀪 Warning",
              [vim.diagnostic.severity.INFO] = "󰋽 Info",
              [vim.diagnostic.severity.HINT] = "󰌶 Hint",
            }
            return string.format("%s (%d/%d) ", icon[diagnostic.severity] or "", i, total)
          end,
        },
      })

      local on_attach = function(_, bufnr)
        local nmap = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
        end

        nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

        nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
        nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
        nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
        nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

        nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
        nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

        nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
        nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
        nmap('<leader>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, '[W]orkspace [L]ist Folders')

        vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
          vim.lsp.buf.format()
        end, { desc = 'Format current buffer with LSP' })
      end

      require('mason').setup()
      require('mason-lspconfig').setup()
      require('fidget').setup()

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
              diagnostics = { globals = { 'vim' } },
            },
          },
        },
        ts_ls = {

          -- VSCode-like configuration for TypeScript
          init_options = {
            hostInfo = 'neovim',
            preferences = {
              importModuleSpecifier = 'non-relative',
              quotePreference = 'single',
              includeCompletionsForModuleExports = true,
              includeCompletionsWithSnippetText = true,
              includeAutomaticOptionalChainCompletions = true,
              includeCompletionsWithInsertText = true,
              generateReturnInDocTemplate = true,
              includePackageJsonAutoImports = 'on',
              organizeImportsOnSave = true,
            },
            InlayHintsOptions = {
              implementationsCodeLens = { enabled = true },
              referencesCodeLens = { enabled = true },
              inlayHints = {
                includeInlayParameterNameHints = 'literal',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            -- VSCode-like features
            languageFeatures = {
              implementationsCodeLens = { enabled = true },
              referencesCodeLens = { enabled = true },
              inlayHints = {
                includeInlayParameterNameHints = 'literal',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            completions = {
              completeFunctionCalls = true,
              autoImportSuggestions = true,
            },
          },
          capabilities = capabilities,
        },
        html = { filetypes = { 'html', 'twig', 'hbs' } },
      }

      for server, _ in pairs(servers) do
        require('lspconfig')[server].setup(vim.tbl_deep_extend('force', {
          capabilities = capabilities,
          on_attach = on_attach,
        }, servers[server] or {}))
      end

      -- Add auto-import organization for TypeScript files
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = {"*.ts", "*.tsx", "*.js", "*.jsx"},
        callback = function()
          -- Use the built-in LSP function to organize imports
          vim.lsp.buf.code_action({
            context = { only = { "source.organizeImports" } },
            apply = true
          })
        end
      })

      -- Format on save for files with LSP attached
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function()
          -- Check if there are any active language servers for this buffer
          local active_clients = vim.lsp.get_active_clients({ bufnr = 0 })
          if #active_clients > 0 then
            vim.lsp.buf.format({ timeout_ms = 1000 })
          end
        end,
      })
    end,
  },
}

