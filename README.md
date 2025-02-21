# rooter.nvim

`rooter.nvim` changes the working directory to the project root when you open a file. It is inspired by [vim-rooter](https://github.com/airblade/vim-rooter).

## Install

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
})
```

## Telescope extension

This plugin also provides a telescope extension:

```
:Telescope project
```

