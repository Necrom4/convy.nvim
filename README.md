# 🧮 convy.nvim

A powerful Neovim plugin to convert between different formats

![output](https://github.com/user-attachments/assets/ef769b97-5e10-41c1-af21-c66a81deb4c0)

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
    notifications = true,
    separator = " ",
    window = {
      blend = 25,
    },
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

## 🚀 Usage

```vim
:Convy <input_format> <output_format>
:Convy " open interactive selection window
```

```lua
lua require("convy").convert("auto", "<output_format>") -- `auto` guesses the format of the input
lua require("convy").convert("<input_format>", "<output_format>", true) -- boolean indicates use of visual selection
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

## 🏆 Roadmap

- [ ] Drop visual-mode flag for util.function that guesses if we executed Convy in visual mode
- [ ] Support for more formats
  - [ ] Colors (RGB, HSL, ...)
  - [ ] Sizes (px, mm, in, ...)
  - [ ] Temperatures (C, F, ...)
- [x] Interactive UI for selecting input/output formats
- [x] Tab completion for conversion formats
- [x] Automatic format detection
