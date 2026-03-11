# 🧮 convy.nvim

A powerful Neovim plugin to convert between various formats

![showcase](https://github.com/user-attachments/assets/d05045db-326a-4e26-b517-0ca7ecdbbc81)

## ✨ Features

- 🔄 Multiple Formats: from ASCII to binary, Morse and Freedom Units
  - **Text**: `ascii`, `bin`, `dec`, `hex`, `oct`, `b64`, `sha256`, `md5`, `morse`
  - **Data** sizes: `B`, `KB`, `MB`, `GB`, `TB`
  - **Lengths**: `pex`, `rem`, `pt`, `mm`, `cm`, `m`, `km`, `in`, `ft`, `yd`, `mi`
  - **Colors**: `hex`, `rgb`, `hsl`, `tailwind`
  - **Time**: `ms`, `s`, `min`, `h`
  - **Angles**: `deg`, `rad`, `grad`, `turn`
  - **Temperatures**: `celcius`, `fahrenheit`, `kelvin`
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
lua require("convy.utils").set_separator(", ") -- sets the separator to `, `
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

## ⌨ Mapping

```lua
local map = vim.keymap.set

------------------------------------------------
-- TEXT
------------------------------------------------

map({ "n", "x" }, "<leader>cta", "<cmd>Convy auto ascii<cr>",  { desc = "→ ascii" })
map({ "n", "x" }, "<leader>ctb", "<cmd>Convy auto bin<cr>",    { desc = "→ binary" })
map({ "n", "x" }, "<leader>ctd", "<cmd>Convy auto dec<cr>",    { desc = "→ decimal" })
map({ "n", "x" }, "<leader>cth", "<cmd>Convy auto hex<cr>",    { desc = "→ hex" })
map({ "n", "x" }, "<leader>cto", "<cmd>Convy auto oct<cr>",    { desc = "→ octal" })
map({ "n", "x" }, "<leader>ct6", "<cmd>Convy auto b64<cr>",    { desc = "→ base64" })
map({ "n", "x" }, "<leader>ctm", "<cmd>Convy auto md5<cr>",    { desc = "→ md5" })
map({ "n", "x" }, "<leader>cts", "<cmd>Convy auto sha256<cr>", { desc = "→ sha256" })
map({ "n", "x" }, "<leader>ctM", "<cmd>Convy auto morse<cr>",  { desc = "→ morse" })


------------------------------------------------
-- DATA SIZE
------------------------------------------------

map({ "n", "x" }, "<leader>cdB", "<cmd>Convy auto B<cr>",  { desc = "→ B" })
map({ "n", "x" }, "<leader>cdk", "<cmd>Convy auto KB<cr>", { desc = "→ KB" })
map({ "n", "x" }, "<leader>cdm", "<cmd>Convy auto MB<cr>", { desc = "→ MB" })
map({ "n", "x" }, "<leader>cdg", "<cmd>Convy auto GB<cr>", { desc = "→ GB" })
map({ "n", "x" }, "<leader>cdt", "<cmd>Convy auto TB<cr>", { desc = "→ TB" })


------------------------------------------------
-- LENGTH
------------------------------------------------

map({ "n", "x" }, "<leader>clp", "<cmd>Convy auto px<cr>",  { desc = "→ px" })
map({ "n", "x" }, "<leader>clr", "<cmd>Convy auto rem<cr>", { desc = "→ rem" })
map({ "n", "x" }, "<leader>clt", "<cmd>Convy auto pt<cr>",  { desc = "→ pt" })
map({ "n", "x" }, "<leader>clm", "<cmd>Convy auto mm<cr>",  { desc = "→ mm" })
map({ "n", "x" }, "<leader>clc", "<cmd>Convy auto cm<cr>",  { desc = "→ cm" })
map({ "n", "x" }, "<leader>clM", "<cmd>Convy auto m<cr>",   { desc = "→ m" })
map({ "n", "x" }, "<leader>clk", "<cmd>Convy auto km<cr>",  { desc = "→ km" })
map({ "n", "x" }, "<leader>cli", "<cmd>Convy auto in<cr>",  { desc = "→ in" })
map({ "n", "x" }, "<leader>clf", "<cmd>Convy auto ft<cr>",  { desc = "→ ft" })
map({ "n", "x" }, "<leader>cly", "<cmd>Convy auto yd<cr>",  { desc = "→ yd" })
map({ "n", "x" }, "<leader>clI", "<cmd>Convy auto mi<cr>",  { desc = "→ mi" })


------------------------------------------------
-- COLORS
------------------------------------------------

map({ "n", "x" }, "<leader>cch", "<cmd>Convy auto hex<cr>",      { desc = "→ hex" })
map({ "n", "x" }, "<leader>ccr", "<cmd>Convy auto rgb<cr>",      { desc = "→ rgb" })
map({ "n", "x" }, "<leader>ccs", "<cmd>Convy auto hsl<cr>",      { desc = "→ hsl" })
map({ "n", "x" }, "<leader>cct", "<cmd>Convy auto tailwind<cr>", { desc = "→ tailwind" })


------------------------------------------------
-- TIME
------------------------------------------------

map({ "n", "x" }, "<leader>cTm", "<cmd>Convy auto ms<cr>",  { desc = "→ ms" })
map({ "n", "x" }, "<leader>cTs", "<cmd>Convy auto s<cr>",   { desc = "→ s" })
map({ "n", "x" }, "<leader>cTi", "<cmd>Convy auto min<cr>", { desc = "→ min" })
map({ "n", "x" }, "<leader>cTh", "<cmd>Convy auto h<cr>",   { desc = "→ h" })


------------------------------------------------
-- ANGLES
------------------------------------------------

map({ "n", "x" }, "<leader>cad", "<cmd>Convy auto deg<cr>",  { desc = "→ deg" })
map({ "n", "x" }, "<leader>car", "<cmd>Convy auto rad<cr>",  { desc = "→ rad" })
map({ "n", "x" }, "<leader>cag", "<cmd>Convy auto grad<cr>", { desc = "→ grad" })
map({ "n", "x" }, "<leader>cat", "<cmd>Convy auto turn<cr>", { desc = "→ turn" })


------------------------------------------------
-- TEMPERATURE
------------------------------------------------

map({ "n", "x" }, "<leader>cec", "<cmd>Convy auto celcius<cr>",    { desc = "→ celcius" })
map({ "n", "x" }, "<leader>cef", "<cmd>Convy auto fahrenheit<cr>", { desc = "→ fahrenheit" })
map({ "n", "x" }, "<leader>cek", "<cmd>Convy auto kelvin<cr>",     { desc = "→ kelvin" })
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
