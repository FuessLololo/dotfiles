return {
  -- No linting for markdown
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft.markdown = {}
    end,
  },
  -- Don't let markdownlint "fix" files on format either
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft.markdown = vim.tbl_filter(function(f)
        return f ~= "markdownlint-cli2"
      end, opts.formatters_by_ft.markdown or {})
    end,
  },
}
