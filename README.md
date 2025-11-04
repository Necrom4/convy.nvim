# convy.nvim

A powerful Neovim plugin for converting between different data formats (decimal, hexadecimal, binary, octal, ASCII, base64, and more).

## Features

- 🔄 Convert between multiple formats: decimal, hex, binary, octal, ASCII, base64
- 🎯 Smart selection: works with visual selection or word under cursor automatically
- 🤖 Auto-detection of input format
- 🎨 Interactive floating window UI for type selection
- ⚡ Fast and lightweight
- 📝 Tab completion for conversion types

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/convy.nvim",
  config = function()
    require("convy").setup({
      -- Optional configuration
      notification = true,     -- Show notification after conversion
    })
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "yourusername/convy.nvim",
  config = function()
    require("convy").setup()
  end
}
```

## Usage

### Commands

#### Basic Conversion

```vim
:Convy <from_type> <to_type>
```

Available types: `dec`, `hex`, `bin`, `oct`, `ascii`, `base64`, `auto`

**Examples:**

```vim
" Convert decimal to hexadecimal
" Select "102 115 45" and run:
:Convy dec hex
" Result: 0x66 0x73 0x2d

" Convert decimal to ASCII
" Select "102 115 45" and run:
:Convy dec ascii
" Result: fs-

" Convert hex to decimal
" Place cursor on "0xFF" and run:
:Convy hex dec
" Result: 255

" Auto-detect input type
" Select "0x48 0x65 0x6c 0x6c 0x6f" and run:
:Convy auto ascii
" Result: Hello

" Types have tab completion - just type:
:Convy d<Tab> h<Tab>
" Will complete to: :Convy dec hex
```

#### Interactive Selection

```vim
" Open floating window to select types interactively
:Convy

" Navigate with j/k or arrow keys
" Press Enter to select
" Press Esc or q to cancel
" Press Backspace to go back (when selecting output type)
```

### Lua API

#### Basic Conversion

```lua
-- Convert with explicit types
-- Automatically detects if in visual mode or uses word under cursor
require("convy").convert("dec", "hex")

-- Open interactive selector
require("convy").show_selector()
```

## Usage Examples

### Example 1: Decimal to ASCII

Select text: `72 101 108 108 111`

Run: `:Convy dec ascii`

Result: `Hello`

### Example 2: Hexadecimal to Binary

Place cursor on: `0xFF`

Run: `:Convy auto bin`

Result: `0b11111111`

### Example 3: Text to Base64

Select text: `Hello World`

Run: `:Convy ascii base64`

Result: `SGVsbG8gV29ybGQ=`

### Example 4: Base64 to Text

Select text: `SGVsbG8gV29ybGQ=`

Run: `:Convy base64 ascii`

Result: `Hello World`

### Example 5: Multiple Numbers

Select text: `10 20 30 40`

Run: `:Convy dec hex`

Result: `0xa 0x14 0x1e 0x28`

## Configuration

```lua
require("convy").setup({
  -- Show notifications after conversion (default: true)
  notification = true,
})
```

## Keymapping Examples

Add these to your Neovim config for quick access:

```lua
-- Quick conversion with type arguments
vim.keymap.set({"n", "v"}, "<leader>ch", ":Convy auto hex<CR>", { desc = "Convert to hex" })
vim.keymap.set({"n", "v"}, "<leader>cd", ":Convy auto dec<CR>", { desc = "Convert to decimal" })
vim.keymap.set({"n", "v"}, "<leader>cb", ":Convy auto bin<CR>", { desc = "Convert to binary" })
vim.keymap.set({"n", "v"}, "<leader>ca", ":Convy auto ascii<CR>", { desc = "Convert to ASCII" })

-- Open interactive selector
vim.keymap.set({"n", "v"}, "<leader>cc", ":Convy<CR>", { desc = "Convert (interactive)" })

-- Specific conversions
vim.keymap.set({"n", "v"}, "<leader>c64", ":Convy ascii base64<CR>", { desc = "Encode base64" })
vim.keymap.set({"n", "v"}, "<leader>c46", ":Convy base64 ascii<CR>", { desc = "Decode base64" })
```

## Supported Formats

| Format      | Input Example              | Output Example                                    |
| ----------- | -------------------------- | ------------------------------------------------- |
| Decimal     | `255`                      | `255`                                             |
| Hexadecimal | `0xFF` or `FF`             | `0xff`                                            |
| Binary      | `0b11111111` or `11111111` | `0b11111111`                                      |
| Octal       | `0o377` or `377`           | `0o377`                                           |
| ASCII       | `Hello`                    | `72 101 108 108 111` (when converting to numbers) |
| Base64      | `SGVsbG8=`                 | (depends on conversion)                           |

## How It Works

1. **Input Detection**: The plugin automatically detects whether you're in visual mode or should use the word under cursor
2. **Type Detection**: If `auto` is used, it intelligently detects the input format
3. **Conversion**: Converts the input to the desired output format
4. **Replacement**: Replaces the text in the buffer with the converted result
5. **Interactive UI**: When called without arguments, opens a floating window for easy type selection

## Roadmap

- [x] Interactive UI for selecting input/output types
- [x] Tab completion for conversion types
- [ ] Support for more formats (RGB colors, Unicode, URL encoding, etc.)
- [ ] Batch conversion of multiple selections
- [ ] Conversion history
- [ ] Custom user-defined converters
- [ ] Telescope.nvim integration

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

## License

MIT License
