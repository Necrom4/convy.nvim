local converters = require("convy.converters")
local formats = require("convy.formats")
local utils = require("convy.utils")
local M = {}

M.config = {
	notifications = true,
	separator = " ",
	css_base_font_size = 16,
	window = {
		blend = 25,
		border = "rounded",
		on_open = nil,
	},
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.get_input_formats()
	return formats.get_all_input_formats()
end

function M.get_output_formats(input_format)
	return formats.get_output_formats(input_format)
end


function M.convert(input_format, output_format, use_visual)
	local text, start_pos, end_pos

	if use_visual then
		text, start_pos, end_pos = utils.get_visual_selection()
	else
		text, start_pos, end_pos = utils.get_word_under_cursor()
	end

	if not text or text == "" then
		utils.notify("No text to convert", vim.log.levels.WARN)
		return
	end

	if input_format == "auto" then
		input_format = utils.detect_format(text)
	end

	if not formats.are_compatible(input_format, output_format) then
		local in_group = formats.get_group(input_format)
		local out_group = formats.get_group(output_format)
		local in_label = in_group and formats.groups[in_group].label or "unknown"
		local out_label = out_group and formats.groups[out_group].label or "unknown"
		utils.notify(
			string.format(
				"Cannot convert %s (%s) to %s (%s) — incompatible format groups",
				input_format,
				in_label,
				output_format,
				out_label
			),
			vim.log.levels.ERROR
		)
		return
	end

	local success, result = pcall(converters.convert, text, input_format, output_format)

	if not success then
		utils.notify(string.format("Conversion failed: %s", result), vim.log.levels.ERROR)
		return
	end

	utils.replace_text(start_pos, end_pos, result)

	utils.notify(
		string.format("Converted from %s to %s", input_format:upper(), output_format:upper()),
		vim.log.levels.INFO
	)
end

function M.show_selector(use_visual)
	local ui = require("convy.ui")

	-- Capture text before opening the float (float takes focus)
	local source_text
	if use_visual then
		source_text = utils.get_visual_selection()
	else
		source_text = utils.get_word_under_cursor()
	end

	ui.show_format_selector(function(input_format, output_format)
		if input_format and output_format then
			M.convert(input_format, output_format, use_visual)
		end
	end, source_text)
end

return M
