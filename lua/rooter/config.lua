local M = {}

local default = {
  root_patterns = { '.git/' },
  outermost = true,
  enable_cache = true,
}

local config = vim.deepcopy(default)

function M.setup(opt)
  config = vim.tbl_deep_extend('force', default, opt or {})
end

function M.get()
  return config
end

return M
