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

function TestRooter:test_current_name_returns_string()
  local name = rooter.current_name()
  lu.assertEquals(type(name), 'string')
end

function TestRooter:test_get_project_history_returns_table()
  local history = rooter.get_project_history()
  lu.assertEquals(type(history), 'table')
end

function TestRooter:test_reg_callback_with_function()
  local called = false
  rooter.reg_callback(function()
    called = true
  end, 'test callback')
  -- callback registered without error
  lu.assertTrue(true)
end

function TestRooter:test_reg_callback_with_desc()
  rooter.reg_callback(function() end, 'my description')
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

return TestRooter

