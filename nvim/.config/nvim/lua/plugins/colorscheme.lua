-- Colorscheme. This is the one real plugin in the starter setup — everything
-- else is up to you. Remove or replace with whatever theme you prefer.
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,    -- load during startup
    priority = 1000, -- load before other plugins so highlights are set first
    config = function()
      require("tokyonight").setup({ style = "night" })
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}
