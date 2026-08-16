-- test/rooter_spec.lua
-- current_root() scenarios, :Rooter command dispatch, cache round trips
local lu = require('luaunit')
local rooter = require('rooter')
local util = require('rooter.util')

local cache_file = vim.fn.stdpath('data') .. '/nvim-rooter.json'
local base

local function default_setup(overrides)
  local opt = vim.tbl_extend('force', {
    root_patterns = { '.git/' },
    outermost = true,
    enable_cache = false,
    project_non_root = '',
    command = 'lcd',
  }, overrides or {})
  rooter.setup(opt)
end

local function make_tree()
  base = vim.fn.tempname() .. '_rooter_tree'
  vim.fn.mkdir(base .. '/proj/.git', 'p')
  vim.fn.mkdir(base .. '/proj/inner/.git', 'p')
  vim.fn.mkdir(base .. '/mk/src', 'p')
  vim.fn.writefile({ 'all:' }, base .. '/mk/Makefile')
  vim.fn.writefile({ 'all:' }, base .. '/proj/Makefile')
  vim.fn.writefile({ 'x' }, base .. '/proj/file.txt')
  vim.fn.writefile({ 'x' }, base .. '/proj/inner/deep.txt')
  vim.fn.writefile({ 'x' }, base .. '/mk/src/a.txt')
  vim.fn.writefile({ 'x' }, base .. '/standalone.txt')
end

local function del_tree()
  if base then
    vim.fn.delete(base, 'rf')
  end
end

local function reset_env()
  while vim.fn.tabpagenr('$') > 1 do
    vim.cmd('silent! tabclose 1')
  end
  for i = 1, vim.fn.bufnr('$') do
    if vim.fn.buflisted(i) == 1 then
      vim.cmd('silent! bwipeout ' .. i)
    end
  end
  vim.cmd('enew')
  vim.o.autochdir = false
  rooter.enable()
  vim.cmd('lcd ' .. vim.fn.getcwd())
end

-- helper: run fn with a scratch buffer named `name` as the current buffer
local function with_buf_name(name)
  vim.cmd('enew')
  vim.api.nvim_buf_set_name(0, name)
  local result = rooter.current_root()
  vim.cmd('silent! bwipeout')
  return result
end

TestRooterRoot = {}

function TestRooterRoot:setUp()
  reset_env()
  make_tree()
  vim.cmd('lcd ' .. base)
  default_setup()
end

function TestRooterRoot:tearDown()
  del_tree()
end

-- root detection ------------------------------------------------------------

function TestRooterRoot:test_git_dir_root_outermost()
  vim.cmd('edit ' .. base .. '/proj/inner/deep.txt')
  local root = rooter.current_root()
  lu.assertEquals(vim.fn.getcwd(), base .. '/proj')
  lu.assertEquals(root, base .. '/proj/')
  lu.assertEquals(vim.b.rootDir, base .. '/proj/')
  lu.assertEquals(rooter.current_name(), 'proj')
  lu.assertNotNil(rooter.get_project_history()[base .. '/proj/'])
end

function TestRooterRoot:test_git_dir_root_innermost()
  default_setup({ outermost = false })
  vim.cmd('edit ' .. base .. '/proj/inner/deep.txt')
  rooter.current_root()
  lu.assertEquals(vim.fn.getcwd(), base .. '/proj/inner')
end

function TestRooterRoot:test_multiple_patterns_pick_outermost()
  default_setup({ root_patterns = { '.git/', 'Makefile' } })
  vim.cmd('edit ' .. base .. '/proj/inner/deep.txt')
  rooter.current_root()
  -- .git found at proj (outermost) and Makefile at proj -> root is proj
  lu.assertEquals(vim.fn.getcwd(), base .. '/proj')
end

function TestRooterRoot:test_multiple_patterns_innermost_prefers_deep()
  default_setup({ root_patterns = { '.git/', 'Makefile' }, outermost = false })
  vim.cmd('edit ' .. base .. '/proj/inner/deep.txt')
  rooter.current_root()
  -- .git nearest match is proj/inner (deeper than the Makefile root)
  lu.assertEquals(vim.fn.getcwd(), base .. '/proj/inner')
end

function TestRooterRoot:test_file_pattern_root()
  default_setup({ root_patterns = { 'Makefile' } })
  vim.cmd('edit ' .. base .. '/mk/src/a.txt')
  rooter.current_root()
  lu.assertEquals(vim.fn.getcwd(), base .. '/mk')
end

function TestRooterRoot:test_file_pattern_root_innermost_matches_nearest()
  default_setup({ root_patterns = { 'Makefile' }, outermost = false })
  vim.cmd('edit ' .. base .. '/proj/inner/deep.txt')
  rooter.current_root()
  lu.assertEquals(vim.fn.getcwd(), base .. '/proj')
end

-- no project ----------------------------------------------------------------

function TestRooterRoot:test_no_project_falls_back_to_cwd()
  vim.cmd('edit ' .. base .. '/standalone.txt')
  local root = rooter.current_root()
  lu.assertEquals(vim.fn.getcwd(), base)
  lu.assertEquals(root, base .. '/')
  lu.assertEquals(vim.b.rootDir, base .. '/')
end

function TestRooterRoot:test_no_project_non_root_home()
  default_setup({ project_non_root = 'home' })
  vim.cmd('edit ' .. base .. '/standalone.txt')
  local root = rooter.current_root()
  lu.assertEquals(root, util.unify_path(vim.fn.expand('~')))
  lu.assertEquals(vim.b.rootDir, util.unify_path(vim.fn.expand('~')))
  vim.cmd('lcd ' .. base)
end

function TestRooterRoot:test_no_project_non_root_home_unreadable_bufname()
  default_setup({ project_non_root = 'home' })
  local root = with_buf_name(base .. '/no_such_file.txt')
  -- not readable -> stays with empty rootdir, cwd untouched
  lu.assertEquals(root, '')
  lu.assertEquals(vim.fn.getcwd(), base)
end

function TestRooterRoot:test_no_project_non_root_current()
  default_setup({ project_non_root = 'current' })
  -- chdir away from the file dir so the isdirectory() branch is observable
  local elsewhere = base .. '/elsewhere'
  vim.fn.mkdir(elsewhere, 'p')
  vim.cmd('cd ' .. elsewhere)
  vim.cmd('edit ' .. base .. '/standalone.txt')
  local root = rooter.current_root()
  lu.assertEquals(root, base .. '/')
  vim.cmd('cd ' .. base)
end

function TestRooterRoot:test_no_project_non_root_current_missing_dir()
  default_setup({ project_non_root = 'current' })
  local root = with_buf_name(base .. '/no_such_dir/x.txt')
  lu.assertEquals(root, base .. '/')
end

-- empty buffer names ----------------------------------------------------------

function TestRooterRoot:test_empty_bufname_reuses_alternate_root()
  vim.cmd('edit ' .. base .. '/proj/file.txt')
  rooter.current_root()
  vim.cmd('enew')
  local root = rooter.current_root()
  lu.assertEquals(root, base .. '/proj/')
end

function TestRooterRoot:test_empty_bufname_alternate_without_root()
  vim.cmd('edit ' .. base .. '/standalone.txt')
  vim.fn.setbufvar('%', 'rootDir', '')
  vim.cmd('enew')
  local root = rooter.current_root()
  lu.assertEquals(root, base .. '/')
end

-- exclude patterns -------------------------------------------------------------

function TestRooterRoot:test_default_exclude_patterns()
  local names = {
    '[denite]',
    'denite-filter',
    '[defx]',
    'git://remote/head',
    'neo-tree filesystem [1]',
    'NvimTree_1',
    '__Tagbar__',
  }
  for _, name in ipairs(names) do
    local root = with_buf_name(name)
    lu.assertEquals(root, base, 'buffer should be excluded: ' .. name)
    lu.assertIsNil(vim.b.rootDir, 'excluded buffer must not get a rootDir: ' .. name)
  end
end

function TestRooterRoot:test_custom_exclude_patterns_replace_defaults()
  default_setup({ exclude_patterns = { '^myplug' } })
  -- custom pattern excludes the buffer
  local root = with_buf_name('myplug://scratch')
  lu.assertEquals(root, base)
  lu.assertIsNil(vim.b.rootDir)
  -- default patterns are gone: NvimTree_ is no longer excluded
  local root2 = with_buf_name('NvimTree_1')
  lu.assertEquals(root2, base .. '/')
end

-- nested roots: sort/compare must be exercised with 3+ candidates -------

function TestRooterRoot:test_nested_roots_outermost_with_three_levels()
  vim.fn.mkdir(base .. '/proj/inner/deep/.git', 'p')
  vim.fn.writefile({ 'x' }, base .. '/proj/inner/deep/f.txt')
  vim.cmd('edit ' .. base .. '/proj/inner/deep/f.txt')
  local root = rooter.current_root()
  lu.assertEquals(root, base .. '/proj/')
end

function TestRooterRoot:test_nested_roots_innermost_with_three_levels()
  default_setup({ outermost = false })
  vim.fn.mkdir(base .. '/proj/inner/deep/.git', 'p')
  vim.fn.writefile({ 'x' }, base .. '/proj/inner/deep/f.txt')
  vim.cmd('edit ' .. base .. '/proj/inner/deep/f.txt')
  local root = rooter.current_root()
  lu.assertEquals(root, base .. '/proj/inner/deep/')
end

-- cached rootDir re-entry --------------------------------------------------

function TestRooterRoot:test_cached_root_redir_on_reentry()
  vim.cmd('edit ' .. base .. '/proj/file.txt')
  rooter.current_root()
  -- move away, then re-root: the cached buffer rootDir must be reused and
  -- the directory switch must trigger the project-change callback path
  vim.cmd('lcd ' .. base)
  local root = rooter.current_root()
  lu.assertEquals(root, base .. '/proj/')
  lu.assertEquals(vim.fn.getcwd(), base .. '/proj')
end

-- autochdir ---------------------------------------------------------------------

function TestRooterRoot:test_autochdir_skips_rooting()
  vim.cmd('edit ' .. base .. '/proj/file.txt')
  rooter.current_root()
  vim.cmd('lcd ' .. base)
  vim.o.autochdir = true
  local root = rooter.current_root()
  vim.o.autochdir = false
  -- early return keeps the window-local cwd at base
  lu.assertEquals(root, base)
  lu.assertEquals(vim.fn.getcwd(), base)
end

-- enable/disable ------------------------------------------------------------------

function TestRooterRoot:test_disable_blocks_root_detection()
  rooter.disable()
  vim.cmd('edit ' .. base .. '/proj/file.txt')
  -- BufEnter fired while disabled: nothing happened
  lu.assertEquals(vim.fn.getcwd(), base)
  lu.assertEquals(rooter.current_root(), base)
  lu.assertIsNil(vim.b.rootDir)
  rooter.enable()
  rooter.current_root()
  lu.assertEquals(vim.fn.getcwd(), base .. '/proj')
end

function TestRooterRoot:test_toggle_reenables()
  rooter.toggle()
  lu.assertFalse(rooter.is_enabled())
  vim.cmd('edit ' .. base .. '/proj/file.txt')
  lu.assertEquals(vim.fn.getcwd(), base)
  rooter.toggle()
  lu.assertTrue(rooter.is_enabled())
  rooter.current_root()
  lu.assertEquals(vim.fn.getcwd(), base .. '/proj')
end

-- BufWritePost autocmd -----------------------------------------------------------

function TestRooterRoot:test_bufwritepost_refinds_root()
  vim.cmd('edit ' .. base .. '/proj/file.txt')
  rooter.current_root()
  vim.b.rootDir = base .. '/wrong/'
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = 0 })
  lu.assertEquals(vim.b.rootDir, base .. '/proj/')
end

-- :Rooter user command ----------------------------------------------------------

function TestRooterRoot:test_rooter_command_exists()
  lu.assertEquals(vim.fn.exists(':Rooter'), 2)
end

function TestRooterRoot:test_rooter_command_dispatch()
  vim.cmd('Rooter') -- no args -> current_root
  vim.cmd('Rooter disable')
  lu.assertFalse(rooter.is_enabled())
  vim.cmd('Rooter enable')
  lu.assertTrue(rooter.is_enabled())
  vim.cmd('Rooter toggle')
  lu.assertFalse(rooter.is_enabled())
  vim.cmd('Rooter toggle')
  lu.assertTrue(rooter.is_enabled())
  vim.cmd('Rooter clear')
  lu.assertIsNil(next(rooter.get_project_history()))
end

function TestRooterRoot:test_rooter_command_kill()
  vim.cmd('edit ' .. base .. '/proj/file.txt')
  rooter.current_root()
  local bufnr = vim.fn.bufnr('%')
  vim.b.rooter_project_name = 'killme'
  vim.cmd('enew')
  rooter.kill_project('does_not_exist') -- no-op path
  vim.cmd('Rooter kill killme')
  lu.assertFalse(vim.fn.buflisted(bufnr) == 1)
end

-- list() -----------------------------------------------------------------------

function TestRooterRoot:test_list_uses_picker_when_available()
  vim.api.nvim_create_user_command('Picker', function(opt)
    _G.rooter_picker_args = opt.args
  end, { nargs = '*' })
  rooter.list()
  lu.assertEquals(_G.rooter_picker_args, 'project')
  vim.api.nvim_del_user_command('Picker')
  _G.rooter_picker_args = nil
end

function TestRooterRoot:test_list_falls_back_to_telescope()
  vim.api.nvim_create_user_command('Telescope', function(opt)
    _G.rooter_telescope_args = opt.args
  end, { nargs = '*' })
  rooter.list()
  lu.assertEquals(_G.rooter_telescope_args, 'project')
  vim.api.nvim_del_user_command('Telescope')
  _G.rooter_telescope_args = nil
end

function TestRooterRoot:test_list_notifies_without_picker()
  local notified
  local orig = vim.notify
  vim.notify = function(msg)
    notified = msg
  end
  rooter.list()
  vim.notify = orig
  lu.assertEquals(notified, 'need picker.nvim or telescope.nvim')
end

-- open() -----------------------------------------------------------------------

function TestRooterRoot:test_open_opens_project_in_new_tab()
  vim.cmd('edit ' .. base .. '/proj/file.txt')
  rooter.current_root()
  local tabs_before = vim.fn.tabpagenr('$')
  rooter.open(base .. '/proj/')
  lu.assertEquals(vim.fn.tabpagenr('$'), tabs_before + 1)
  lu.assertEquals(vim.fn.getcwd(), base .. '/proj')
  vim.cmd('silent! tabclose')
end

-- project history ------------------------------------------------------------

function TestRooterRoot:test_project_switch_runs_callbacks()
  _G.rooter_switch_hits = 0
  rooter.reg_callback(function(p)
    _G.rooter_switch_hits = _G.rooter_switch_hits + 1
    _G.rooter_switch_path = p.path
  end, 'switch watcher')
  vim.cmd('edit ' .. base .. '/proj/file.txt')
  rooter.current_root()
  lu.assertTrue(_G.rooter_switch_hits >= 1)
  lu.assertEquals(_G.rooter_switch_path, base .. '/proj/')
  _G.rooter_switch_hits = nil
  _G.rooter_switch_path = nil
end

-- cache ------------------------------------------------------------------------

TestRooterCache = {}

function TestRooterCache:setUp()
  reset_env()
  rooter.clear()
  os.remove(cache_file)
  make_tree()
  vim.cmd('lcd ' .. base)
end

function TestRooterCache:tearDown()
  del_tree()
  os.remove(cache_file)
end

function TestRooterCache:test_cache_written_and_cleared()
  default_setup({ enable_cache = true })
  vim.cmd('edit ' .. base .. '/proj/file.txt')
  rooter.current_root()
  lu.assertEquals(vim.fn.filereadable(cache_file), 1)
  local decoded = vim.json.decode(vim.fn.readfile(cache_file)[1])
  lu.assertNotNil(decoded[base .. '/proj/'])

  rooter.clear()
  local after = vim.json.decode(vim.fn.readfile(cache_file)[1])
  lu.assertEquals(after, {})
end

function TestRooterCache:test_load_cache_filters_invalid_projects()
  local valid = vim.fn.tempname() .. '_rooter_valid'
  vim.fn.mkdir(valid, 'p')
  vim.fn.writefile({
    vim.json.encode({
      [valid .. '/'] = { path = valid .. '/', name = 'valid', opened_time = 1 },
      ['/nonexistent_proj/'] = { path = '/nonexistent_proj/', name = 'gone', opened_time = 2 },
    }),
  }, cache_file)
  default_setup({ enable_cache = true })
  local history = rooter.get_project_history()
  lu.assertNotNil(history[valid .. '/'])
  lu.assertIsNil(history['/nonexistent_proj/'])
  vim.fn.delete(valid, 'rf')
end

function TestRooterCache:test_load_cache_ignores_invalid_json()
  vim.fn.writefile({ '{"broken json' }, cache_file)
  -- must not raise
  default_setup({ enable_cache = true })
  lu.assertIsNil(next(rooter.get_project_history()))
end

function TestRooterCache:test_load_cache_without_file()
  os.remove(cache_file)
  default_setup({ enable_cache = true })
  lu.assertIsNil(next(rooter.get_project_history()))
end

return TestRooterRoot, TestRooterCache

