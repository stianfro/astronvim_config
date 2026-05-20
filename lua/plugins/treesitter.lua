-- Override AstroNvim's nvim-treesitter spec to patch query predicates/directives
-- for Neovim 0.12+, where `iter_matches` returns `TSNode[]` per capture instead
-- of a single TSNode. The legacy `master` branch of nvim-treesitter is archived
-- and unpatched, so we re-register the broken handlers ourselves.

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  init = function(plugin)
    require("lazy.core.loader").add_to_rtp(plugin)
    pcall(require, "nvim-treesitter.query_predicates")

    local query = vim.treesitter.query
    local opts = { force = true }

    local function first_node(n)
      if type(n) == "table" then return n[1] end
      return n
    end

    local html_script_type_languages = {
      ["importmap"] = "json",
      ["module"] = "javascript",
      ["application/ecmascript"] = "javascript",
      ["text/ecmascript"] = "javascript",
    }

    local non_filetype_match_injection_language_aliases = {
      ex = "elixir",
      pl = "perl",
      sh = "bash",
      uxn = "uxntal",
      ts = "typescript",
    }

    local function get_parser_from_markdown_info_string(alias)
      local match = vim.filetype.match { filename = "a." .. alias }
      return match or non_filetype_match_injection_language_aliases[alias] or alias
    end

    query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
      local node = first_node(match[pred[2]])
      if not node then return end
      local type_attr_value = vim.treesitter.get_node_text(node, bufnr)
      local configured = html_script_type_languages[type_attr_value]
      if configured then
        metadata["injection.language"] = configured
      else
        local parts = vim.split(type_attr_value, "/", {})
        metadata["injection.language"] = parts[#parts]
      end
    end, opts)

    query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
      local node = first_node(match[pred[2]])
      if not node then return end
      local alias = vim.treesitter.get_node_text(node, bufnr):lower()
      metadata["injection.language"] = get_parser_from_markdown_info_string(alias)
    end, opts)

    query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
      local id = pred[2]
      local node = first_node(match[id])
      if not node then return end
      local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
      if not metadata[id] then metadata[id] = {} end
      metadata[id].text = string.lower(text)
    end, opts)

    query.add_predicate("nth?", function(match, _pattern, _bufnr, pred)
      local node = first_node(match[pred[2]])
      local n = tonumber(pred[3])
      if node and node:parent() and node:parent():named_child_count() > n then
        return node:parent():named_child(n) == node
      end
      return false
    end, opts)

    query.add_predicate("is?", function(match, _pattern, bufnr, pred)
      local node = first_node(match[pred[2]])
      if not node then return true end
      local ok, locals = pcall(require, "nvim-treesitter.locals")
      if not ok then return false end
      local types = { unpack(pred, 3) }
      local _, _, kind = locals.find_definition(node, bufnr)
      return vim.tbl_contains(types, kind)
    end, opts)

    query.add_predicate("kind-eq?", function(match, _pattern, _bufnr, pred)
      local node = first_node(match[pred[2]])
      if not node then return true end
      local types = { unpack(pred, 3) }
      return vim.tbl_contains(types, node:type())
    end, opts)

    local function has_ancestor(match, _pattern, _bufnr, pred)
      local node = first_node(match[pred[2]])
      if not node then return true end
      local ancestor_types = { unpack(pred, 3) }
      local cur = node:parent()
      while cur do
        if vim.tbl_contains(ancestor_types, cur:type()) then return true end
        cur = cur:parent()
      end
      return false
    end

    query.add_predicate("has-ancestor?", has_ancestor, opts)
    query.add_predicate("has-parent?", has_ancestor, opts)
  end,
}
