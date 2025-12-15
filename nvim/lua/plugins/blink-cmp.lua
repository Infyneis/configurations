return {
  {
    "moyiz/blink-emoji.nvim",
    lazy = true,
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      "moyiz/blink-emoji.nvim",
    },
    opts = function(_, opts)
      -- Add emoji to the default sources
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      table.insert(opts.sources.default, "emoji")

      -- Configure the emoji provider
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.emoji = {
        module = "blink-emoji",
        name = "Emoji",
        score_offset = 15,
        opts = { insert = true },
      }
    end,
  },
}

