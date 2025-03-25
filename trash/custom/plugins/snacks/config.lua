---@type snacks.Config
local opts = {
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
      {
        pane = 2,
        icon = ' ',
        desc = 'Browse Repo',
        padding = 1,
        key = 'b',
        action = function()
          Snacks.gitbrowse()
        end,
      },
      function()
        local in_git = Snacks.git.get_root() ~= nil
        local cmds = {
          {
            title = 'Notifications',
            cmd = 'gh notify -s -a -n5',
            action = function()
              vim.ui.open 'https://github.com/notifications'
            end,
            key = 'n',
            icon = ' ',
            height = 5,
            enabled = true,
          },
          -- more commands...
        }
        return vim.tbl_map(function(cmd)
          return vim.tbl_extend('force', {
            pane = 2,
            section = 'terminal',
            enabled = in_git,
            padding = 3,
            ttl = 5 * 60,
            indent = 3,
          }, cmd)
        end, cmds)
      end,
      { section = 'startup' },
    },
  },
  explorer = {
    enabled = true,
    position = 'right',
    pos = 'right',
    width = 40,
    layout = { position = 'right' },
  },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 3000,
  },
  picker = {
    enabled = true,
    sources = {
      explorer = {
        finder = 'explorer',
        sort = { fields = { 'sort' } },
        supports_live = true,
        tree = true,
        watch = true,
        diagnostics = true,
        diagnostics_open = false,
        git_status = true,
        git_status_open = false,
        git_untracked = true,
        follow_file = true,
        focus = 'list',
        auto_close = false,
        jump = { close = false },
        layout = { layout = { position = 'right' } },
        formatters = {
          file = { filename_only = true },
          severity = { pos = 'right' },
        },
        matcher = { sort_empty = false, fuzzy = false },
        config = function(explorer_opts)
          return require('snacks.picker.source.explorer').setup(explorer_opts)
        end,
        win = {
          list = {
            keys = {
              ['<BS>'] = 'explorer_up',
              ['l'] = 'confirm',
              ['h'] = 'explorer_close',
              ['a'] = 'explorer_add',
              ['d'] = 'explorer_del',
              ['r'] = 'explorer_rename',
              ['c'] = 'explorer_copy',
              ['m'] = 'explorer_move',
              ['o'] = 'explorer_open',
              ['P'] = 'toggle_preview',
              ['y'] = 'explorer_yank',
              ['u'] = 'explorer_update',
              ['<c-c>'] = 'tcd',
              ['<leader>/'] = 'picker_grep',
              ['<c-t>'] = 'terminal',
              ['.'] = 'explorer_focus',
              ['I'] = 'toggle_ignored',
              ['H'] = 'toggle_hidden',
              ['Z'] = 'explorer_close_all',
              [']g'] = 'explorer_git_next',
              ['[g'] = 'explorer_git_prev',
              [']d'] = 'explorer_diagnostic_next',
              ['[d'] = 'explorer_diagnostic_prev',
              [']w'] = 'explorer_warn_next',
              ['[w'] = 'explorer_warn_prev',
              [']e'] = 'explorer_error_next',
              ['[e'] = 'explorer_error_prev',
            },
          },
        },
      },
    },
  },
  quickfile = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  styles = {
    notification = {
      -- e.g., wrap text if needed:
      -- wo = { wrap = true },
    },
  },
}

return { opts = opts }
