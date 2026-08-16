-- test/install_deps.lua
-- Cross-platform test dependency installer
-- Replaces shell-based makefile targets (if [ ... ]; then ... fi doesn't work on Windows)

local function mkdir(path)
  vim.fn.mkdir(path, 'p')
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function download(url, dest)
  -- Use Neovim's built-in curl-like capability via vim.fn.system
  -- or fall back to LuaSocket if available
  local has_curl = vim.fn.executable('curl') == 1
  if has_curl then
    local cmd = { 'curl', '-fsSL', url, '-o', dest }
    local result = vim.fn.system(cmd)
    return vim.v.shell_error == 0
  end

  -- Fallback: try powershell on Windows
  if vim.fn.has('win32') == 1 then
    local ps_cmd = string.format(
      "Invoke-WebRequest -Uri '%s' -OutFile '%s'",
      url, dest
    )
    local result = vim.fn.system({ 'powershell', '-Command', ps_cmd })
    return vim.v.shell_error == 0
  end

  -- Fallback: try wget
  local has_wget = vim.fn.executable('wget') == 1
  if has_wget then
    local cmd = { 'wget', '-q', '-O', dest, url }
    local result = vim.fn.system(cmd)
    return vim.v.shell_error == 0
  end

  return false
end

local deps_dir = 'test/.deps'
mkdir(deps_dir)

-- Install luaunit
local luaunit_path = deps_dir .. '/luaunit.lua'
local luaunit_url = 'https://raw.githubusercontent.com/bluebird75/luaunit/main/luaunit.lua'

if file_exists(luaunit_path) then
  print('luaunit already installed')
else
  print('Installing luaunit...')
  if download(luaunit_url, luaunit_path) then
    print('luaunit installed to ' .. luaunit_path)
  else
    print('[ERROR] Failed to download luaunit')
    os.exit(1)
  end
end

-- Install luacov (line coverage tool, pure Lua)
local luacov_base = 'https://raw.githubusercontent.com/keplerproject/luacov/master/src'
local luacov_files = {
  { 'luacov.lua', luacov_base .. '/luacov.lua' },
  { 'luacov/defaults.lua', luacov_base .. '/luacov/defaults.lua' },
  { 'luacov/hook.lua', luacov_base .. '/luacov/hook.lua' },
  { 'luacov/linescanner.lua', luacov_base .. '/luacov/linescanner.lua' },
  { 'luacov/reporter.lua', luacov_base .. '/luacov/reporter.lua' },
  { 'luacov/runner.lua', luacov_base .. '/luacov/runner.lua' },
  { 'luacov/stats.lua', luacov_base .. '/luacov/stats.lua' },
  { 'luacov/tick.lua', luacov_base .. '/luacov/tick.lua' },
  { 'luacov/util.lua', luacov_base .. '/luacov/util.lua' },
}

mkdir(deps_dir .. '/luacov')

local luacov_failed = false
for _, dep in ipairs(luacov_files) do
  local dest = deps_dir .. '/' .. dep[1]
  if file_exists(dest) then
    print('luacov file already installed: ' .. dep[1])
  else
    print('Installing luacov file: ' .. dep[1])
    if download(dep[2], dest) then
      print('luacov file installed to ' .. dest)
    else
      print('[ERROR] Failed to download ' .. dep[2])
      luacov_failed = true
    end
  end
end

if luacov_failed then
  -- coverage is optional for plain `make test`; only hard-fail on the runner entry
  if not file_exists(deps_dir .. '/luacov/runner.lua') then
    print('[WARN] luacov runner missing, `make coverage` will not work')
  end
end

print('All dependencies installed.')
os.exit(0)

