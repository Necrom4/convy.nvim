local converters = require("convy.converters")
local formats = require("convy.formats")
local utils = require("convy.utils")
local M = {}

M.config = {
	notifications = true,
	separator = " ",
	css_base_font_size = 16,
	window = {
		position = "left",
		width = 36,
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


-- Capture the source text and its position from the current window.
local function capture_origin(use_visual)
	local text, start_pos, end_pos
	if use_visual then
		text, start_pos, end_pos = utils.get_visual_selection()
	else
		text, start_pos, end_pos = utils.get_word_under_cursor()
	end

	return {
		win = vim.api.nvim_get_current_win(),
		buf = vim.api.nvim_get_current_buf(),
		text = text,
		start_pos = start_pos,
		end_pos = end_pos,
	}
end

-- Convert `text` and write the result back at the captured origin position.
-- `input_format` may be "auto" to detect from the text. `value` overrides the
-- captured text when the user edited the input in the selector.
function M.convert_origin(origin, input_format, output_format, value)
	local text = value or origin.text
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
		local in_label = in_group and formats.label(in_group) or "unknown"
		local out_label = out_group and formats.label(out_group) or "unknown"
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

	vim.api.nvim_win_call(origin.win, function()
		utils.replace_text(origin.start_pos, origin.end_pos, result)
	end)

	utils.notify(
		string.format("Converted from %s to %s", formats.display(input_format), formats.display(output_format)),
		vim.log.levels.INFO
	)
end

function M.convert(input_format, output_format, use_visual)
	M.convert_origin(capture_origin(use_visual), input_format, output_format)
end

function M.show_selector(use_visual)
	local origin = capture_origin(use_visual)
	require("convy.ui").open(origin, function(input_format, output_format, value)
		M.convert_origin(origin, input_format, output_format, value)
	end)
end

return M
