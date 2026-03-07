local M = {}

function M.notify(msg, level, opts)
	if not require("convy").config.notifications then
		return
	end

	opts = opts or {}
	opts.title = opts.title or "Convy"

	vim.notify(msg, level or vim.log.levels.INFO, opts)
end

function M.set_separator(sep)
	require("convy").config.separator = sep
	vim.notify("Convy separator changed to: " .. sep)
end

function M.get_visual_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_line = start_pos[2]
	local start_col = start_pos[3]
	local end_line = end_pos[2]
	local end_col = end_pos[3]

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

	if #lines == 0 then
		return nil, nil, nil
	end

	-- Handle single line selection
	if #lines == 1 then
		lines[1] = lines[1]:sub(start_col, end_col)
	else
		-- Handle multi-line selection
		lines[1] = lines[1]:sub(start_col)
		lines[#lines] = lines[#lines]:sub(1, end_col)
	end

	local text = table.concat(lines, "\n")

	return text, { start_line, start_col }, { end_line, end_col }
end

function M.get_word_under_cursor()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = cursor[1]
	local col = cursor[2] + 1

	local line_text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]

	if not line_text or line_text == "" then
		return nil, nil, nil
	end

	-- Define word boundary characters (alphanumeric, underscore, and hex-related)
	local function is_word_char(char)
		return char:match("[%w_%.%%%°#%(%)%-]") ~= nil
	end

	-- If cursor is on a space or boundary, return nothing
	local char_under_cursor = line_text:sub(col, col)
	if not is_word_char(char_under_cursor) then
		return nil, nil, nil
	end

	-- Find start of word
	local start_col = col
	while start_col > 1 do
		local prev_char = line_text:sub(start_col - 1, start_col - 1)
		-- Stop at delimiters
		if not is_word_char(prev_char) or prev_char:match("[%[%]%{%};]") then
			break
		end
		start_col = start_col - 1
	end

	-- Find end of word
	local end_col = col
	while end_col <= #line_text do
		local next_char = line_text:sub(end_col + 1, end_col + 1)
		-- Stop at delimiters
		if next_char == "" or not is_word_char(next_char) or next_char:match("[%[%]%{%};]") then
			break
		end
		end_col = end_col + 1
	end

	local word = line_text:sub(start_col, end_col)

	return word, { line, start_col }, { line, end_col }
end

function M.replace_text(start_pos, end_pos, new_text)
	local start_line, start_col = start_pos[1], start_pos[2]
	local end_line, end_col = end_pos[1], end_pos[2]

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

	if #lines == 0 then
		return
	end

	-- Split new text into lines
	local new_lines = vim.split(new_text, "\n", { plain = true })

	if #lines == 1 then
		-- Single line replacement
		local before = lines[1]:sub(1, start_col - 1)
		local after = lines[1]:sub(end_col + 1)
		new_lines[1] = before .. new_lines[1]
		new_lines[#new_lines] = new_lines[#new_lines] .. after
	else
		-- Multi-line replacement
		local before = lines[1]:sub(1, start_col - 1)
		local after = lines[#lines]:sub(end_col + 1)
		new_lines[1] = before .. new_lines[1]
		new_lines[#new_lines] = new_lines[#new_lines] .. after
	end

	-- Replace in buffer
	vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_lines)
end

-- Auto-detect input format
function M.detect_format(text)
	-- Remove whitespace for detection
	local clean = text:match("^%s*(.-)%s*$") or text
	local no_spaces = text:gsub("%s", "")

	-- ── Color formats ──────────────────────────────────────────────

	if clean:match("^hsl%s*%(") then
		return "hsl"
	end

	if clean:match("^rgb%s*%(") then
		return "rgb"
	end

	if clean:match("^#%x%x%x%x%x%x$") or clean:match("^#%x%x%x$") then
		return "hex_color"
	end

	local color_mod = require("convy.converters.color")
	if color_mod.is_tailwind_color(clean) then
		return "tailwind"
	end

	-- ── Temperature formats ────────────────────────────────────────

	local no_degree = clean:gsub("°", "")

	if no_degree:match("^%-?[%d%.]+K$") then
		return "kelvin"
	end

	if no_degree:match("^%-?[%d%.]+F$") then
		return "fahrenheit"
	end

	if no_degree:match("^%-?[%d%.]+C$") then
		return "celsius"
	end

	-- ── Angle formats ──────────────────────────────────────────────

	if clean:match("^%-?[%d%.]+turn$") then
		return "turn"
	end

	if clean:match("^%-?[%d%.]+grad$") then
		return "grad"
	end

	if clean:match("^%-?[%d%.]+rad$") then
		return "rad"
	end

	if clean:match("^%-?[%d%.]+deg$") then
		return "deg"
	end

	-- ── Time formats ───────────────────────────────────────────────

	-- Must check "min" before "m" (length) and "ms" before "m"
	if clean:match("^[%d%.]+ms$") then
		return "ms"
	end

	if clean:match("^[%d%.]+min$") then
		return "min"
	end

	if clean:match("^[%d%.]+h$") then
		return "h"
	end

	if clean:match("^[%d%.]+s$") then
		return "s"
	end

	-- ── Data size formats ──────────────────────────────────────────

	if clean:match("^[%d%.]+TB$") then
		return "TB"
	end

	if clean:match("^[%d%.]+GB$") then
		return "GB"
	end

	if clean:match("^[%d%.]+MB$") then
		return "MB"
	end

	if clean:match("^[%d%.]+KB$") then
		return "KB"
	end

	if clean:match("^[%d%.]+B$") then
		return "B"
	end

	-- ── Length formats ─────────────────────────────────────────────

	if clean:match("^%-?[%d%.]+px$") then
		return "px"
	end

	if clean:match("^%-?[%d%.]+rem$") then
		return "rem"
	end

	if clean:match("^%-?[%d%.]+pt$") then
		return "pt"
	end

	if clean:match("^%-?[%d%.]+km$") then
		return "km"
	end

	if clean:match("^%-?[%d%.]+cm$") then
		return "cm"
	end

	if clean:match("^%-?[%d%.]+mm$") then
		return "mm"
	end

	if clean:match("^%-?[%d%.]+m$") then
		return "m"
	end

	if clean:match("^%-?[%d%.]+mi$") then
		return "mi"
	end

	if clean:match("^%-?[%d%.]+yd$") then
		return "yd"
	end

	if clean:match("^%-?[%d%.]+ft$") then
		return "ft"
	end

	if clean:match("^%-?[%d%.]+in$") then
		return "in"
	end

	-- ── Text encoding formats (original detection logic) ───────────

	if no_spaces:match("^0b[01]+") then
		return "bin"
	end

	if no_spaces:match("^[0-9,]+$") or no_spaces:match("^[0-9]+$") then
		return "dec"
	end

	if no_spaces:match("^0x[0-9a-fA-F]+") then
		return "hex"
	end

	if no_spaces:match("^[0-9a-fA-F]+$") and no_spaces:match("[a-fA-F]") then
		return "hex"
	end

	if no_spaces:match("^0o[0-7]+") then
		return "oct"
	end

	if
		#no_spaces >= 8
		and no_spaces:match("^[A-Za-z0-9+/]+=*$")
		and (no_spaces:match("[A-Z]") and no_spaces:match("[a-z]") or no_spaces:match("[+/]"))
	then
		return "b64"
	end

	if text:match("^[%s%.%-%/%|]+$") then
		if text:match("[%.-]") then
			return "morse"
		end
	end

	return "ascii"
end

return M
