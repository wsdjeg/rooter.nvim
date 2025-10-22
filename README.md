# rooter.nvim

**rooter.nvim** changes the working directory to the project root when you open a file. It is inspired by [vim-rooter](https://github.com/airblade/vim-rooter).

This plugin also provides a telescope extension to fuzzy find recently opened project.

<!-- vim-markdown-toc GFM -->

- [Installation](#installation)
- [Setup](#setup)
- [Telescope extension](#telescope-extension)
- [Picker.nvim extension](#pickernvim-extension)
- [Callback function](#callback-function)
- [Command](#command)
- [Debug](#debug)
- [Self-Promotion](#self-promotion)

<!-- vim-markdown-toc -->

## Installation

using [nvim-plug](https://github.com/wsdjeg/nvim-plug)

```lua
require('plug').add({
  {
    'wsdjeg/rooter.nvim',
    config = function()
      require('rooter').setup({
        root_pattern = { '.git/' },
      })
    end,
  }
})
```

## Setup

```lua
require('rooter').setup({
  root_patterns = { '.git/' },
  outermost = true,
  enable_cache = true,
  project_non_root = '',  -- this can be '', 'home' or 'current'
  enable_logger = true,   -- enable runtime log via logger.nvim
  command = 'lcd',        -- cd, tcd or lcd
})
```

## Telescope extension

This plugin also provides a telescope extension:

```
:Telescope project
```

![Image](https://github.com/user-attachments/assets/f936176a-cace-4bac-b394-c1c11f3f71b7)

## Picker.nvim extension

![picker project](https://github.com/user-attachments/assets/4a53d99c-5319-4f79-afff-0f0f4d6b4e3f)

```
:Picker project
```

key bindings for picker project:

| key binding | description                                                                            |
| ----------- | -------------------------------------------------------------------------------------- |
| `<C-f>`     | file project files                                                                     |
| `<C-d>`     | delete project                                                                         |
| `<C-s>`     | search text in project, require [flygrep.nvim](https://github.com/wsdjeg/flygrep.nvim) |

## Callback function

To add new callback function when project changed. You can use `rooter.reg_callback`, for example:

update c code runner based on project `.clang` file.

```lua
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
vim.keymap.set(
    'n',
    '<leader>lr',
    '<cmd>lua require("code-runner").open()<cr>',
    { silent = true }
)

-- make sure rooter.nvim plugin is loaded before code-runner

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

require('rooter').reg_callback(update_clang_flag)
```

## Command

This plugin also provides a user command `:Rooter`.

1. switch to project root manually.

`:Rooter`

2. clear cached projects.

`:Rooter clear`

3. Delete all buffers for the specified project.

`:Rooter kill project_name1 project_name2`

## Debug

You can enable logger and install logger.nvim to debug this plugin:

```lua
require('plug').add({
  {
    'wsdjeg/rooter.nvim',
    config = function()
      require('rooter').setup({
        root_pattern = { '.git/' },
        enable_logger = true,
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

and the runtime log of rooter is:

```
[   rooter ] [23:22:50:576] [ Info  ] start to find root for: D:/wsdjeg/rooter.nvim/lua/rooter/init.lua
[   rooter ] [23:22:50:576] [ Info  ]         (.git/):D:/wsdjeg/rooter.nvim/
[   rooter ] [23:22:50:576] [ Info  ] switch to project:[rooter.nvim]
[   rooter ] [23:22:50:576] [ Info  ]        rootdir is:D:/wsdjeg/rooter.nvim/
```

## Self-Promotion

Like this plugin? Star the repository on
GitHub.

Love this plugin? Follow [me](https://wsdjeg.net/) on
[GitHub](https://github.com/wsdjeg).
