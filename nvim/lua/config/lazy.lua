-- Bootstrap lazy.nvim (plugin manager) and load everything under lua/plugins/.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Every *.lua file in lua/plugins/ is imported as a plugin spec.
  spec = { { import = "plugins" } },
  -- Don't auto-check for updates; run :Lazy sync manually.
  checker = { enabled = false },
  change_detection = { notify = false },
})
