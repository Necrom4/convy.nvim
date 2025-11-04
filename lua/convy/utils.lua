-- lua/convy/utils.lua
-- Utility functions for text manipulation and type detection

local M = {}

-- Check if currently in visual mode
function M.is_visual_mode()
	local mode = vim.fn.mode()
	return mode == "v" or mode == "V" or mode == "\22" -- \22 is <C-v>
end

-- Get visual selection
function M.get_visual_selection()
	-- Save and restore selection
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_line = start_pos[2]
	local start_col = start_pos[3]
	local end_line = end_pos[2]
	local end_col = end_pos[3]

	-- Get lines
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

-- Get word under cursor
function M.get_word_under_cursor()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = cursor[1]
	local col = cursor[2]

	local line_text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]

	-- Find word boundaries
	local start_col = col
	local end_col = col

	-- Move start_col to beginning of word
	while start_col > 0 do
		local char = line_text:sub(start_col, start_col)
		if char:match("[%s,;]") then
			break
		end
		start_col = start_col - 1
	end
	start_col = start_col + 1

	-- Move end_col to end of word
	while end_col <= #line_text do
		local char = line_text:sub(end_col + 1, end_col + 1)
		if char:match("[%s,;]") or char == "" then
			break
		end
		end_col = end_col + 1
	end

	local word = line_text:sub(start_col, end_col)

	return word, { line, start_col }, { line, end_col }
end

-- Replace text in buffer
function M.replace_text(start_pos, end_pos, new_text)
	local start_line, start_col = start_pos[1], start_pos[2]
	local end_line, end_col = end_pos[1], end_pos[2]

	-- Get current line(s)
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

-- Auto-detect input type
function M.detect_type(text)
	-- Remove whitespace for detection
	local clean_text = text:gsub("%s", "")

	-- Check for hex (0x prefix or all hex digits)
	if clean_text:match("^0x[0-9a-fA-F]+") or (clean_text:match("^[0-9a-fA-F]+$") and clean_text:match("[a-fA-F]")) then
		return "hex"
	end

	-- Check for binary (0b prefix or all binary digits)
	if clean_text:match("^0b[01]+") or clean_text:match("^[01]+$") then
		return "bin"
	end

	-- Check for octal (0o prefix)
	if clean_text:match("^0o[0-7]+") then
		return "oct"
	end

	-- Check for base64 (ends with = or contains base64 chars)
	if clean_text:match("[A-Za-z0-9+/]+=*$") and #clean_text > 3 then
		return "base64"
	end

	-- Check for decimal numbers (space/comma separated numbers)
	if clean_text:match("^[0-9,]+$") then
		return "dec"
	end

	-- Default to ASCII if it contains non-numeric characters
	return "ascii"
end

return M
