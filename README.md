# 🧮 convy.nvim

A powerful Neovim plugin to convert between various formats

![showcase](https://github.com/user-attachments/assets/d05045db-326a-4e26-b517-0ca7ecdbbc81)

## ✨ Features

- 🔄 Multiple Formats: from ASCII to binary, Morse and Freedom Units
  - **Encoding**: `ascii`, `bin`, `dec`, `hex`, `oct`, `b64`, `sha256`, `md5`, `morse`, `braille`, `nato`
  - **Data size**: `B`, `KB`, `MB`, `GB`, `TB` (SI), `KiB`, `MiB`, `GiB`, `TiB` (IEC)
  - **Data rate**: `bps`, `kbps`, `mbps`, `gbps`, `tbps`
  - **Length**: `px`, `em`, `rem`, `pt`, `pica`, `mm`, `cm`, `m`, `km`, `in`, `ft`, `yd`, `mi`, `barleycorn`, `bolt`, `cable`, `chain`, `clothyard`, `cubit`, `ell`, `fathom`, `finger`, `furlong`, `hand`, `league`, `line`, `link`, `megalithicyard`, `nail`, `nmi`, `palm`, `poppyseed`, `pyramidinch`, `rod`, `shackle`, `span`, `thou`, `angstrom`, `ls`, `au`, `ly`, `pc`
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
- 🧩 Custom formats: add your own units or conversions from your config

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
    formats = {
      -- custom formats, see section below
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

- Navigation: `Up`/`Down`/`j`/`k`/`Tab`/`gg`/`G`
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

## 🧩 Custom formats

Add your own units or conversions through `setup({ formats = { ... } })`.
Each entry either `extend`s a built-in group or defines a new `key`/`kind`
group. New formats appear in the selector, tab-completion and `:Convy`.

### Add a unit to an existing group

`length` is a `linear` group, so a new unit is just a `suffix` and a
`factor` relative to the group's base (meters):

```lua
require("convy").setup({
  formats = {
    { extend = "length", formats = {
      { name = "smoot", suffix = "smoot", factor = 1.7018 },
    }},
  },
})
-- :Convy smoot m -> 1smoot becomes 1.7018m
```

### Define a new group with custom conversions

A `custom` group converts through a shared base: each format provides
`decode(text) -> base` and `encode(base) -> text`. Conversion is
`out.encode(in.decode(text))`, so N formats only need N function pairs.

This example treats a uint32 as a Unix timestamp (epoch seconds) and
converts between the raw integer, hex, and an ISO 8601 UTC date:

```lua
local function iso_to_epoch(text)
  local y, mo, d, h, mi, s = text:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not y then return nil end
  -- os.time uses local time; subtract the local UTC offset to get UTC epoch.
  local utc_offset = os.time(os.date("!*t", 0))
  return os.time({
    year = tonumber(y), month = tonumber(mo), day = tonumber(d),
    hour = tonumber(h), min = tonumber(mi), sec = tonumber(s), isdst = false,
  }) - utc_offset
end

require("convy").setup({
  formats = {
    {
      key = "epoch",
      label = "Epoch Date",
      kind = "custom",
      formats = {
        {
          name = "unix",
          decode = function(text) return tonumber(text) end,
          encode = function(secs) return tostring(math.floor(secs)) end,
        },
        {
          name = "hex32",
          decode = function(text) return tonumber(text, 16) end,
          encode = function(secs) return string.format("%08X", secs) end,
        },
        {
          name = "iso",
          display = "ISO date",
          -- optional: makes `auto` recognise ISO dates
          detect = function(text) return text:match("^%d%d%d%d%-%d%d%-%d%dT") ~= nil end,
          decode = iso_to_epoch,
          encode = function(secs) return os.date("!%Y-%m-%dT%H:%M:%SZ", secs) end,
        },
      },
    },
  },
})
-- :Convy unix iso     ->  1700000000 becomes 2023-11-14T22:13:20Z
-- :Convy auto unix    ->  2023-11-14T22:13:20Z becomes 1700000000
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
