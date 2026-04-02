-- Lualine configuration
require('lualine').setup({
  options = {
    theme = 'catppuccin-mocha',
    component_separators = { left = " ", right = " " },
    section_separators = { left = "", right = "" },
    globalstatus = true,  -- Single statusline across all windows
  },
  sections = {
    lualine_a = {{ 'mode', color = { bg = '#cba6f7', fg = '#1e1e2e', gui = 'bold' } }},
    lualine_b = {{ 'branch', color = { bg = '#313244', fg = '#cba6f7' } }},
    lualine_c = {{ 'filename', color = { bg = '#1e1e2e', fg = '#cdd6f4' } }},
    lualine_x = {{ 'filetype', color = { bg = '#1e1e2e', fg = '#b4befe' } }},
    lualine_y = {{ 'progress', color = { bg = '#313244', fg = '#cdd6f4' } }},
    lualine_z = {{ 'location', color = { bg = '#cba6f7', fg = '#1e1e2e' } }},
  },
})
-- Add separator line above statusline
vim.opt.laststatus = 3  -- Global statusline
vim.cmd([[
  highlight StatusLine guibg=#313244 guifg=#cdd6f4
  highlight StatusLineNC guibg=#313244 guifg=#6c7086
  set fillchars+=stl:─,stlnc:─
]])
-- Telescope configuration
require('telescope').setup({
  defaults = { layout_config = { horizontal = { preview_width = 0.6 } } },
})

-- Gitsigns configuration
require('gitsigns').setup({
  signs = {
    add = { text = '│' },
    change = { text = '│' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
})

-- Indent-blankline configuration
require('ibl').setup({
  indent = { char = '│' },
  scope = { enabled = false },
})

-- Neoscroll configuration
require('neoscroll').setup({
  mappings = {'<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb'},
  hide_cursor = true,
  stop_eof = true,
  respect_scrolloff = false,
  cursor_scrolls_alone = true,
  easing_function = "quadratic",
  performance_mode = false;
})

-- Toggleterm configuration
require('toggleterm').setup({
  size = 20,
  open_mapping = [[<c-\>]],
  hide_numbers = true,
  shade_terminals = true,
  shading_factor = 2,
  start_in_insert = true,
  insert_mappings = true,
  persist_size = true,
  direction = 'float',
  close_on_exit = true,
  shell = vim.o.shell,
  float_opts = { border = 'curved', winblend = 0 },
})
