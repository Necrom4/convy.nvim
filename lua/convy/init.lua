local converters = require("convy.converters")
local utils = require("convy.utils")
local M = {}

M.config = {
	notifications = true,
	separator = " ",
	window = {
		blend = 25,
	},
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.get_input_formats()
	return { "auto", "ascii", "bin", "dec", "hex", "oct", "base64" }
end

function M.get_output_formats()
	return { "ascii", "bin", "dec", "hex", "oct", "base64" }
end

-- Main conversion function
function M.convert(input_format, output_format, use_visual)
	local text, start_pos, end_pos

	if use_visual then
		text, start_pos, end_pos = utils.get_visual_selection()
	else
		text, start_pos, end_pos = utils.get_word_under_cursor()
	end

	if not text or text == "" then
		vim.notify("No text to convert", vim.log.levels.WARN)
		return
	end

	if input_format == "auto" then
		input_format = utils.detect_format(text)
	end

	-- Convert the text
	local success, result = pcall(converters.convert, text, input_format, output_format)

	if not success then
		vim.notify(string.format("Conversion failed: %s", result), vim.log.levels.ERROR)
		return
	end

	-- Replace the text in buffer
	utils.replace_text(start_pos, end_pos, result)

	if M.config.notifications then
		vim.notify(string.format("Converted from %s to %s", input_format, output_format), vim.log.levels.INFO)
	end
end

-- Show interactive selector for conversion formats
function M.show_selector(use_visual)
	local ui = require("convy.ui")

	local input_formats = M.get_input_formats()

	ui.show_format_selector(input_formats, function(input_format, output_format)
		if input_format and output_format then
			M.convert(input_format, output_format, use_visual)
		end
	end, function()
		return M.get_output_formats()
	end)
end

return M
