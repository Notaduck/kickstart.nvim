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
      {
        type = 'pwa-node',
        request = 'attach',
        name = 'Attach to Node Process',
        processId = require('dap.utils').pick_process,
        cwd = '${workspaceFolder}',
      },
      {
        type = 'pwa-chrome',
        request = 'launch',
        name = 'Launch Chrome',
        url = 'http://localhost:3000',
        webRoot = '${workspaceFolder}',
        userDataDir = '${workspaceFolder}/.chrome-debug-data',
        sourceMaps = true,
      },
    }

    dap.configurations.typescript = {
      {
        type = 'pwa-node',
        request = 'launch',
        name = 'Launch TS File',
        program = '${file}',
        cwd = '${workspaceFolder}',
        runtimeExecutable = 'node',
        runtimeArgs = { '--loader', 'ts-node/esm' },
        outFiles = { '${workspaceFolder}/**/*.js' },
        sourceMaps = true,
        resolveSourceMapLocations = { '${workspaceFolder}/**', '!**/node_modules/**' },
        skipFiles = { '<node_internals>/**' },
      },
      {
        type = 'pwa-node',
        request = 'attach',
        name = 'Attach to Node Process',
        processId = require('dap.utils').pick_process,
        cwd = '${workspaceFolder}',
        sourceMaps = true,
      },
      {
        type = 'pwa-chrome',
        request = 'launch',
        name = 'Launch Chrome against localhost',
        url = 'http://localhost:3000',
        webRoot = '${workspaceFolder}',
        userDataDir = '${workspaceFolder}/.chrome-debug-data',
        sourceMaps = true,
      },
      -- For React applications 
      {
        type = 'pwa-chrome',
        request = 'launch',
        name = 'Launch Chrome for React',
        url = 'http://localhost:3000',
        webRoot = '${workspaceFolder}/src',
        sourceMaps = true,
        sourceMapPathOverrides = { 
          'webpack:///src/*', '${webRoot}/*',
}
        ,
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
    -- Register command and keymap
    vim.api.nvim_create_user_command('DebugNpmScript', debug_npm_script, {})
    
    -- VS Code-style debug keybindings
    vim.keymap.set('n', '<leader>dd', debug_npm_script, { desc = 'Debug npm script' })
    vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Start/Continue (F5)' })
    vim.keymap.set('n', '<F10>', function() require('dap').step_over() end, { desc = 'Debug: Step Over (F10)' })
    vim.keymap.set('n', '<F11>', function() require('dap').step_into() end, { desc = 'Debug: Step Into (F11)' })
    vim.keymap.set('n', '<F12>', function() require('dap').step_out() end, { desc = 'Debug: Step Out (F12)' })
    vim.keymap.set('n', '<leader>b', function() require('dap').toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, { desc = 'Debug: Conditional Breakpoint' })
    vim.keymap.set('n', '<leader>dr', function() require('dap').repl.open() end, { desc = 'Debug: Open REPL' })
    vim.keymap.set('n', '<leader>dl', function() require('dap').run_last() end, { desc = 'Debug: Run Last' })
    vim.keymap.set('n', '<leader>dt', function() require('dapui').toggle() end, { desc = 'Debug: Toggle UI' })

    -- Register Mason to ensure_installed for js-debug-adapter
    require('mason-nvim-dap').setup {
      ensure_installed = { 'js-debug-adapter', 'node-debug2-adapter' },
      automatic_installation = true,
    }
    
    -- Add support for VS Code-style launch.json files
    local function load_launch_json()
      local launch_json_path = vim.fn.getcwd() .. '/.vscode/launch.json'
      if vim.fn.filereadable(launch_json_path) == 1 then
        local file_content = vim.fn.readfile(launch_json_path)
        local json_str = table.concat(file_content, '\n')
        local ok, launch_data = pcall(vim.fn.json_decode, json_str)
        
        if ok and launch_data and launch_data.configurations then
          for _, config in ipairs(launch_data.configurations) do
            if config.type and config.request and config.name then
              local config_type = config.type
              
              -- Convert VSCode debug type names to nvim-dap types
              if config_type == "node" then
                config_type = "pwa-node"
              elseif config_type == "chrome" then
                config_type = "pwa-chrome"
              end
              
              -- Make sure the configurations table exists for this type
              dap.configurations[config.type] = dap.configurations[config.type] or {}
              
              -- Add this configuration
              table.insert(dap.configurations[config.type], config)
            end
          end
          vim.notify("Loaded debug configurations from launch.json", vim.log.levels.INFO)
        else
          vim.notify("Failed to parse launch.json", vim.log.levels.WARN)
        end
      end
    end
    
    -- Load launch.json on startup and when entering a new project
    vim.api.nvim_create_autocmd({"DirChanged"}, {
      pattern = "*",
      callback = load_launch_json
    })
    
    -- Load launch.json on initial load
    load_launch_json()
    
    -- Create command to manually reload launch.json
    vim.api.nvim_create_user_command('LoadLaunchJson', load_launch_json, {
      desc = 'Load debug configurations from .vscode/launch.json'
    })
    
    -- Add a command to create a default launch.json
    vim.api.nvim_create_user_command('CreateLaunchJson', function()
      local dir = vim.fn.getcwd() .. '/.vscode'
      if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, 'p')
      end
      
      local launch_json_path = dir .. '/launch.json'
      if vim.fn.filereadable(launch_json_path) == 1 then
        local choice = vim.fn.confirm("launch.json already exists. Overwrite?", "&Yes\n&No", 2)
        if choice ~= 1 then return end
      end
      
      local template = {
        version = "0.2.0",
        configurations = {
          {
            type = "node",
            request = "launch",
            name = "Launch Program",
            program = "${file}",
            cwd = "${workspaceFolder}",
            skipFiles = {"<node_internals>/**"}
          },
          {
            type = "node",
            request = "attach",
            name = "Attach",
            port = 9229,
            skipFiles = {"<node_internals>/**"}
          },
          {
            type = "chrome",
            request = "launch",
            name = "Launch Chrome against localhost",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}"
          }
        }
      }
      
      local json_str = vim.fn.json_encode(template)
      local formatted_json = vim.fn.system("echo '" .. json_str .. "' | jq .")
      
      if vim.v.shell_error == 0 then
        vim.fn.writefile(vim.fn.split(formatted_json, "\n"), launch_json_path)
      else
        -- Fallback if jq is not available
        vim.fn.writefile({json_str}, launch_json_path)
      end
      
      vim.notify("Created default launch.json", vim.log.levels.INFO)
      load_launch_json()
    end, {
      desc = 'Create a default .vscode/launch.json file'
    })
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
