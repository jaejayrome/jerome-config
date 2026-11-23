local function paste_template(template_name)
  local template_path = vim.fn.stdpath("config") .. "/templates/" .. template_name
  local file, err = io.open(template_path, "r")
  if file then
    local content = file:read("*all")
    file:close()
    local lines = vim.fn.split(content, "\n")
    vim.api.nvim_put(lines, "l", true, true)
  else
    vim.notify("Failed to load template: " .. template_name .. ". Error: " .. err, vim.log.levels.ERROR)
  end
end

vim.keymap.set("n", "<leader>td", function()
  paste_template("Directions.cpp")
end, { desc = "Paste Directions template" })

vim.keymap.set("n", "<leader>tD", function()
  paste_template("Debug.hpp")
end, { desc = "Paste Debugging template" })

vim.keymap.set("n", "<leader>tu", function()
  paste_template("UnionFind.cpp")
end, { desc = "Paste Union Find template" })

vim.keymap.set("n", "<leader>tq", function()
  paste_template("CircularQueue.cpp")
end, { desc = "Paste Circular Queue template" })

vim.keymap.set("n", "<leader>tf", function()
  paste_template("FenwickTree.cpp")
end, { desc = "Paste Fenwick Tree template" })

vim.keymap.set("n", "<leader>ts", function()
  paste_template("SegmentTree.cpp")
end, { desc = "Paste Segment Tree template" })

vim.keymap.set("n", "<leader>tm", function()
  paste_template("ModNum.hpp")
end, { desc = "Paste Mod Num template" })

vim.keymap.set("n", "<leader>tM", function()
  paste_template("MaxFlow.cpp")
end, { desc = "Paste Max Flow template" })

vim.keymap.set("n", "<leader>tMM", function()
  paste_template("Matrix.cpp")
end, { desc = "Paste Matrix template" })

vim.keymap.set("n", "<leader>tH", function()
  paste_template("Hungarian.cpp")
end, { desc = "Paste Hungarian Weighted Matching template" })

vim.keymap.set("n", "<leader>tr", function()
  paste_template("RadixSort.cpp")
end, { desc = "Paste Radix/Counting Sort template" })

vim.keymap.set("n", "<leader>tSC", function()
  paste_template("SCC.cpp")
end, { desc = "Paste Tarjan SCC template" })

vim.keymap.set("n", "<leader>tSA", function()
  paste_template("SuffixArray.cpp")
end, { desc = "Paste Suffix Array template" })

vim.keymap.set("n", "<leader>tB", function()
  paste_template("MCBM.cpp")
end, { desc = "Paste MCBM template" })

vim.keymap.set("n", "<leader>tI", function()
  paste_template("IndependentSet.cpp")
end, { desc = "Paste IndependentSet template" })

vim.keymap.set("n", "<leader>tC", function()
  paste_template("MaxClique.cpp")
end, { desc = "Paste MaxClique template" })

-- Seamless navigation between Neovim windows (splits) and Zellij panes.
-- Ctrl+h/j/k/l first tries to move within Neovim. If the cursor is already at
-- the edge of Neovim's layout, focus is handed off to the adjacent Zellij pane
-- (and, left/right, to the adjacent tab). Requires running inside Zellij.
local function nav(wincmd, zellij_action, zellij_dir)
  return function()
    local prev = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(wincmd)
    -- Window unchanged => we were at the edge, so let Zellij take over.
    if vim.api.nvim_get_current_win() == prev and vim.env.ZELLIJ then
      vim.system({ "zellij", "action", zellij_action, zellij_dir })
    end
  end
end

vim.keymap.set("n", "<C-h>", nav("h", "move-focus-or-tab", "left"), { desc = "Navigate left (nvim/zellij)" })
vim.keymap.set("n", "<C-j>", nav("j", "move-focus", "down"), { desc = "Navigate down (nvim/zellij)" })
vim.keymap.set("n", "<C-k>", nav("k", "move-focus", "up"), { desc = "Navigate up (nvim/zellij)" })
vim.keymap.set("n", "<C-l>", nav("l", "move-focus-or-tab", "right"), { desc = "Navigate right (nvim/zellij)" })

-- Same Ctrl+h/j/k/l navigation from terminal mode (e.g. the <C-/> Snacks
-- terminal): drop out of insert/terminal mode, then move to the target window.
for _, key in ipairs({ "h", "j", "k", "l" }) do
  vim.keymap.set("t", "<C-" .. key .. ">", "<C-\\><C-n><C-w>" .. key, { desc = "Navigate " .. key .. " (from terminal)" })
end

-- LazyVim's <leader>bb jumps to the alternate buffer with no UI; open the
-- buffer picker popup instead (<leader>` still jumps to the alternate buffer).
vim.keymap.set("n", "<leader>bb", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
