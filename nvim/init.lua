-- Neovim entry point.
-- Structure:
--   lua/config/options.lua  -> vim.opt settings
--   lua/config/keymaps.lua  -> keybindings
--   lua/config/lazy.lua     -> bootstraps lazy.nvim + loads lua/plugins/
--
-- Leader must be set before lazy.nvim loads so plugin mappings pick it up.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.lazy")
