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
  command = 'lcd'
}

---@type RooterConfig
local config = vim.deepcopy(default)

---@param opt RooterConfig
function M.setup(opt)
  config = vim.tbl_deep_extend('force', default, opt or {})
end


---@return RooterConfig
function M.get()
  return config
end

return M
