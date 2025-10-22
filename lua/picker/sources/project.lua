local M = {}
local rooter = require('rooter')
local util = require('rooter.util')

local previewer = require('picker.previewer.file')

function M.get()
    local p = {}
    local projects = rooter.get_project_history()

    for _, k in pairs(projects) do
        table.insert(p, k)
    end
    return vim.tbl_map(function(t)
        -- return { value = t, str = t.name }
        local item = { value = t }
        local idx = 0
        item.str = '[' .. t.name .. ']'
        item.str = item.str .. string.rep(' ', math.max(25 - vim.fn.strdisplaywidth(item.str), 0))
        item.highlight = { { idx, #item.str, 'String' } }
        idx = #item.str
        item.str = item.str .. util.unify_path(t.path, ':~')
        item.highlight[#item.highlight + 1] = { idx, #item.str, 'Normal' }
        idx = #item.str
        item.str = item.str
            .. string.rep(' ', math.max(vim.o.columns - 100 - vim.fn.strdisplaywidth(item.str), 0))
        item.str = item.str .. '<' .. vim.fn.strftime('%Y-%m-%d %T', t.opened_time) .. '>'
        item.highlight[#item.highlight + 1] = { idx, #item.str, 'Comment' }
        idx = #item.str
        return item
    end, p)
end

M.actions = function()
    local actions = {
        ['<C-f>'] = function(entry)
            vim.cmd.lcd(entry.value.path)
            vim.cmd('Picker files')
        end,
        ['<C-d>'] = function(entry)
            local projects = rooter.get_project_history()
            projects[entry.value.path] = nil
        end,
    }
    local ok, flygrep = pcall(require, 'flygrep')
    if ok then
        actions['<C-s>'] = function(entry)
            flygrep.open({ cwd = entry.value.path })
        end
    end
    return actions
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
