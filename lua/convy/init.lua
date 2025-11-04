-- lua/convy/init.lua
-- Main module for convy.nvim

local M = {}
local converters = require("convy.converters")
local utils = require("convy.utils")

M.config = {
	-- Default configuration
	notification = true, -- Show notification after conversion
}

-- Setup function for plugin configuration
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.config, opts)
end

-- Main conversion function
function M.convert(from_type, to_type)
	-- Check if we're in visual mode
	local is_visual = utils.is_visual_mode()

	-- Get the text to convert
	local text, start_pos, end_pos

	if is_visual then
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

-- Show interactive selector for conversion types
function M.show_selector()
	local types = { "dec", "hex", "bin", "oct", "ascii", "base64", "auto" }
	local ui = require("convy.ui")

	ui.show_type_selector(types, function(from_type, to_type)
		if from_type and to_type then
			M.convert(from_type, to_type)
		end
	end)
end

return M
