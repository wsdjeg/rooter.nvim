# rooter.nvim

`rooter.nvim` changes the working directory to the project root when you open a file. It is inspired by [vim-rooter](https://github.com/airblade/vim-rooter).

<!-- vim-markdown-toc GFM -->

* [Installation](#installation)
* [Setup](#setup)
* [Telescope extension](#telescope-extension)
* [Debug](#debug)
* [Self-Promotion](#self-promotion)

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
[GitHub](https://github.com/wsdjeg) and
[Twitter](http://twitter.com/wsdtty).
