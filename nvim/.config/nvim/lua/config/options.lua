-- General editor options. Add or tweak freely.
local opt = vim.opt

-- UI
opt.number = true             -- absolute line numbers
opt.relativenumber = true     -- relative numbers for easy motions
opt.cursorline = true         -- highlight current line
opt.signcolumn = "yes"        -- always show sign column (no text shift)
opt.termguicolors = true      -- 24-bit color
opt.scrolloff = 8             -- keep lines of context around cursor
opt.sidescrolloff = 8
opt.colorcolumn = "80"        -- ruler at 80 cols
opt.showmode = false          -- mode shown by statusline instead
opt.wrap = false
opt.mouse = "a"

-- Indentation (2 spaces; override per-filetype as needed)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.shiftround = true

-- Search
opt.ignorecase = true
opt.smartcase = true          -- case-sensitive if query has capitals
opt.inccommand = "nosplit"    -- live preview of :substitute

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Files / persistence
opt.undofile = true           -- persistent undo
opt.undolevels = 10000
opt.confirm = true            -- prompt instead of failing on unsaved changes
opt.updatetime = 200

-- System clipboard (skip over SSH so OSC52 can work)
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"

-- Timing (quicker which-key style popups)
opt.timeoutlen = 300
