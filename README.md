# 🧮 convy.nvim

A powerful Neovim plugin to convert between various formats

![output](https://github.com/user-attachments/assets/ef769b97-5e10-41c1-af21-c66a81deb4c0)

## ✨ Features

- 🔄 Formats: ASCII, binary, decimal, hex, octal, base64, morse
- 🤖 Auto-detection of input format
- 🎯 Smart selection: works with visual selection or word-under-cursor
- 🎨 Interactive floating window UI for format selection

## 📦 Installation

```lua
{
  "necrom4/convy.nvim",
  cmd = { "Convy", "ConvySeparator" },
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
      border = "rounded"
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
    {
      "<leader>cs",
      ":ConvySeparator<CR>",
      desc = "Set convertion separator (visual selection)",
      mode = { "v" },
      silent = true,
    },
  }
}
```

## 🚀 Usage

```vim
:Convy <input_format> <output_format>
:Convy " open interactive selection window
:'<,'>Convy <<input_format> <output_format>> " visual selection as string to work on
```

```lua
lua require("convy").convert("auto", "<output_format>") -- `auto` guesses the format of the input
lua require("convy").convert("<input_format>", "<output_format>", true) -- boolean indicates use of visual selection
lua require("convy").show_selector() -- open interactive selection window
```

```vim
:ConvySeparator ", " " sets the separator to `, `
:ConvySeparator \", \" " sets the separator to `", "`
:ConvySeparator | - | " spaces are not ignored, this sets the separator to `| - |`
:'<,'>ConvySeparator " visual selection as selector
```

```lua
lua require("convy.utils").separator(", ") -- sets the separator to `, `
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
