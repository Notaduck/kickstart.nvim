-- npm_debug.lua
--
-- This module adds functionality to debug npm scripts using DAP
-- similar to VSCode's debug functionality for package.json

return {
  -- We're extending the existing DAP configuration
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add debugger for Node.js
    'mxsdev/nvim-dap-vscode-js',

    -- Add Telescope for selection UI
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
  },
  config = function()
    local dap = require 'dap'

    -- Configure JavaScript/TypeScript debugging
    require('dap-vscode-js').setup {
      -- Path to the debug adapter for vscode-js-debug
      -- The debugger will be installed by Mason automatically
      debugger_path = vim.fn.stdpath 'data' .. '/mason/packages/js-debug-adapter',
      adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
    }

    -- Add Node.js configuration to DAP
    dap.configurations.javascript = {
      {
        type = 'pwa-node',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        cwd = '${workspaceFolder}',
      },
    }

    dap.configurations.typescript = {
      {
        type = 'pwa-node',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        cwd = '${workspaceFolder}',
        runtimeExecutable = 'node',
        runtimeArgs = { '--loader', 'ts-node/esm' },
        outFiles = { '${workspaceFolder}/**/*.js' },
        sourceMaps = true,
        resolveSourceMapLocations = { '${workspaceFolder}/**', '!**/node_modules/**' },
        skipFiles = { '<node_internals>/**' },
      },
    }

    -- Function to find the closest package.json file
    local function find_package_json()
      local current_file = vim.fn.expand '%:p'
      local current_dir = vim.fn.fnamemodify(current_file, ':h')
      local package_json_path = ''

      -- Traverse up directories until a package.json is found
      while current_dir ~= '/' do
        local potential_path = current_dir .. '/package.json'
        if vim.fn.filereadable(potential_path) == 1 then
          package_json_path = potential_path
          break
        end
        current_dir = vim.fn.fnamemodify(current_dir, ':h')
      end

      return package_json_path
    end

    -- Function to parse package.json and extract npm scripts
    local function get_npm_scripts()
      local package_json_path = find_package_json()
      if package_json_path == '' then
        vim.notify('No package.json found', vim.log.levels.ERROR)
        return {}
      end

      local package_json_content = vim.fn.readfile(package_json_path)
      local package_json = vim.fn.json_decode(package_json_content)

      if not package_json or not package_json.scripts then
        vim.notify('No scripts found in package.json', vim.log.levels.ERROR)
        return {}
      end

      local scripts = {}
      for name, command in pairs(package_json.scripts) do
        table.insert(scripts, { name = name, command = command })
      end

      return scripts, package_json_path
    end

    -- Function to create debug configuration for an npm script
    local function create_npm_debug_config(script_name, package_dir)
      return {
        type = 'pwa-node',
        request = 'launch',
        name = 'Debug npm: ' .. script_name,
        runtimeExecutable = 'npm',
        runtimeArgs = { 'run', script_name },
        cwd = package_dir,
        console = 'integratedTerminal',
        internalConsoleOptions = 'neverOpen',
        sourceMaps = true,
        resolveSourceMapLocations = { '${workspaceFolder}/**', '!**/node_modules/**' },
        skipFiles = { '<node_internals>/**' },
      }
    end

    -- Function to select and debug an npm script using Telescope
    local function debug_npm_script()
      local scripts, package_json_path = get_npm_scripts()
      if #scripts == 0 then
        return
      end

      local package_dir = vim.fn.fnamemodify(package_json_path, ':h')

      -- Use Telescope for script selection
      local pickers = require 'telescope.pickers'
      local finders = require 'telescope.finders'
      local conf = require('telescope.config').values
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      pickers
        .new({}, {
          prompt_title = 'NPM Scripts',
          finder = finders.new_table {
            results = scripts,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.name .. ': ' .. entry.command,
                ordinal = entry.name,
              }
            end,
          },
          sorter = conf.generic_sorter {},
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              local script = selection.value

              -- Create debug configuration for the selected script
              local debug_config = create_npm_debug_config(script.name, package_dir)

              -- Start debugging with DAP
              dap.run(debug_config)
            end)
            return true
          end,
        })
        :find()
    end

    -- Register command and keymap
    vim.api.nvim_create_user_command('DebugNpmScript', debug_npm_script, {})
    vim.keymap.set('n', '<leader>dd', debug_npm_script, { desc = 'Debug npm script' })

    -- Register Mason to ensure_installed for js-debug-adapter
    require('mason-nvim-dap').setup {
      ensure_installed = { 'js-debug-adapter', 'node-debug2-adapter' },
      automatic_installation = true,
    }
  end,
}
