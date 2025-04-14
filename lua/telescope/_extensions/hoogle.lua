-- Sanity checks
local function empty()
  return require'telescope'.register_extension{
    setup = function() end,
    exports = {},
  }
end

if vim.fn.executable'hoogle' == 0 then
  vim.notify("[telescope.hoogle] Warning: Unable to find hoogle executable on the path. Install it", vim.log.levels.WARN)
  return empty()
end

if not require('nvim-treesitter.parsers') then
  vim.notify("[telescope.hoogle] nvim-treesitter is not installed!", vim.log.levels.WARN)
  return empty()
end

if not require('nvim-treesitter.parsers').has_parser('haskell') then
  vim.notify("[telescope.hoogle] Haskell parser not found! Run :TSInstall haskell", vim.log.levels.WARN)
  return empty()
end


-- Entrance
local hoogle_builtin = require'telescope._extensions.hoogle_builtin'
return require'telescope'.register_extension{
  setup = function(ext_config, _)
    hoogle_builtin.ext_config = ext_config
  end,
  exports = {
    list = hoogle_builtin.list,
  },
}
