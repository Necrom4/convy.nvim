# 🧮 convy.nvim

A powerful Neovim plugin to convert between different formats

<!--toc:start-->

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Roadmap](#roadmap)
<!--toc:end-->

## ✨ Features

- 🔄 Convert between multiple formats: ASCII, base64, decimal, hex, octal
- 🤖 Auto-detection of input format
- 🎯 Smart selection: works with visual selection or word-under-cursor
- 🎨 Interactive floating window UI for format selection

## 📦 Installation

```lua
{
  "necrom4/convy.nvim",
  cmd = "Convy",
  opts = {}
}
```

## ⚙️ Configuration

```lua
{
  opts = {
    -- default configuration
    notification = true,
  },
  keys = {
    -- example keymaps
    {
      "<leader>cc",
      ":Convy<CR>",
      desc = "Convert (interactive selection)",
      mode = { "n", "v" },
      silent = true,
    },
    {
      "<leader>cd",
      ":Convy auto dec<CR>",
      desc = "Convert to decimal",
      mode = { "n", "v" },
      silent = true,
    },
  }
}
```

## Usage

```vim
:Convy <from_type> <to_type>
:Convy " open interactive selection window
```

```lua
lua require("convy").convert("auto", "<to_type>") -- `auto` guesses the type of the input
lua require("convy").convert("<from_type>", "<to_type>", true) -- boolean indicates use of visual selection
lua require("convy").show_selector() -- open interactive selection window
```

**Examples:**

> `|` represents the cursor's position, `[ ... ]` represents a visual selection.

```vim
" 72 1|01 108 108 111
:Convy auto ascii
" Converts hovered word from decimal to ascii
" Result: 72 e 108 108 111

" [72 101 108 108 111]
:Convy auto ascii
" Converts selection from decimal to ascii
" Result: Hello

" [Hello]
:Convy
" Opens the interactive selection window
" Choose the input format (ascii) with `j/k` and accept with `<CR>`
" Choose the output format (dec) with `j/k` and accept with `<CR>`
" Converts selection from decimal to ascii
" Result: 72 101 108 108 111
```

## Roadmap

- [ ] Drop visual-mode flag for util.function that guesses if we executed Convy in visual mode
- [ ] Support for more formats
  - [ ] Colors (RGB, HSL, ...)
  - [ ] Sizes (px, mm, in, ...)
  - [ ] Temperatures (C, F, ...)
- [x] Interactive UI for selecting input/output types
- [x] Tab completion for conversion types
- [x] Automatic format detection
