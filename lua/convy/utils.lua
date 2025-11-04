-- lua/convy/utils.lua
-- Utility functions for text manipulation and type detection

local M = {}

-- Get visual selection from marks
function M.get_visual_selection()
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
	local col = cursor[2] + 1 -- Convert to 1-indexed

	local line_text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]

	if not line_text or line_text == "" then
		return nil, nil, nil
	end

	-- Define word boundary characters (alphanumeric, underscore, and hex-related)
	local function is_word_char(char)
		return char:match("[%w_]") ~= nil or char == "x" or char == "b" or char == "o"
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
		-- Stop at brackets, spaces, or other delimiters
		if not is_word_char(prev_char) or prev_char:match("[%[%]%(%)%{%},;]") then
			break
		end
		start_col = start_col - 1
	end

	-- Find end of word
	local end_col = col
	while end_col <= #line_text do
		local next_char = line_text:sub(end_col + 1, end_col + 1)
		-- Stop at brackets, spaces, or other delimiters
		if next_char == "" or not is_word_char(next_char) or next_char:match("[%[%]%(%)%{%},;]") then
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

-- Auto-detect input type (improved to avoid false base64 detection)
function M.detect_type(text)
	-- Remove whitespace for detection
	local clean_text = text:gsub("%s", "")

	-- Check for hex (0x prefix or all hex digits with a-f)
	if clean_text:match("^0x[0-9a-fA-F]+") then
		return "hex"
	end

	-- Check for binary (0b prefix)
	if clean_text:match("^0b[01]+") then
		return "bin"
	end

	-- Check for octal (0o prefix)
	if clean_text:match("^0o[0-7]+") then
		return "oct"
	end

	-- Check for decimal numbers (space/comma separated numbers, or single number)
	if clean_text:match("^[0-9,]+$") or clean_text:match("^[0-9]+$") then
		return "dec"
	end

	-- Check if it's all hex digits (without 0x prefix)
	if clean_text:match("^[0-9a-fA-F]+$") and clean_text:match("[a-fA-F]") then
		return "hex"
	end

	-- Check for base64 - must be longer and have proper base64 characteristics
	-- Base64 should be mostly alphanumeric with + / and optional = padding
	if
		#clean_text >= 8
		and clean_text:match("^[A-Za-z0-9+/]+=*$")
		-- Should have a good mix of characters (not just one type)
		and (clean_text:match("[A-Z]") and clean_text:match("[a-z]") or clean_text:match("[+/]"))
	then
		return "base64"
	end

	-- Default to ASCII for anything else
	return "ascii"
end

return M
