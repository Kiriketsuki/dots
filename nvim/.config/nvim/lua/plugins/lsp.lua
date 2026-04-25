return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
        sqlls = {},
        glsl_analyzer = {},
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
        "shellcheck",
        "ruff",
        "prettierd",
        "clang-format",
        "sql-formatter",
      },
    },
  },
}
