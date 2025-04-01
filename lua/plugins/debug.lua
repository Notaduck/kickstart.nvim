return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'delve',
        'js-debug-adapter',
      },
    }

    -- Configure a more VS Code-like DAP UI
    dapui.setup({
      icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
      controls = {
        icons = {
          pause = "⏸️",
          play = "▶️",
          step_into = "⏎",
          step_over = "⏭️",
          step_out = "⏮️",
          step_back = "⏪",
          run_last = "⟲",
          terminate = "⏹️",
          disconnect = "⏏️",
        },
      },
      layouts = {
        {
          elements = {
            -- Elements can be strings or table with id and size keys.
            { id = "scopes", size = 0.25 },
            "breakpoints",
            "stacks",
            "watches",
          },
          size = 40, -- 40 columns
          position = "left",
        },
        {
          elements = {
            "repl",
            "console",
          },
          size = 0.25, -- 25% of total lines
          position = "bottom",
        },
      },
      floating = {
        max_height = nil, -- These can be integers or a float between 0 and 1.
        max_width = nil, -- Floats will be treated as percentage of your screen.
        border = "single", -- Border style. Can be "single", "double" or "rounded"
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      render = {
        max_type_length = nil, -- Can be integer or nil.
        max_value_lines = 100, -- Can be integer or nil.
      }
    })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
    
    -- VS Code-like breakpoint appearance
    vim.fn.sign_define('DapBreakpoint', { text='🔴', texthl='DapBreakpoint', linehl='', numhl='' })
    vim.fn.sign_define('DapBreakpointCondition', { text='🟡', texthl='DapBreakpointCondition', linehl='', numhl='' })
    vim.fn.sign_define('DapLogPoint', { text='📝', texthl='DapLogPoint', linehl='', numhl='' })
    vim.fn.sign_define('DapStopped', { text='▶️', texthl='DapStopped', linehl='DapStopped', numhl='DapStopped' })
    vim.fn.sign_define('DapBreakpointRejected', { text='⭕', texthl='DapBreakpointRejected', linehl='', numhl='' })
  end,
}
