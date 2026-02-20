-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

local function toggle_lazygit()
  local astro = require "astrocore"
  local lazygit = vim.fn.exepath "lazygit"
  if lazygit == "" then
    astro.notify("lazygit not found in PATH", vim.log.levels.ERROR)
    return
  end

  local current = vim.api.nvim_buf_get_name(0)
  local start_dir = vim.fn.getcwd()
  if current ~= "" then
    local stat = (vim.uv or vim.loop).fs_stat(current)
    if stat and stat.type == "file" then start_dir = vim.fs.dirname(current) or start_dir end
  end

  local git_root = astro.cmd({ "git", "-C", start_dir, "rev-parse", "--show-toplevel" }, false)
  local term_opts = { cmd = lazygit, direction = "float" }
  if git_root then term_opts.dir = vim.trim(git_root) end

  astro.toggle_term_cmd(term_opts)
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 500, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = false, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "auto", -- sets vim.opt.signcolumn to auto
        wrap = true, -- sets vim.opt.wrap
        conceallevel = 2,
        shiftwidth = 2,
        tabstop = 2,
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
        VM_theme = "ocean",
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- second key is the lefthand side of the map

        -- navigate buffer tabs with `H` and `L`
        L = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        H = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- mappings seen under group name "Buffer"
        ["<leader>bD"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Pick to close",
        },

        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        ["<leader>b"] = { desc = "Buffers" },
        -- quick save
        ["<C-s>"] = { ":w!<cr>", desc = "Save File" },

        ["<F4>"] = {
          function() vim.cmd "split | terminal cargo run -q" end,
          desc = "Run Cargo on Current File",
        },
        ["<F3>"] = {
          function() vim.cmd "split | terminal go run ." end,
          desc = "Run Go on Current File",
        },
        ["<leader>P"] = {
          function() vim.cmd "PasteImage" end,
          desc = "Paste image from system clipboard",
        },
        ["<leader>gg"] = { toggle_lazygit, desc = "ToggleTerm lazygit" },
        ["<leader>tl"] = { toggle_lazygit, desc = "ToggleTerm lazygit" },
      },
    },
  },
}
