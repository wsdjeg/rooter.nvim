# rooter.nvim

**rooter.nvim** changes the working directory to the project root when you open a file.
It is inspired by [vim-rooter](https://github.com/airblade/vim-rooter).

This plugin also provides telescope and picker.nvim extensions to fuzzy find recently opened projects.

[![Run Tests](https://github.com/wsdjeg/rooter.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/wsdjeg/rooter.nvim/actions/workflows/test.yml)
[![GitHub License](https://img.shields.io/github/license/wsdjeg/rooter.nvim)](LICENSE)
[![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/wsdjeg/rooter.nvim)](https://github.com/wsdjeg/rooter.nvim/issues)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/wsdjeg/rooter.nvim)](https://github.com/wsdjeg/rooter.nvim/commits/master/)
[![GitHub Release](https://img.shields.io/github/v/release/wsdjeg/rooter.nvim)](https://github.com/wsdjeg/rooter.nvim/releases)
[![luarocks](https://img.shields.io/luarocks/v/wsdjeg/rooter.nvim)](https://luarocks.org/modules/wsdjeg/rooter.nvim)

<!-- vim-markdown-toc GFM -->

- [✨ Features](#-features)
- [📦 Installation](#-installation)
- [🔧 Configuration](#-configuration)
- [⚙️ Basic Usage](#-basic-usage)
    - [Commands](#commands)
    - [Telescope extension](#telescope-extension)
    - [Picker.nvim extension](#pickernvim-extension)
    - [Callback function](#callback-function)
    - [API](#api)
- [🐛 Debug](#-debug)
- [💬 Feedback](#-feedback)
- [🙏 Credits](#-credits)
- [📣 Self-Promotion](#-self-promotion)
- [📄 License](#-license)

<!-- vim-markdown-toc -->

## ✨ Features

- Automatic project root detection on `BufEnter` / `VimEnter`
- Re-detect root on `BufWritePost` (e.g. after creating a new `.git/`)
- Project history caching to disk for persistence across sessions
- Outermost vs nearest root directory support
- Flexible behavior for non-project files (`''`, `'home'`, or `'current'`)
- Automatic logging via [logger.nvim](https://github.com/wsdjeg/logger.nvim) (optional dependency)
- Callback APIs for project switch events
- Command-line interface (`:Rooter`)
- Telescope integration
- Picker.nvim integration

## 📦 Installation

using [nvim-plug](https://github.com/wsdjeg/nvim-plug)

```lua
require('plug').add({
  {
    'wsdjeg/rooter.nvim',
    config = function()
      require('rooter').setup({
        root_patterns = { '.git/' },
      })
    end,
  }
})
```

## 🔧 Configuration

```lua
require('rooter').setup({
  root_patterns = { '.git/' },
  outermost = true,
  enable_cache = true,
  project_non_root = '',
  command = 'lcd',
})
```

| Option            | Type             | Default       | Description                                                                                          |
| ----------------- | ---------------- | ------------- | ---------------------------------------------------------------------------------------------------- |
| `root_patterns`   | `table<string>`  | `{ '.git/' }` | Patterns to identify project root. Directories end with `/`, files do not.                           |
| `outermost`       | `boolean`        | `true`        | When `true`, find the outermost matching directory. When `false`, find the nearest (innermost).      |
| `enable_cache`    | `boolean`        | `true`        | Persist project history to `stdpath('data')/nvim-rooter.json` for cross-session persistence.         |
| `project_non_root`| `string`         | `''`          | Behavior for files outside any project: `''` = keep cwd, `'home'` = switch to `$HOME`, `'current'` = switch to file's directory. |
| `command`         | `string`         | `'lcd'`       | Vim command used to change directory: `'cd'`, `'tcd'`, or `'lcd'`.                                   |

### Example: multiple patterns

```lua
require('rooter').setup({
  root_patterns = { '.git/', '.hg/', 'Cargo.toml', 'go.mod', 'package.json' },
  outermost = false,  -- find nearest root
  command = 'tcd',    -- use tab-local cd
})
```

## ⚙️ Basic Usage

Once `setup()` is called, rooter.nvim automatically changes the working directory
whenever you open a file or switch buffers. You can also use the commands and APIs below.

### Commands

This plugin provides a user command `:Rooter`:

| Command                              | Description                                      |
| ------------------------------------ | ------------------------------------------------ |
| `:Rooter`                            | Manually trigger root detection for current buffer. |
| `:Rooter clear`                      | Clear all cached projects.                       |
| `:Rooter kill project1 project2`     | Delete all buffers belonging to the specified project(s). |

### Telescope extension

Requires [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

```
:Telescope project
```

![Image](https://github.com/user-attachments/assets/f936176a-cace-4bac-b394-c1c11f3f71b7)

Lists all cached projects sorted by last opened time. Press `<CR>` to open a
project in a new tab.

### Picker.nvim extension

Requires [picker.nvim](https://github.com/wsdjeg/picker.nvim).

![picker project](https://github.com/user-attachments/assets/4a53d99c-5319-4f79-afff-0f0f4d6b4e3f)

```
:Picker project
```

Key bindings for picker project:

| Key binding | Description                                                                            |
| ----------- | -------------------------------------------------------------------------------------- |
| `<CR>`      | Open project in a new tab (default action)                                             |
| `<C-f>`     | Browse project files                                                                   |
| `<C-d>`     | Delete project from history                                                            |
| `<C-s>`     | Search text in project, requires [flygrep.nvim](https://github.com/wsdjeg/flygrep.nvim) |

### Callback function

To run custom logic when the project changes, register a callback with
`rooter.reg_callback`:

```lua
-- Update code-runner config based on project's .clang file
local c_runner = {
    exe = 'gcc',
    targetopt = '-o',
    usestdin = true,
    opt = { '-std=c11', '-xc', '-' },
}
require('code-runner').setup({
    runners = {
        c = { c_runner, '#TEMP#' },
    },
})

local function update_clang_flag()
    if vim.fn.filereadable('.clang') == 1 then
        local flags = vim.fn.readfile('.clang')
        local opt = { '-std=c11' }
        for _, v in ipairs(flags) do
            table.insert(opt, v)
        end
        table.insert(opt, '-xc')
        table.insert(opt, '-')
        c_runner.opt = opt
    end
end

require('rooter').reg_callback(update_clang_flag, 'update clang flags')
```

The callback receives no arguments. It is called via `pcall` so errors won't
crash the root detection flow. You can also pass a Vimscript function name as
a string.

### API

| Function                                  | Description                                                      |
| ----------------------------------------- | ---------------------------------------------------------------- |
| `setup(opt)`                              | Initialize rooter.nvim with config options and set up autocmds.  |
| `current_root()`                          | Detect and switch to the project root for the current buffer. Returns the root path. |
| `current_name()`                          | Returns the current project name (from `b:rooter_project_name`). |
| `list()`                                  | Open the project picker (Picker.nvim or Telescope, whichever is available). |
| `open(project_path)`                      | Open a project by its path in a new tab.                         |
| `clear()`                                 | Clear all cached projects and write empty cache to disk.         |
| `kill_project(name)`                      | Delete all buffers belonging to the named project.               |
| `reg_callback(func, desc?)`               | Register a callback function (or Vimscript function name) to run on project switch. `desc` is an optional description for logging. |
| `get_project_history()`                   | Returns the table of all cached projects.                        |

## 🐛 Debug

Install [logger.nvim](https://github.com/wsdjeg/logger.nvim) as a dependency.
Logging is automatically enabled when logger.nvim is available — no extra config needed.

```lua
require('plug').add({
  {
    'wsdjeg/rooter.nvim',
    config = function()
      require('rooter').setup({
        root_patterns = { '.git/' },
      })
    end,
    depends = {
      {
        'wsdjeg/logger.nvim',
        config = function()
          vim.keymap.set(
            'n',
            '<leader>hL',
            '<cmd>lua require("logger").viewRuntimeLog()<cr>',
            { silent = true }
          )
        end,
      },
    },
  },
})
```

Sample runtime log:

```
[   rooter ] [23:22:50:576] [ Info  ] start to find root for: D:/wsdjeg/rooter.nvim/lua/rooter/init.lua
[   rooter ] [23:22:50:576] [ Info  ]         (.git/):D:/wsdjeg/rooter.nvim/
[   rooter ] [23:22:50:576] [ Info  ] switch to project:[rooter.nvim]
[   rooter ] [23:22:50:576] [ Info  ]        rootdir is:D:/wsdjeg/rooter.nvim/
```

## 💬 Feedback

If you encounter any bugs or have suggestions, please file an issue in the [issue tracker](https://github.com/wsdjeg/rooter.nvim/issues)

## 🙏 Credits

- [airblade/vim-rooter](https://github.com/airblade/vim-rooter)
- [DrKJeff16/project.nvim](https://github.com/DrKJeff16/project.nvim)

## 📣 Self-Promotion

Like this plugin? Star the repository on
GitHub.

Love this plugin? Follow [me](https://wsdjeg.net/) on
[GitHub](https://github.com/wsdjeg).

## 📄 License

Licensed under GPL-3.0.

