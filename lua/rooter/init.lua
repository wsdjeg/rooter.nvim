--=============================================================================
-- rooter.lua --- find root dir of current file
-- Copyright (c) 2025 Wang Shidong & Contributors
-- Author: Wang Shidong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

local project_paths = {}
local project_cache_path = vim.fn.stdpath('data') .. '/nvim-rooter.json'
local project_rooter_ignores = {}
local project_callback = {}
local rooter_config = require('rooter.config').get()

local function log(msg)
  if
    rooter_config.logger
    and rooter_config.logger.info
    and type(rooter_config.logger.info) == 'function'
  then
    rooter_config.logger.info(msg)
  end
end

local function exists(expr)
  return vim.fn.exists(expr) == 1
end

local unify_path = require('rooter.util').unify_path

local function finddir(what, where, ...)
  -- let old_suffixesadd = &suffixesadd
  -- let &suffixesadd = ''
  local count = select(1, ...)
  if count == nil then
    count = 0
  end
  local path = ''
  local file = ''
  if vim.fn.filereadable(where) == 1 and vim.fn.isdirectory(where) == 0 then
    path = vim.fn.fnamemodify(where, ':h')
  else
    path = where
  end
  if count > 0 then
    file = vim.fn.finddir(what, vim.fn.escape(path, ' ') .. ';', count)
  elseif #{ ... } == 0 then
    file = vim.fn.finddir(what, vim.fn.escape(path, ' ') .. ';')
  elseif count == 0 then
    file = vim.fn.finddir(what, vim.fn.escape(path, ' ') .. ';', -1)
  else
    file = vim.fn.get(vim.fn.finddir(what, vim.fn.escape(path, ' ') .. ';', -1), count, '')
  end
  -- let &suffixesadd = old_suffixesadd
  return file
end

local function findfile(what, where, ...)
  -- let old_suffixesadd = &suffixesadd
  -- let &suffixesadd = ''
  local count = select(1, ...)
  if count == nil then
    count = 0
  end

  local file = ''
  local path = ''

  if vim.fn.filereadable(where) == 1 and vim.fn.isdirectory(where) == 0 then
    path = vim.fn.fnamemodify(where, ':h')
  else
    path = where
  end
  if count > 0 then
    file = vim.fn.findfile(what, vim.fn.escape(path, ' ') .. ';', count)
  elseif #{ ... } == 0 then
    file = vim.fn.findfile(what, vim.fn.escape(path, ' ') .. ';')
  elseif count == 0 then
    file = vim.fn.findfile(what, vim.fn.escape(path, ' ') .. ';', -1)
  else
    file = vim.fn.get(vim.fn.findfile(what, vim.fn.escape(path, ' ') .. ';', -1), count, '')
  end
  -- let &suffixesadd = old_suffixesadd
  return file
end

local cd = 'cd'
if exists(':tcd') then
  cd = 'tcd'
elseif exists(':lcd') then
  cd = 'lcd'
end

local function is_ignored_dir(dir)
  for _, v in pairs(project_rooter_ignores) do
    if string.match(dir, v) ~= nil then
      return true
    end
  end
  return false
end
local function cache()
  local path = unify_path(project_cache_path, ':p')
  local file = io.open(path, 'w')
  if file then
    if file:write(vim.json.encode(project_paths)) == nil then
    end
    io.close(file)
  else
  end
end

local function readfile(path)
  local file = io.open(path, 'r')
  if file then
    local content = file:read('*a')
    io.close(file)
    return content
  end
  return nil
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
  local f, err, code = io.open(fpath, 'r')
  if f ~= nil then
    f:close()
    return false
  end
  return code == 13
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
  if filereadable(project_cache_path) then
    local cache_context = readfile(project_cache_path)
    if cache_context ~= nil then
      local cache_object = vim.json.decode(cache_context)
      if type(cache_object) == 'table' then
        project_paths = filter_invalid(cache_object)
      end
    end
  else
  end
end

local function compare_time(d1, d2)
  local proj1 = project_paths[d1] or {}
  local proj1time = proj1['opened_time'] or 0
  local proj2 = project_paths[d2] or {}
  local proj2time = proj2['opened_time'] or 0
  return proj2time < proj1time
end
local function sort_by_opened_time()
  local paths = {}
  for k, _ in pairs(project_paths) do
    table.insert(paths, k)
  end
  table.sort(paths, compare_time)
  return paths
end

local function change_dir(dir)
  if not dir or dir == unify_path(vim.fn.getcwd()) then
    return false
  else
    vim.cmd(cd .. ' ' .. dir)
    return true
  end
end

local function compare(d1, d2)
  local al = #vim.split(d1, '/')
  local bl = #vim.split(d2, '/')
  if not rooter_config.outermost then
    if bl >= al then
      return false
    else
      return true
    end
  else
    if al > bl then
      return false
    else
      return true
    end
  end
end

local function sort_dirs(dirs)
  table.sort(dirs, compare)
  local dir = dirs[1]
  local bufdir = vim.fn.getbufvar('%', 'rootDir', '')
  if bufdir == dir then
    return ''
  else
    return dir
  end
end

local function find_root_directory()
  local fd = vim.fn.bufname('%')
  if fd == '' then
    -- for empty name buffer, check previous buffer dir
    local previous_bufnr = vim.fn.bufnr('#')
    if previous_bufnr == -1 then
    elseif vim.fn.getbufvar('#', 'rootDir', '') == '' then
    else
      return vim.fn.getbufvar('#', 'rootDir', '')
    end
    fd = vim.fn.getcwd()
  end
  fd = vim.fn.fnamemodify(fd, ':p')
  log('start to find root dir for:' .. fd)
  local dirs = {}
  for _, pattern in pairs(rooter_config.root_patterns) do
    local find_path = ''
    if string.sub(pattern, -1) == '/' then
      if rooter_config.outermost then
        find_path = finddir(pattern, fd, -1)
      else
        find_path = finddir(pattern, fd)
      end
    else
      if rooter_config.outermost then
        find_path = findfile(pattern, fd, -1)
      else
        find_path = findfile(pattern, fd)
      end
    end
    local path_type = vim.fn.getftype(find_path)
    if (path_type == 'dir' or path_type == 'file') and not (is_ignored_dir(find_path)) then
      find_path = unify_path(find_path, ':p')
      if path_type == 'dir' then
        find_path = unify_path(find_path, ':h:h')
      else
        find_path = unify_path(find_path, ':h')
      end
      if find_path ~= unify_path(vim.fn.expand('$HOME')) then
        table.insert(dirs, find_path)
      else
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

function M.setup(opt)
  require('rooter.config').setup(opt)
  rooter_config = require('rooter.config').get()
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
  local c = require('rooter.config').get()
  if c.enable_cache then
    load_cache()
  end
end

function M.list()
  vim.cmd('Telescope project')
end

function M.open(project)
  local path = project_paths[project]['path']
  vim.cmd('tabnew')
  vim.cmd(cd .. ' ' .. path)
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
  local project = {
    ['path'] = path,
    ['name'] = name,
    ['opened_time'] = os.time(),
  }
  if project.path == '' then
    return
  end
  cache_project(project)
  vim.fn.setbufvar('%', 'rooter_project_name', project.name)
  for _, Callback in pairs(project_callback) do
    if type(Callback.func) == 'string' then
      if Callback.desc then
      else
      end
      vim.fn.call(Callback.func, {})
    elseif type(Callback.func) == 'function' then
      if Callback.desc then
      else
      end
      pcall(Callback.func)
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
    if type(callback.func) == 'string' and string.match(callback.func, '^function%(') ~= nil then
      callback.func = string.sub(callback.func, 11, -3)
    end
    table.insert(project_callback, callback)
  else
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
    bufname:match('%[denite%]')
    or bufname:match('denite-filter')
    or bufname:match('%[defx%]')
    or bufname:match('^git://') -- this is for git.vim
    or vim.fn.empty(bufname) == 1
    or bufname:match('^neo%-tree') -- this is for neo-tree.nvim
    or vim.o.autochdir
  then
    return vim.fn.getcwd()
  end
  local rootdir = vim.b.rootDir or ''
  if rootdir == '' then
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
