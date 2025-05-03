local M = {}

---@class RooterConfig
---@field command? string
---@field root_patterns? table<string>
---@field enable_cache? boolean
---@field project_non_root? string

---@type RooterConfig
local default = {
  root_patterns = { '.git/' },
  outermost = true,
  enable_cache = true,
  project_non_root = '',
  command = 'lcd',
}

---@param opt RooterConfig
---@return RooterConfig
function M.setup(opt)
  return vim.tbl_deep_extend('force', default, opt or {})
end

return M
