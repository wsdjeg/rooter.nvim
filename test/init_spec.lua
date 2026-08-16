-- test/init_spec.lua
local lu = require('luaunit')
local rooter = require('rooter')

TestRooter = {}

function TestRooter:test_module_exists()
  lu.assertNotNil(rooter)
  lu.assertEquals(type(rooter), 'table')
end

function TestRooter:test_setup_function_exists()
  lu.assertEquals(type(rooter.setup), 'function')
end

function TestRooter:test_current_root_function_exists()
  lu.assertEquals(type(rooter.current_root), 'function')
end

function TestRooter:test_list_function_exists()
  lu.assertEquals(type(rooter.list), 'function')
end

function TestRooter:test_open_function_exists()
  lu.assertEquals(type(rooter.open), 'function')
end

function TestRooter:test_clear_function_exists()
  lu.assertEquals(type(rooter.clear), 'function')
end

function TestRooter:test_current_name_function_exists()
  lu.assertEquals(type(rooter.current_name), 'function')
end

function TestRooter:test_reg_callback_function_exists()
  lu.assertEquals(type(rooter.reg_callback), 'function')
end

function TestRooter:test_kill_project_function_exists()
  lu.assertEquals(type(rooter.kill_project), 'function')
end

function TestRooter:test_get_project_history_function_exists()
  lu.assertEquals(type(rooter.get_project_history), 'function')
end

-- toggle / enable / disable ------------------------------------------------

function TestRooter:test_enable_disable_is_enabled()
  lu.assertTrue(rooter.is_enabled())
  lu.assertEquals(rooter.disable(), false)
  lu.assertFalse(rooter.is_enabled())
  lu.assertEquals(rooter.enable(), true)
  lu.assertTrue(rooter.is_enabled())
end

function TestRooter:test_toggle_flips_state()
  local before = rooter.is_enabled()
  lu.assertEquals(rooter.toggle(), not before)
  lu.assertEquals(rooter.is_enabled(), not before)
  lu.assertEquals(rooter.toggle(), before)
  lu.assertEquals(rooter.is_enabled(), before)
end

-- current_name ---------------------------------------------------------------

function TestRooter:test_current_name_returns_string()
  local name = rooter.current_name()
  lu.assertEquals(type(name), 'string')
end

function TestRooter:test_current_name_empty_without_project()
  vim.b.rooter_project_name = nil
  lu.assertEquals(rooter.current_name(), '')
end

function TestRooter:test_current_name_reads_bufvar()
  vim.b.rooter_project_name = 'myproj'
  lu.assertEquals(rooter.current_name(), 'myproj')
  vim.b.rooter_project_name = nil
end

-- get_project_history ---------------------------------------------------------

function TestRooter:test_get_project_history_returns_table()
  local history = rooter.get_project_history()
  lu.assertEquals(type(history), 'table')
end

-- reg_callback ---------------------------------------------------------------

function TestRooter:test_reg_callback_with_function()
  rooter.reg_callback(function() end, 'test callback')
  lu.assertTrue(true)
end

function TestRooter:test_reg_callback_with_desc()
  rooter.reg_callback(function() end, 'my description')
  lu.assertTrue(true)
end

function TestRooter:test_reg_callback_without_desc()
  rooter.reg_callback(function() end)
  lu.assertTrue(true)
end

function TestRooter:test_reg_callback_ignores_invalid_type()
  -- numbers (or anything else) are silently ignored
  rooter.reg_callback(42)
  rooter.reg_callback(nil)
  lu.assertTrue(true)
end

function TestRooter:test_callback_receives_project_object()
  local received = nil
  rooter.reg_callback(function(project)
    received = project
  end, 'capture project object')
  rooter.RootchandgeCallback()
  lu.assertNotNil(received)
  lu.assertEquals(type(received), 'table')
  lu.assertEquals(type(received.path), 'string')
  lu.assertNotEquals(received.path, '')
  lu.assertEquals(type(received.name), 'string')
  lu.assertNotEquals(received.name, '')
  lu.assertEquals(type(received.opened_time), 'number')
end

function TestRooter:test_callback_no_args_still_works()
  local called = false
  rooter.reg_callback(function()
    called = true
  end, 'no args callback')
  rooter.RootchandgeCallback()
  lu.assertTrue(called)
end

function TestRooter:test_callback_project_matches_current_root()
  local received = nil
  rooter.reg_callback(function(project)
    received = project
  end, 'check root path')
  rooter.RootchandgeCallback()
  -- project.path is the unified cwd with trailing separator
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ':p')
  lu.assertEquals(received.path, cwd)
end

function TestRooter:test_string_name_callback_is_called_via_fn_call()
  -- String names are resolved via vim.fn.call, which only sees Vimscript
  -- functions. Define a real one to exercise that path. The function must
  -- stay defined for the rest of the session: there is no unregister API,
  -- so deleting it would leave a dangling entry that errors on every
  -- subsequent RootchandgeCallback call.
  vim.cmd([[
    function! RooterVimslCb(project)
      let g:rooter_vimsl_hits = get(g:, 'rooter_vimsl_hits', 0) + 1
    endfunction
  ]])
  rooter.reg_callback('RooterVimslCb', 'string name callback')
  local before = vim.g.rooter_vimsl_hits or 0
  rooter.RootchandgeCallback()
  lu.assertEquals(vim.g.rooter_vimsl_hits, before + 1)
end

function TestRooter:test_string_name_callback_without_desc()
  vim.cmd([[
    function! RooterNodescCb(project)
      let g:rooter_nodesc_hits = get(g:, 'rooter_nodesc_hits', 0) + 1
    endfunction
  ]])
  rooter.reg_callback('RooterNodescCb')
  local before = vim.g.rooter_nodesc_hits or 0
  rooter.RootchandgeCallback()
  lu.assertEquals(vim.g.rooter_nodesc_hits, before + 1)
end

function TestRooter:test_function_callback_error_is_contained()
  rooter.reg_callback(function()
    error('boom')
  end, 'exploding callback')
  -- pcall inside RootchandgeCallback must swallow the error
  rooter.RootchandgeCallback()
  lu.assertTrue(true)
end

-- logger wrapper ---------------------------------------------------------------

function TestRooter:test_logger_uses_logger_nvim_when_available()
  -- provide a mock logger.nvim via package.preload so both branches of the
  -- lazy require (first call derives, later calls reuse the handle) run
  local recorded = {}
  package.preload['logger'] = function()
    return {
      derive = function(name)
        recorded.derived_from = name
        local handle = {}
        for _, f in ipairs({ 'info', 'debug', 'warn', 'error' }) do
          handle[f] = function(msg)
            recorded[f] = msg
          end
        end
        return handle
      end,
    }
  end
  local lg = require('rooter.logger')
  lg.info('first call derives the logger')
  lu.assertEquals(recorded.derived_from, 'rooter')
  lu.assertEquals(recorded.info, 'first call derives the logger')
  lg.warn('second call reuses the cached logger')
  lu.assertEquals(recorded.warn, 'second call reuses the cached logger')
  package.preload['logger'] = nil
end

return TestRooter

