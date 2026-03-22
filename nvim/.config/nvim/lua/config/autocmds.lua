-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-open Neo-tree on startup (VS Code-like always-visible sidebar)
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("open_neo_tree", { clear = true }),
  callback = function()
    if vim.fn.argc() == 0 then
      -- Only auto-open when launching nvim without a file argument
      vim.cmd("Neotree show")
    end
  end,
})
