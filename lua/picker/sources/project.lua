local M = {}
local rooter = require('rooter')

local previewer = require("picker.previewer.file")

function M.get()
    local p = {}
    local projects = rooter.get_project_history()

    for _, k in pairs(projects) do
        table.insert(p, k)
    end
    return vim.tbl_map(function(t)
        return { value = t, str = t.name }
    end, p)
end

function M.default_action(entry)
    rooter.open(entry.value.path)
end

M.preview_win = true

---@field item PickerItem
function M.preview(item, win, buf)
	previewer.preview(item.value.path .. '/README.md', win, buf)
end

return M
