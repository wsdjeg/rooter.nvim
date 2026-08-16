local M = {}

---@class RooterConfig
---@field command? string
---@field root_patterns? table<string>
---@field enable_cache? boolean
---@field project_non_root? string
---@field outermost? boolean
---@field exclude_patterns? table<string> Lua patterns matched against buffer names; matching buffers are skipped by root detection

---@type RooterConfig
local default = {
  root_patterns = { '.git/' },
  outermost = true,
  enable_cache = true,
  project_non_root = '',
  command = 'lcd',
  exclude_patterns = {
    '%[denite%]',
    'denite%-filter',
    '%[defx%]',
    '^git://', -- git.vim
    '^neo%-tree', -- neo-tree.nvim
    '^NvimTree_', -- nvim-tree.nvim
    '^__Tagbar__', -- tagbar.vim
  },
}

---@param opt RooterConfig
---@return RooterConfig
function M.setup(opt)
  local config = vim.tbl_deep_extend('force', default, opt or {})
  -- list options are replaced as a whole (deep extend would merge by index
  -- and keep stale default entries around)
  if opt then
    if opt.root_patterns then
      config.root_patterns = opt.root_patterns
    end
    if opt.exclude_patterns then
      config.exclude_patterns = opt.exclude_patterns
    end
  end
  return config
end

return M

