-- test/coverage_report.lua
-- Parse luacov.stats.out and enforce the coverage threshold (default 100%)
-- for the plugin sources.
--
-- Line accounting replicates luacov's own reporter: each source line is fed
-- through luacov's LineScanner, which classifies lines as "always excluded"
-- (comments, blanks, etc.), "excluded when not hit" (structural closers like
-- `end`, `)`, `else`) or active. Only active lines count towards coverage.
--
-- Two checks:
--   1. line coverage: every active line recorded by luacov must have hits
--   2. dead functions: every function definition line must appear in the
--      stats (a never-called function is never recorded by luacov, which
--      would otherwise silently inflate the percentage)
--
-- Scope: lua/rooter/*.lua and plugin/rooter.lua.
-- The picker/telescope integration files are excluded because they cannot
-- be loaded without their host plugins.
--
-- Exits with code 1 when any file is below threshold.

local THRESHOLD = tonumber(vim.env.COV_THRESHOLD or '100') or 100

package.path = 'test/.deps/?.lua;' .. package.path
local LineScanner = require('luacov.linescanner')

-- repo path -> chunk basename as recorded in the stats file
local scope = {
  ['lua/rooter/init.lua'] = 'init.lua',
  ['lua/rooter/config.lua'] = 'config.lua',
  ['lua/rooter/logger.lua'] = 'logger.lua',
  ['lua/rooter/util.lua'] = 'util.lua',
  ['plugin/rooter.lua'] = 'rooter.lua',
}

-- parse luacov.stats.out: chunk headers then "count count count..." lines.
-- Header formats (luacov >= 0.16 writes "<max>:<chunkname>", older wrote
-- "=<chunkname>"); both are supported here.
local stats = {} -- basename -> { [line] = count }
local current
for line in io.lines('luacov.stats.out') do
  local name
  if line:sub(1, 1) == '=' then
    name = line:sub(2)
  else
    name = line:match('^%d+:(.+)$')
  end
  if name then
    local base = name:match('[^/\\]+$') or name
    local known = false
    for _, b in pairs(scope) do
      if b == base then
        known = true
      end
    end
    if known then
      stats[base] = stats[base] or {}
      current = stats[base]
    else
      current = nil
    end
  elseif current then
    local line_no = 1
    for count in line:gmatch('%d+') do
      current[line_no] = (current[line_no] or 0) + tonumber(count)
      line_no = line_no + 1
    end
  end
end

-- a function definition line (used for the dead-function check)
local function is_func_def(line)
  if line:match('^%s*%-%-') then
    return false
  end
  return line:match('^%s*local%s+function%s')
    or line:match('^%s*function%s')
    or line:match('^%s*[A-Za-z_][%w_.%[%]"\']*%s*=%s*function%s*%(')
end

local failed = false
print(string.format('=== Coverage Report (threshold: %d%%) ===', THRESHOLD))

for file, base in pairs(scope) do
  local counts = stats[base] or {}
  local total, hit = 0, 0
  local missed = {}
  local dead = {}

  local src_lines = vim.fn.readfile(file)

  -- line accounting identical to luacov's reporter
  local scanner = LineScanner:new()
  for line_no, src in ipairs(src_lines) do
    local always_excluded, excluded_when_not_hit = scanner:consume(src)
    local hits = counts[line_no] or 0
    local included = not always_excluded and (not excluded_when_not_hit or hits ~= 0)
    if included then
      total = total + 1
      if hits > 0 then
        hit = hit + 1
      else
        table.insert(missed, line_no)
      end
    end
  end

  -- dead-function check against the real source
  for line_no, src in ipairs(src_lines) do
    if is_func_def(src) and counts[line_no] == nil then
      table.insert(dead, line_no)
    end
  end

  if total == 0 then
    print(string.format('[FAIL] %-24s no coverage data (never executed?)', file))
    failed = true
  else
    local pct = math.floor(hit / total * 100 + 0.5)
    local mark = 'OK  '
    if pct < THRESHOLD or #dead > 0 then
      mark = 'FAIL'
      failed = true
    end
    print(string.format('[%s] %-24s %d/%d lines  %d%%', mark, file, hit, total, pct))
    for _, line_no in ipairs(missed) do
      print(string.format('        missed  %s:%d  %s', file, line_no, src_lines[line_no] or ''))
    end
    for _, line_no in ipairs(dead) do
      print(string.format('        function never executed  %s:%d  %s', file, line_no, src_lines[line_no] or ''))
    end
  end
end

if failed then
  print('=== Coverage check FAILED ===')
  os.exit(1)
else
  print('=== Coverage check PASSED ===')
  os.exit(0)
end

