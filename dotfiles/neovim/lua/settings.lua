-- Filetype detection
vim.filetype.add({
  filename = {
    ['config'] = 'toml',
    ['conf'] = 'toml',
  },
})

-- General settings
vim.keymap.set('i', '<ScrollWheelUp>', '<Nop>') -- Disable scroll up in insert mode (prevents "2222" spam)
vim.keymap.set('i', '<ScrollWheelDown>', '<Nop>') -- Disable scroll down in insert mode (prevents "2222" spam)
vim.opt.undofile = true -- Persistent undo's across reboots, etc: uses ~/.vim/undodir
vim.opt.autoindent = true -- Copy indent from current line when starting new line
vim.opt.smartindent = false -- Disable automatic indenting for C-like syntax
vim.opt.number = true -- Show absolute line numbers
vim.opt.relativenumber = false -- Disable relative line numbers
vim.opt.cursorline = true -- Highlight the line the cursor is on
vim.opt.ignorecase = true -- Ignore case in search patterns
vim.opt.scroll = 10 -- Number of lines to scroll with CTRL-U/CTRL-D
vim.opt.smartcase = true -- Override ignorecase if search has uppercase
vim.opt.hlsearch = true -- Highlight all search matches
vim.opt.incsearch = true -- Show search matches as you type
vim.opt.tabstop = 2 -- Number of spaces a tab counts for
vim.opt.softtabstop = 2 -- Number of spaces for tab in insert mode
vim.opt.shiftwidth = 2 -- Number of spaces for auto-indent
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.mouse = 'a' -- Enable mouse in all modes
vim.opt.clipboard = 'unnamedplus' -- Use system clipboard for yank/paste
vim.opt.termguicolors = true -- Enable 24-bit RGB colors
vim.opt.ttyfast = true -- Faster redrawing (assumes fast terminal)
vim.opt.compatible = false -- Disable vi compatibility mode
vim.opt.list = true -- Show invisible characters
vim.opt.listchars = { tab = '│ ', trail = '·', nbsp = '␣' } -- Chars to show for tabs, trailing spaces, non-breaking spaces
vim.opt.wildmode = 'longest,list' -- Command-line completion behavior (longest match, then list)
vim.opt.foldmethod = 'marker' -- Use markers (like {{{ }}}) for code folding
vim.opt.guicursor = 'n-v-c:block-Cursor,i-ci-ve:ver25-iCursor,r-cr:hor20-Cursor' -- Cursor shapes (block/v.bar/horiz.)
vim.opt.signcolumn = 'yes' -- Always show sign column (prevents text shifting)

-- Custom highlights for cursor
vim.cmd([[
  highlight Cursor guifg=black guibg=#aaffff
  highlight iCursor guifg=black guibg=#aaffff
  highlight Search guifg=black guibg=#ffb366
]])

-- Enable filetype detection and syntax
vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')
