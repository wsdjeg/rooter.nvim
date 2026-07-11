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

return TestUtil

