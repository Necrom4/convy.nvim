-- lua/convy/init.lua
-- Main module for convy.nvim

local M = {}
local converters = require("convy.converters")
local utils = require("convy.utils")

M.config = {
	-- Default configuration
	preserve_visual = true, -- Keep visual selection after conversion
	notification = true, -- Show notification after conversion
}

-- Setup function for plugin configuration
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.config, opts)
end

-- Main conversion function
function M.convert(from_type, to_type, is_visual_range)
	-- Get the text to convert
	local text, start_pos, end_pos

	if is_visual_range then
		-- Visual selection
		text, start_pos, end_pos = utils.get_visual_selection()
	else
		-- Word under cursor
		text, start_pos, end_pos = utils.get_word_under_cursor()
	end

	if not text or text == "" then
		vim.notify("No text to convert", vim.log.levels.WARN)
		return
	end

	-- Auto-detect input type if "auto"
	if from_type == "auto" then
		from_type = utils.detect_type(text)
		if M.config.notification then
			vim.notify(string.format("Detected type: %s", from_type), vim.log.levels.INFO)
		end
	end

	-- Convert the text
	local success, result = pcall(converters.convert, text, from_type, to_type)

	if not success then
		vim.notify(string.format("Conversion failed: %s", result), vim.log.levels.ERROR)
		return
	end

	-- Replace the text in buffer
	utils.replace_text(start_pos, end_pos, result)

	if M.config.notification then
		vim.notify(string.format("Converted from %s to %s", from_type, to_type), vim.log.levels.INFO)
	end
end

-- Convenience functions for specific conversions
function M.to_hex(text)
	if not text then
		text = utils.get_word_under_cursor()
	end
	local from_type = utils.detect_type(text)
	return converters.convert(text, from_type, "hex")
end

function M.to_dec(text)
	if not text then
		text = utils.get_word_under_cursor()
	end
	local from_type = utils.detect_type(text)
	return converters.convert(text, from_type, "dec")
end

function M.to_bin(text)
	if not text then
		text = utils.get_word_under_cursor()
	end
	local from_type = utils.detect_type(text)
	return converters.convert(text, from_type, "bin")
end

function M.to_ascii(text)
	if not text then
		text = utils.get_word_under_cursor()
	end
	local from_type = utils.detect_type(text)
	return converters.convert(text, from_type, "ascii")
end

function M.to_base64(text)
	if not text then
		text = utils.get_word_under_cursor()
	end
	return converters.convert(text, "ascii", "base64")
end

function M.from_base64(text)
	if not text then
		text = utils.get_word_under_cursor()
	end
	return converters.convert(text, "base64", "ascii")
end

return M
