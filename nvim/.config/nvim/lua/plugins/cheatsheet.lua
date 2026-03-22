-- Persistent cheat sheet widget in the bottom-right corner
-- Toggle with <leader>? or auto-shows on startup

local cheat_lines = {
  " MOTIONS          EDIT            NAV",
  " h j k l  move    x   del char   Space p   files",
  " w b      word    dd  del line   Space P   cmds",
  " 0 $      line    dw  del word   Space /   grep",
  " gg G     file    cw  change     Space e   tree",
  " Ctrl+U/D page    u   undo       gd        go def",
  " f{c}     find    Ctrl+R redo    gr        refs",
  "                  yy  copy line  Space gg  git",
  " INSERT          p/P paste      Space `   term",
  " i  before       >>  indent     Ctrl+S    save",
  " a  after        <<  outdent    Space w   close",
  " o  line below   gcc comment    Ctrl+A    sel all",
  " Esc normal      J   join       Space ?   toggle",
}

local ns = vim.api.nvim_create_namespace("cheatsheet")
local buf = nil
local win = nil

local function close_cheatsheet()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    win = nil
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
    buf = nil
  end
end

local function open_cheatsheet()
  if win and vim.api.nvim_win_is_valid(win) then
    close_cheatsheet()
    return
  end

  local width = 46
  local height = #cheat_lines

  buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, cheat_lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "cheatsheet"

  local editor_w = vim.o.columns
  local editor_h = vim.o.lines

  win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    anchor = "SE",
    row = editor_h - 3,
    col = editor_w - 1,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 10,
    title = " Cheat Sheet ",
    title_pos = "center",
  })

  vim.wo[win].winblend = 20
  vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"
end

local function toggle_cheatsheet()
  if win and vim.api.nvim_win_is_valid(win) then
    close_cheatsheet()
  else
    open_cheatsheet()
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("cheatsheet_startup", { clear = true }),
  callback = function()
    vim.defer_fn(open_cheatsheet, 500)
  end,
})

vim.keymap.set("n", "<leader>?", toggle_cheatsheet, { desc = "Toggle Cheat Sheet" })

return {}
