return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "css",
        "scss",
        "html",
        "markdown",
        "markdown_inline",
        "toml",
        "sql",
        "glsl",
        "yaml",
        "regex",
        "vim",
        "vimdoc",
      })
    end,
  },
}
