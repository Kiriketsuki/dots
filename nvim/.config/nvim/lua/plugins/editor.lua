return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      -- Show git status and buffer sources as tabs in the sidebar
      sources = { "filesystem", "buffers", "git_status" },
      source_selector = {
        winbar = true,
        sources = {
          { source = "filesystem", display_name = " Files" },
          { source = "git_status", display_name = " Git" },
          { source = "buffers", display_name = " Bufs" },
        },
      },
    },
  },
}
