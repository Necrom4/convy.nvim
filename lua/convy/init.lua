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

-- Get ordered list of input types (auto first, then alphabetical)
function M.get_input_types()
	return { "auto", "ascii", "base64", "bin", "dec", "hex", "oct" }
end

-- Get ordered list of output types (alphabetical, no auto)
function M.get_output_types()
	return { "ascii", "base64", "bin", "dec", "hex", "oct" }
end

-- Main conversion function
function M.convert(from_type, to_type, use_visual)
	-- Get the text to convert based on use_visual flag
	local text, start_pos, end_pos

	if use_visual then
		-- Visual selection (from stored marks)
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
function M.show_selector(use_visual)
	local ui = require("convy.ui")

	-- Get input types for first step
	local input_types = M.get_input_types()

	ui.show_type_selector(input_types, function(from_type, to_type)
		if from_type and to_type then
			M.convert(from_type, to_type, use_visual)
		end
	end, function()
		-- This callback provides output types for step 2
		return M.get_output_types()
	end)
end

return M
