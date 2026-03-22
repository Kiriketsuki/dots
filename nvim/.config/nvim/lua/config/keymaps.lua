-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- VS Code Transition Reference:
-- Ctrl+P (find files)      = <leader><space> or <leader>ff
-- Ctrl+Shift+P (commands)  = <leader>sC
-- F12 (go to definition)   = gd
-- Shift+F12 (references)   = gr
-- Explorer sidebar          = <leader>e
-- Integrated terminal       = <C-/>
-- Source Control (git)      = <leader>gg
-- Ctrl+Shift+F (search)    = <leader>/ or <leader>sg
-- Ctrl+/ (toggle comment)  = gc (visual) or gcc (line)

local map = vim.keymap.set

-- Save with Ctrl+S (familiar from VS Code)
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Close buffer with Ctrl+W (closer to VS Code tab close)
map("n", "<leader>w", "<cmd>bd<cr>", { desc = "Close Buffer" })

-- Select all with Ctrl+A
map("n", "<C-a>", "ggVG", { desc = "Select All" })

-- Palette shortcuts (VS Code Ctrl+P / Ctrl+Shift+P)
map("n", "<leader>p", function() Snacks.picker.files() end, { desc = "Find Files" })
map("n", "<leader>P", function() Snacks.picker.commands() end, { desc = "Command Palette" })

-- Terminal toggle with leader+` (VS Code Ctrl+`)
map("n", "<leader>`", function() Snacks.terminal() end, { desc = "Toggle Terminal" })
map("t", "<leader>`", "<cmd>close<cr>", { desc = "Hide Terminal" })
