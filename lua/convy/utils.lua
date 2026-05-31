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

	-- ── Unit formats (case-insensitive suffix match) ──────────────
	local unit_suffixes = {
		-- Temperature (strip an optional ° before the letter)
		{ suffix = "K", format = "kelvin", degree = true },
		{ suffix = "F", format = "fahrenheit", degree = true },
		{ suffix = "C", format = "celsius", degree = true },
		-- Angle
		{ suffix = "turn", format = "turn" },
		{ suffix = "grad", format = "grad" },
		{ suffix = "rad", format = "rad" },
		{ suffix = "deg", format = "deg" },
		-- Time
		{ suffix = "ms", format = "ms" },
		{ suffix = "min", format = "min" },
		{ suffix = "h", format = "h" },
		{ suffix = "s", format = "s" },
		-- Data size
		{ suffix = "TB", format = "TB" },
		{ suffix = "GB", format = "GB" },
		{ suffix = "MB", format = "MB" },
		{ suffix = "KB", format = "KB" },
		{ suffix = "B", format = "B" },
		-- Length
		{ suffix = "px", format = "px" },
		{ suffix = "rem", format = "rem" },
		{ suffix = "pt", format = "pt" },
		{ suffix = "km", format = "km" },
		{ suffix = "cm", format = "cm" },
		{ suffix = "mm", format = "mm" },
		{ suffix = "m", format = "m" },
		{ suffix = "mi", format = "mi" },
		{ suffix = "yd", format = "yd" },
		{ suffix = "ft", format = "ft" },
		{ suffix = "in", format = "in" },
	}

	local function ends_with_ci(str, suffix)
		return #str >= #suffix and str:sub(-#suffix):lower() == suffix:lower()
	end

	for _, unit in ipairs(unit_suffixes) do
		local candidate = clean
		if unit.degree then
			candidate = candidate:gsub("°", "")
		end

		if ends_with_ci(candidate, unit.suffix) then
			local number = candidate:sub(1, #candidate - #unit.suffix)
			-- The remaining prefix must be a bare (optionally negative) number.
			if number:match("^%-?[%d%.]+$") then
				return unit.format
			end
		end
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
