return {
  -- Bash LSP + tweak clangd for system code
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers.bashls = {}
      opts.servers.clangd.cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=never", -- don't auto-add #includes
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
      }
    end,
  },

  -- Shell linting/formatting
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "shellcheck", "shfmt" })
    end,
  },

  -- Parsers for low-level files
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "c",
        "cpp",
        "make",
        "cmake",
        "asm",
        "devicetree",
        "kconfig",
        "linkerscript",
        "diff",
        "gitcommit",
        "git_config",
        "ssh_config",
      })
    end,
  },
}
