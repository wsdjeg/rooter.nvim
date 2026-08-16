-- test/util_spec.lua
local lu = require('luaunit')
local util = require('rooter.util')

TestUtil = {}

function TestUtil:test_unify_path_basic()
  local result = util.unify_path('/tmp')
  lu.assertEquals(string.sub(result, -1), '/')
end

function TestUtil:test_unify_path_with_trailing_slash()
  local result = util.unify_path('/tmp/')
  lu.assertEquals(string.sub(result, -1), '/')
end

function TestUtil:test_unify_path_double_backslash()
  -- backslashes should be converted to forward slashes
  local result = util.unify_path('/home/user\\\\project')
  lu.assertNotNil(string.find(result, '/'))
  lu.assertIsNil(string.find(result, '\\\\'))
end

function TestUtil:test_unify_path_mod_p()
  local result = util.unify_path('~/project', ':p')
  lu.assertNotNil(result)
  lu.assertTrue(#result > 0)
end

function TestUtil:test_unify_path_returns_string()
  local result = util.unify_path('/tmp')
  lu.assertEquals(type(result), 'string')
end

-- a plain file path (not a directory, no trailing slash input) falls
-- through to the untouched-return branch
function TestUtil:test_unify_path_file_keeps_no_trailing_slash()
  local result = util.unify_path('/nonexistent_file_xyz')
  lu.assertEquals(string.sub(result, -1), 'z')
end

-- input ends with '/' but expands to a non-directory: the second branch
-- re-appends the slash
function TestUtil:test_unify_path_trailing_slash_input_on_nondir()
  local result = util.unify_path('/nonexistent_dir_xyz/', ':t')
  lu.assertEquals(string.sub(result, -1), '/')
end

function TestUtil:test_unify_path_default_mod_is_p()
  local result = util.unify_path('/tmp')
  lu.assertEquals(result, '/tmp/')
end

function TestUtil:test_unify_path_win_drive_letter_uppercased()
  -- exercise the win32 branch on any platform via the internal flag;
  -- mod '' passes the value through fnamemodify untouched
  local saved = util._is_win
  util._is_win = true
  local upper = util.unify_path('c:/foo', '')
  local untouched = util.unify_path('cfoo', '')
  util._is_win = saved
  lu.assertEquals(upper, 'C:/foo')
  lu.assertEquals(untouched, 'cfoo')
end

return TestUtil

