return {
  "ggandor/leap.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = false,
  dependencies = {
    -- Required.
    "tpope/vim-repeat",
  },
  config = function() require("leap").create_default_mappings() end,
}
