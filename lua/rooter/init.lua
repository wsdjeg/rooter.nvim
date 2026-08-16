--=============================================================================
-- rooter.lua --- find root dir of current file
-- Copyright (c) 2025 Wang Shidong & Contributors
-- Author: Wang Shidong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

local project_paths = {}
local project_cache_path = vim.fn.stdpath('data') .. '/nvim-rooter.json'
local project_callback = {}
local logger = require('rooter.logger')
local rooter_config
local enabled = true

local function log(msg)
    logger.info(msg)
end

local unify_path = require('rooter.util').unify_path

local function search_upward(fn, what, where, all)
    local path = where
    if vim.fn.filereadable(where) == 1 and vim.fn.isdirectory(where) == 0 then
        path = vim.fn.fnamemodify(where, ':h')
    end
    local target = vim.fn.escape(path, ' ') .. ';'
    if all then
        -- outermost match: last entry of the upward search
        return vim.fn.get(fn(what, target, -1), -1, '')
    end
    return fn(what, target)
end

local function finddir(what, where, all)
    return search_upward(vim.fn.finddir, what, where, all)
end

local function findfile(what, where, all)
    return search_upward(vim.fn.findfile, what, where, all)
end

local function cache()
    local path = unify_path(project_cache_path, ':p')
    local file = io.open(path, 'w')
    if file then
        file:write(vim.json.encode(project_paths))
        io.close(file)
    end
end

local function filereadable(fpath)
    local f = io.open(fpath, 'r')
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

local function isdirectory(fpath)
    -- NOTE: io.open(dir, 'r') succeeds on unix and would report directories
    -- as non-directories; use the builtin check instead
    return vim.fn.isdirectory(fpath) == 1
end

local function filter_invalid(projects)
    for key, value in pairs(projects) do
        if vim.fn.isdirectory(value.path) == 0 then
            projects[key] = nil
        end
    end
    return projects
end

local function load_cache()
    local file = io.open(project_cache_path, 'r')
    if not file then
        return
    end
    local content = file:read('*a')
    file:close()
    local ok, cache_object = pcall(vim.json.decode, content)
    if ok and type(cache_object) == 'table' then
        project_paths = filter_invalid(cache_object)
    end
end

local function change_dir(dir)
    if not dir or dir == '' or dir == unify_path(vim.fn.getcwd()) then
        return false
    else
        vim.cmd(rooter_config.command .. ' ' .. dir)
        return true
    end
end

local function compare(d1, d2)
    local al = #vim.split(d1, '/')
    local bl = #vim.split(d2, '/')
    if rooter_config.outermost then
        -- sort ascending: the shallowest dir comes first
        return al <= bl
    else
        -- sort descending: the deepest dir comes first
        return al > bl
    end
end

---@return string
local function sort_dirs(dirs)
    table.sort(dirs, compare)
    return dirs[1]
end
---@return string
local function find_root_directory()
    -- empty buffer names are handled by current_root() (alternate-buffer
    -- reuse); reaching here with an empty name should not happen, so just
    -- fall back to the cwd as a safety net
    local fd = vim.fn.bufname('%')
    fd = fd ~= '' and fd or vim.fn.getcwd()
    fd = vim.fn.fnamemodify(fd, ':p')
    log('start to find root for: ' .. fd)
    local dirs = {}
    for _, pattern in pairs(rooter_config.root_patterns) do
        local find_path = ''
        if string.sub(pattern, -1) == '/' then
            find_path = finddir(pattern, fd, rooter_config.outermost)
        else
            find_path = findfile(pattern, fd, rooter_config.outermost)
        end
        local path_type = vim.fn.getftype(find_path)
        if path_type == 'dir' or path_type == 'file' then
            find_path = unify_path(find_path, ':p')
            if path_type == 'dir' then
                find_path = unify_path(find_path, ':h:h')
            else
                find_path = unify_path(find_path, ':h')
            end
            if find_path ~= unify_path(vim.fn.expand('$HOME')) then
                log('        (' .. pattern .. '):' .. find_path)
                table.insert(dirs, find_path)
            end
        end
    end
    return sort_dirs(dirs)
end
local function cache_project(prj)
    project_paths[prj.path] = prj
    if rooter_config.enable_cache then
        cache()
    end
end

local M = {}

---@param opt RooterConfig
function M.setup(opt)
    rooter_config = require('rooter.config').setup(opt)
    local group = vim.api.nvim_create_augroup('nvim-rooter', { clear = true })
    vim.api.nvim_create_autocmd({ 'VimEnter', 'BufEnter' }, {
        group = group,
        pattern = { '*' },
        callback = function(e)
            M.current_root()
        end,
    })
    vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
        group = group,
        pattern = { '*' },
        callback = function(e)
            vim.b.rootDir = ''
            M.current_root()
        end,
    })
    if rooter_config.enable_cache then
        load_cache()
    end
end

function M.toggle()
    if enabled then
        return M.disable()
    else
        return M.enable()
    end
end

function M.enable()
    enabled = true
    return enabled
end

function M.disable()
    enabled = false
    return enabled
end

---@return boolean
function M.is_enabled()
    return enabled
end

function M.list()
    if vim.fn.exists(':Picker') == 2 then
        vim.cmd('Picker project')
    elseif vim.fn.exists(':Telescope') == 2 then
        vim.cmd('Telescope project')
    else
        vim.notify('need picker.nvim or telescope.nvim')
    end
end

function M.open(project)
    local path = project_paths[project]['path']
    vim.cmd('tabnew')
    vim.cmd(rooter_config.command .. ' ' .. path)
end

function M.current_name()
    return vim.b.rooter_project_name or ''
end

function M.clear()
    project_paths = {}
    cache()
end

function M.RootchandgeCallback()
    -- this function only will be called when switch to other project.
    local path = unify_path(vim.fn.getcwd(), ':p')
    local name = vim.fn.fnamemodify(path, ':h:t')
    log('switch to project:[' .. name .. ']')
    log('       rootdir is:' .. path)
    ---@class RooterProject
    ---@field path string absolute root path
    ---@field name string project name
    ---@field opened_time number timestamp when the project was opened
    local project = {
        ['path'] = path,
        ['name'] = name,
        ['opened_time'] = os.time(),
    }
    cache_project(project)
    vim.fn.setbufvar('%', 'rooter_project_name', project.name)
    for _, Callback in pairs(project_callback) do
        if type(Callback.func) == 'string' then
            if Callback.desc then
                log('     run callback:' .. Callback.desc)
            else
                log('     run callback:' .. Callback.func)
            end
            vim.fn.call(Callback.func, { project })
        elseif type(Callback.func) == 'function' then
            if Callback.desc then
                log('     run callback:' .. Callback.desc)
            else
                log('     run callback:' .. tostring(Callback.func))
            end
            pcall(Callback.func, project)
        end
    end
end

function M.reg_callback(func, ...)
    local callback = { func = func }
    local argv = { ... }
    if argv[1] then
        callback.desc = argv[1]
    end
    if type(callback.func) == 'string' or type(callback.func) == 'function' then
        table.insert(project_callback, callback)
    end
end

function M.kill_project(name)
    for i = 1, vim.fn.bufnr('$') do
        if vim.fn.buflisted(i) == 1 and vim.b[i].rooter_project_name == name then
            vim.cmd(string.format('bd %d', i))
        end
    end
end

function M.current_root()
    local bufname = vim.fn.bufname('%')
    if
        not enabled
        or vim.o.autochdir
        or not rooter_config -- if rooter.nvim is not setup
    then
        return vim.fn.getcwd()
    end
    if vim.fn.empty(bufname) == 1 then
        -- unnamed buffer (scratch, enew): reuse the alternate buffer's
        -- project root so scratch buffers stay inside the current project
        local alt_root = vim.fn.getbufvar('#', 'rootDir')
        if alt_root ~= nil and alt_root ~= '' then
            alt_root = unify_path(alt_root)
            if change_dir(alt_root) then
                M.RootchandgeCallback()
            end
            return alt_root
        end
        return unify_path(vim.fn.getcwd())
    end
    for _, pattern in pairs(rooter_config.exclude_patterns or {}) do
        if bufname:match(pattern) then
            return vim.fn.getcwd()
        end
    end
    local rootdir = vim.b.rootDir or ''
    if rootdir == '' or type(rootdir) ~= 'string' then
        rootdir = find_root_directory()
        if rootdir == nil or rootdir == '' then
            -- for no project
            if rooter_config.project_non_root == '' then
                rootdir = unify_path(vim.fn.getcwd())
            elseif rooter_config.project_non_root == 'home' and filereadable(bufname) then
                rootdir = unify_path(vim.fn.expand('~'))
            elseif rooter_config.project_non_root == 'current' then
                local dir = unify_path(bufname, ':p:h')
                if isdirectory(dir) then
                    rootdir = dir
                else
                    rootdir = unify_path(vim.fn.getcwd())
                end
            end
            rootdir = rootdir or ''
            change_dir(rootdir)
        else
            -- for project
            if change_dir(rootdir) then
                M.RootchandgeCallback()
            end
        end
        vim.fn.setbufvar('%', 'rootDir', rootdir)
    elseif change_dir(rootdir) then
        M.RootchandgeCallback()
    end
    return rootdir
end

function M.get_project_history() -- {{{
    return project_paths
end
-- }}}

return M

