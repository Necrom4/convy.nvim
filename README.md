# 🧮 convy.nvim

A powerful Neovim plugin to convert between various formats

![showcase](https://github.com/user-attachments/assets/d05045db-326a-4e26-b517-0ca7ecdbbc81)

## ✨ Features

- 🔄 Multiple Formats: from ASCII to binary, Morse and Freedom Units
  - **Encoding**: `ascii`, `bin`, `dec`, `hex`, `oct`, `b64`, `sha256`, `md5`, `morse`, `braille`, `nato`
  - **Data size**: `B`, `KB`, `MB`, `GB`, `TB` (SI), `KiB`, `MiB`, `GiB`, `TiB` (IEC)
  - **Data rate**: `bps`, `kbps`, `mbps`, `gbps`, `tbps`
  - **Length**: `px`, `rem`, `em`, `pt`, `mm`, `cm`, `m`, `km`, `in`, `ft`, `yd`, `mi`, `barleycorn`, `hand`, `fathom`, `chain`, `furlong`, `league`, `nmi`, `angstrom`, `ls`, `au`, `ly`, `pc`
  - **Area**: `mm2`, `cm2`, `m2`, `km2`, `in2`, `ft2`, `yd2`, `mi2`, `ha`, `acre`
  - **Volume**: `ml`, `cl`, `dl`, `l`, `m3`, `tsp`, `tbsp`, `floz`, `cup`, `pint`, `qt`, `gal`
  - **Angle**: `deg`, `rad`, `grad`, `turn`
  - **Time**: `ns`, `us`, `ms`, `s`, `min`, `h`, `day`, `week`, `fortnight`
  - **Speed**: `mps`, `kmh`, `mph`, `fps`, `kn`
  - **Mass**: `mg`, `g`, `kg`, `t`, `oz`, `lb`, `st`
  - **Pressure**: `Pa`, `kPa`, `bar`, `atm`, `psi`, `mmHg`, `torr`
  - **Energy**: `J`, `kJ`, `cal`, `kcal`, `Wh`, `kWh`, `BTU`
  - **Power**: `W`, `kW`, `MW`, `GW`, `hp`
  - **Temperature**: `celsius`, `fahrenheit`, `kelvin`
  - **Frequency**: `Hz`, `kHz`, `MHz`, `GHz`, `THz`
  - **Color**: `hex`, `rgb`, `hsl`, `tailwind`
- 🤖 Auto-detection of input format
- 🎯 Smart selection: works with visual selection or word-under-cursor
- 🌳 Interactive split-window tree UI with search and live result preview

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
      position = "left", -- "left" or "right"
      width = 36,
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
      desc = "Set conversion separator (visual selection)",
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
lua require("convy.utils").set_separator(", ") -- sets the separator to `, `
```

**Interactive window keymaps:**

- Navigation: `Up`/`Down`/`j`/`k`/`Tab`/`g`/`G`
- Select unit: `Enter`/`Space`/`Right`/`l`
- Deselect unit: `Esc`/`BS`
- Open/collapse group: `Enter`/`Space`
- Toggle all groups: `za`
- Search: `/`
- Modify input value: `i`

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
" Opens the split-window selector
" Navigate the tree with `j/k`, open a group with `l`/`right`, search with `/`
" Select the input format (or `auto`) with `<CR>`/`<Space>`
" Then select a compatible output format to apply and close
" Result: 72 101 108 108 111
```

## 🏆 Roadmap

- [ ] Drop visual-mode flag for util.function that guesses if we executed Convy in visual mode
- [x] Support for more formats
  - [x] Colors (RGB, HSL, ...)
  - [x] Sizes (px, mm, in, ...)
  - [x] Temperatures (C, F, ...)
- [x] Interactive UI for selecting input/output formats
- [x] Tab completion for conversion formats
- [x] Automatic format detection
