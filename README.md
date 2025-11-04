# convy.nvim

A powerful Neovim plugin for converting between different data formats (decimal, hexadecimal, binary, octal, ASCII, base64, and more).

## Features

- 🔄 Convert between multiple formats: decimal, hex, binary, octal, ASCII, base64
- 🎯 Smart selection: works with visual selection, word under cursor, or explicit input
- 🤖 Auto-detection of input format
- ⚡ Fast and lightweight
- 🎨 Multiple ways to use: commands or Lua API

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/convy.nvim",
  config = function()
    require("convy").setup({
      -- Optional configuration
      preserve_visual = true,  -- Keep visual selection after conversion
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
```

#### Convenience Commands

```vim
:ConvyToHex    " Convert to hexadecimal (auto-detects input)
:ConvyToDec    " Convert to decimal (auto-detects input)
:ConvyToBin    " Convert to binary (auto-detects input)
:ConvyToAscii  " Convert to ASCII (auto-detects input)
```

### Lua API

#### Basic Conversion

```lua
-- Convert with explicit types
require("convy").convert("dec", "hex", false)  -- false = use word under cursor

-- In visual mode (from a keymap)
require("convy").convert("dec", "ascii", true)  -- true = use visual selection
```

#### Convenience Functions

```lua
-- Convert word under cursor to hex
require("convy").to_hex()

-- Convert specific text to hex
require("convy").to_hex("255")

-- Other convenience functions
require("convy").to_dec()
require("convy").to_bin()
require("convy").to_ascii()
require("convy").to_base64()
require("convy").from_base64()
```

## Usage Examples

### Example 1: Decimal to ASCII

Select text: `72 101 108 108 111`

Run: `:Convy dec ascii`

Result: `Hello`

### Example 2: Hexadecimal to Binary

Place cursor on: `0xFF`

Run: `:ConvyToBin`

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

  -- Preserve visual selection after conversion (default: true)
  preserve_visual = true,
})
```

## Keymapping Examples

Add these to your Neovim config for quick access:

```lua
-- Visual mode mappings
vim.keymap.set("v", "<leader>ch", ":ConvyToHex<CR>", { desc = "Convert to hex" })
vim.keymap.set("v", "<leader>cd", ":ConvyToDec<CR>", { desc = "Convert to decimal" })
vim.keymap.set("v", "<leader>cb", ":ConvyToBin<CR>", { desc = "Convert to binary" })
vim.keymap.set("v", "<leader>ca", ":ConvyToAscii<CR>", { desc = "Convert to ASCII" })

-- Normal mode - converts word under cursor
vim.keymap.set("n", "<leader>ch", ":ConvyToHex<CR>", { desc = "Convert to hex" })
vim.keymap.set("n", "<leader>cd", ":ConvyToDec<CR>", { desc = "Convert to decimal" })

-- Custom conversion
vim.keymap.set("v", "<leader>cx", function()
  vim.ui.input({ prompt = "From type: " }, function(from)
    if not from then return end
    vim.ui.input({ prompt = "To type: " }, function(to)
      if not to then return end
      require("convy").convert(from, to, true)
    end)
  end)
end, { desc = "Custom conversion" })
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

1. **Input Detection**: The plugin detects whether you're using visual selection or word under cursor
2. **Type Detection**: If `auto` is used, it intelligently detects the input format
3. **Conversion**: Converts the input to the desired output format
4. **Replacement**: Replaces the text in the buffer with the converted result

## Roadmap

- [ ] Interactive UI for selecting input/output types
- [ ] Support for more formats (RGB colors, Unicode, URL encoding, etc.)
- [ ] Batch conversion of multiple selections
- [ ] Conversion history
- [ ] Custom user-defined converters

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

## License

MIT License
