local M = {}

local ts = require "vim.treesitter"
local query = require "vim.treesitter.query"
local lang = "haskell"

local ALIASED_QUALIFIED_IMPORTS = "aliased-qualified-imports"
local LIST_IMPORTS = "list-imports"
local SINGLE_QUALIFIED_IMPORTS = "single-qualified-imports"
local SINGLE_UNQUALIFIED_IMPORTS = "single-unqualified-imports"

local function isImport(name)
  return name == ALIASED_QUALIFIED_IMPORTS or
         name == LIST_IMPORTS or
         name == SINGLE_QUALIFIED_IMPORTS or
         name == SINGLE_UNQUALIFIED_IMPORTS
end

-- Query import statements.
-- type import ::
--    { name: String, node:: TSNode, mod:: String, alias: String } @ALIASED_QUALIFIED_IMPORTS
--  | { name: String, node: TSNode, mod:: String, list:: TSNode } @LIST_IMPORTS
--  | { name: String, node, mod: String, alias: String } @SINGLE_QUALIFIED_IMPORTS
--  | { name: String, node, mod: String } @SINGLE_UNQUALIFIED_IMPORTS
-- Return a list of import
local function get_haskell_imports()
  local bufnr = 0
  local parser = vim.treesitter.get_parser(0, "haskell")
  local tree = parser:parse()[1]  -- Get the first tree (usually only one)
  local root = tree:root()

  -- You can test it with nvim :InspectTree
  local query_string = [[
    (import
      module: (module) @mod
      alias: (_) @alias) @aliased-qualified-imports

    (import
      module: (module) @mod
      names: (import_list) @list) @list-imports

    ((import
       . module: (module) @mod
         alias: (_) @alias .)
      (#match? "qualified")) @single-qualified-imports

    ((import . module: (module (module_id)) @mod .)
      (#not-match? "qualified")) @single-unqualified-imports
  ]]

  local imports = {}

  local q = query.parse(lang, query_string)
  local toplevel = nil
  for id, node in q:iter_captures(root, bufnr, 0, -1) do
    local name = q.captures[id]

    if isImport(name) then -- New top level capture
      toplevel = name
      table.insert(imports, {
        type = toplevel,
        node = node
      })
    else
      local current = imports[#imports]
      if name == "mod" or name == "alias" then
        current[name] = ts.get_node_text(node, 0)
      else
        current[name] = node
      end
    end
  end
  return imports
end


-- Search entry in import lists. Return all matched imports as a list.
local function search_imports(imports, moduleName)
  local result = {}
  for _, imp in ipairs(imports) do
    if imp.mod == moduleName then
      table.insert(result, imp)
    end
  end
  return result
end


M.get_haskell_imports = get_haskell_imports
M.search_imports = search_imports

return M
