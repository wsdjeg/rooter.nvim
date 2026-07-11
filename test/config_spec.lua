-- test/config_spec.lua
local lu = require('luaunit')
local config = require('rooter.config')

TestConfig = {}

function TestConfig:test_default_config()
  local cfg = config.setup()
  lu.assertEquals(cfg.root_patterns, { '.git/' })
  lu.assertEquals(cfg.outermost, true)
  lu.assertEquals(cfg.enable_cache, true)
  lu.assertEquals(cfg.project_non_root, '')
  lu.assertEquals(cfg.command, 'lcd')
end

function TestConfig:test_custom_root_patterns()
  local cfg = config.setup({
    root_patterns = { '.git/', 'Makefile', 'package.json' },
  })
  lu.assertEquals(cfg.root_patterns, { '.git/', 'Makefile', 'package.json' })
end

function TestConfig:test_custom_outermost()
  local cfg = config.setup({ outermost = false })
  lu.assertEquals(cfg.outermost, false)
end

function TestConfig:test_custom_enable_cache()
  local cfg = config.setup({ enable_cache = false })
  lu.assertEquals(cfg.enable_cache, false)
end

function TestConfig:test_custom_project_non_root()
  local cfg = config.setup({ project_non_root = 'current' })
  lu.assertEquals(cfg.project_non_root, 'current')
end

function TestConfig:test_custom_command()
  local cfg = config.setup({ command = 'cd' })
  lu.assertEquals(cfg.command, 'cd')
end

function TestConfig:test_nil_opt_uses_defaults()
  local cfg = config.setup(nil)
  lu.assertEquals(cfg.root_patterns, { '.git/' })
  lu.assertEquals(cfg.outermost, true)
end

function TestConfig:test_partial_override_keeps_defaults()
  local cfg = config.setup({ command = 'tcd' })
  -- overridden field
  lu.assertEquals(cfg.command, 'tcd')
  -- default fields preserved
  lu.assertEquals(cfg.root_patterns, { '.git/' })
  lu.assertEquals(cfg.enable_cache, true)
end

return TestConfig

