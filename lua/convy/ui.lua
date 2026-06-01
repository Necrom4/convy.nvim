local M = {}

local formats = require("convy.formats")
local converters = require("convy.converters")
local utils = require("convy.utils")

local ns = vim.api.nvim_create_namespace("convy")

local function setup_highlights()
	local defs = {
		ConvyAuto = { link = "Identifier" },
		ConvyGroup = { link = "Title" },
		ConvyUnit = { link = "Normal" },
		ConvyDim = { link = "Comment" },
		ConvyStrong = { link = "String" },
		ConvyHover = { link = "String" },
		ConvyLabel = { link = "Comment" },
	}
	for name, def in pairs(defs) do
		if vim.fn.hlexists(name) == 0 then
			def.default = true
			vim.api.nvim_set_hl(0, name, def)
		end
	end
end

-- Build the flat list of tree rows from the registry, applying expand state
-- and the search query. Groups stay visible when any of their units match.
local function build_rows(state)
	local rows = { { kind = "auto" } }
	local query = state.query:lower()

	for _, group in ipairs(formats.groups) do
		local units = {}
		for _, entry in ipairs(group.formats) do
			local label = formats.display(entry.name):lower()
			if query == "" or label:find(query, 1, true) then
				table.insert(units, entry)
			end
		end

		if query == "" or #units > 0 then
			table.insert(rows, { kind = "group", key = group.key, label = group.label })
			if state.expanded[group.key] then
				for _, entry in ipairs(units) do
					table.insert(rows, { kind = "unit", name = entry.name, group = group.key })
				end
			end
		end
	end

	return rows
end

-- Returns the input and output result lines as { unit, value } pairs.
local function compute_preview(state)
	local value = state.input_value
	if not value or value == "" then
		return nil, nil
	end

	local input = state.input_fixed and state.input_format or state.hover_format
	if not input then
		return nil, nil
	end

	local detected = input == "auto" and utils.detect_format(value) or input
	local number = value:match("^%s*(%-?[%d%.]+)") or value
	local in_line = { unit = formats.display(detected), value = number }

	if not state.input_fixed or not state.hover_output then
		return in_line, nil
	end

	local ok, result = pcall(converters.convert, value, detected, state.hover_output)
	if not ok then
		return in_line, nil
	end
	return in_line, { unit = formats.display(state.hover_output), value = result }
end

-- The group whose units stay active once an input is fixed.
local function active_group(state)
	if not state.input_fixed then
		return nil
	end
	local fmt = state.input_format == "auto" and utils.detect_format(state.input_value or "") or state.input_format
	return formats.get_group(fmt)
end

local function is_tree_row(row)
	return row and (row.kind == "auto" or row.kind == "group" or row.kind == "unit")
end

-- The cursor line is the source of truth for the current row.
local function current_row(state)
	local line = vim.api.nvim_win_get_cursor(state.win)[1]
	return state.line_map and state.line_map[line]
end

local function render(state)
	setup_highlights()
	local lines = {}
	local hls = {} -- { line, col_start, col_end, hl }
	state.line_map = {}

	local function add(text, row)
		table.insert(lines, text)
		state.line_map[#lines] = row
		return #lines - 1
	end

	-- Tree section
	local agroup = active_group(state)
	local cursor_line = vim.api.nvim_win_is_valid(state.win) and vim.api.nvim_win_get_cursor(state.win)[1]
	for _, row in ipairs(state.rows) do
		local hl
		if row.kind == "auto" then
			add("  auto", row)
			hl = "ConvyAuto"
		elseif row.kind == "group" then
			local arrow = state.expanded[row.key] and "▾" or "▸"
			add(string.format("  %s %s", arrow, row.label), row)
			hl = "ConvyGroup"
		elseif row.kind == "unit" then
			add("      " .. formats.display(row.name), row)
			local dim = agroup ~= nil and row.group ~= agroup
			hl = dim and "ConvyDim" or "ConvyUnit"
		end
		if #lines == cursor_line then
			hl = "ConvyHover"
		end
		table.insert(hls, { line = #lines - 1, col_start = 0, col_end = -1, hl = hl })
	end

	-- Result section: "<unit>: <value>", unit strong, value normal.
	add("  " .. string.rep("─", state.width - 4), nil)
	local in_res, out_res = compute_preview(state)
	local function add_result(res, row)
		local text = res and string.format("  %s: %s", res.unit, res.value) or "  "
		local l = add(text, row)
		if res then
			table.insert(hls, { line = l, col_start = 2, col_end = 2 + #res.unit, hl = "ConvyStrong" })
		end
	end
	add_result(in_res, { kind = "input" })
	add_result(out_res, nil)

	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = false

	vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
	for _, h in ipairs(hls) do
		vim.api.nvim_buf_add_highlight(state.buf, ns, h.hl, h.line, h.col_start, h.col_end)
	end
end

local function place_cursor(state, line)
	pcall(vim.api.nvim_win_set_cursor, state.win, { line, 0 })
end

-- Keep the cursor on a selectable tree row, snapping off dividers/sections.
local function clamp_cursor(state)
	local total = vim.api.nvim_buf_line_count(state.buf)
	local line = vim.api.nvim_win_get_cursor(state.win)[1]
	if is_tree_row(state.line_map[line]) then
		return
	end
	for off = 0, total do
		for _, l in ipairs({ line + off, line - off }) do
			if l >= 1 and l <= total and is_tree_row(state.line_map[l]) then
				place_cursor(state, l)
				return
			end
		end
	end
end

-- Buffer line (1-indexed) of a row, matched by identity.
local function line_of(state, row)
	for line, mapped in pairs(state.line_map) do
		if mapped == row then
			return line
		end
	end
end

-- Move the cursor to the next/previous selectable tree row.
local function move(state, delta)
	local total = vim.api.nvim_buf_line_count(state.buf)
	local line = vim.api.nvim_win_get_cursor(state.win)[1]
	local l = line + delta
	while l >= 1 and l <= total do
		if is_tree_row(state.line_map[l]) then
			place_cursor(state, l)
			return
		end
		l = l + delta
	end
end

-- Move the cursor to the next/previous group header row.
local function move_group(state, delta)
	local total = vim.api.nvim_buf_line_count(state.buf)
	local line = vim.api.nvim_win_get_cursor(state.win)[1]
	local l = line + delta
	while l >= 1 and l <= total do
		local row = state.line_map[l]
		if row and row.kind == "group" then
			place_cursor(state, l)
			return
		end
		l = l + delta
	end
end

-- Recompute the hovered unit/output from the row under the cursor.
local function update_hover(state)
	local row = current_row(state)
	if not row then
		return
	end
	if not state.input_fixed then
		if row.kind == "auto" then
			state.hover_format = "auto"
		elseif row.kind == "unit" then
			state.hover_format = row.name
		else
			state.hover_format = nil
		end
	elseif row.kind == "unit" then
		state.hover_output = row.name
	end
	render(state)
end

local function refresh(state, keep_row)
	state.rows = build_rows(state)
	render(state)
	if keep_row then
		local line = line_of(state, keep_row)
		if line then
			place_cursor(state, line)
		end
	end
	update_hover(state)
end

local function open_or_select(state)
	local row = current_row(state)
	if row and row.kind == "group" then
		if not state.expanded[row.key] then
			state.expanded[row.key] = true
			refresh(state, row)
		else
			M.select(state)
		end
		return
	end
	M.select(state)
end

local function close_or_collapse(state)
	local row = current_row(state)
	if not row then
		return
	end
	if row.kind == "unit" then
		local group_row
		state.expanded[row.group] = false
		state.rows = build_rows(state)
		for _, r in ipairs(state.rows) do
			if r.kind == "group" and r.key == row.group then
				group_row = r
				break
			end
		end
		refresh(state, group_row)
	elseif row.kind == "group" and state.expanded[row.key] then
		state.expanded[row.key] = false
		refresh(state, row)
	elseif state.input_fixed then
		M.back(state)
	end
end

function M.select(state)
	local row = current_row(state)
	if not row then
		return
	end

	if not state.input_fixed then
		if row.kind == "auto" then
			state.input_format = "auto"
		elseif row.kind == "unit" then
			state.input_format = row.name
		else
			return
		end
		state.input_fixed = true
		state.hover_output = nil
		render(state)
		return
	end

	if row.kind == "unit" then
		local input = state.input_format == "auto" and utils.detect_format(state.input_value or "")
			or state.input_format
		if not formats.are_compatible(input, row.name) then
			return
		end
		local out = row.name
		M.close(state)
		state.on_confirm(state.input_format, out)
	end
end

function M.back(state)
	if not state.input_fixed then
		return
	end
	state.input_fixed = false
	state.input_format = nil
	state.hover_output = nil
	render(state)
end

local function focus_search(state)
	vim.ui.input({ prompt = "Search: ", default = state.query }, function(input)
		if input ~= nil then
			state.query = input
			refresh(state)
		end
	end)
end

local function edit_input(state)
	vim.ui.input({ prompt = "Input value: ", default = state.input_value or "" }, function(input)
		if input ~= nil and input ~= "" then
			state.input_value = input
			render(state)
		end
	end)
end

function M.close(state)
	if vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end
end

local function setup_keymaps(state)
	local opts = { noremap = true, silent = true, buffer = state.buf }
	local function map(lhs, fn)
		vim.keymap.set("n", lhs, function()
			fn(state)
		end, opts)
	end

	local function step(delta)
		return function(s)
			move(s, delta)
			update_hover(s)
		end
	end
	map("j", step(1))
	map("k", step(-1))
	map("<Down>", step(1))
	map("<Up>", step(-1))
	map("l", open_or_select)
	map("<Right>", open_or_select)
	map("h", close_or_collapse)
	map("<Left>", close_or_collapse)
	map("<Tab>", function(s)
		move_group(s, 1)
		update_hover(s)
	end)
	map("<S-Tab>", function(s)
		move_group(s, -1)
		update_hover(s)
	end)
	map("<Space>", M.select)
	map("<CR>", M.select)
	map("/", focus_search)
	map("i", edit_input)
	map("<BS>", M.back)
	map("<Esc>", function(s)
		if s.input_fixed then
			M.back(s)
		else
			M.close(s)
		end
	end)
	map("q", M.close)
end

function M.open(origin, on_confirm)
	local cfg = require("convy").config.window
	local width = cfg.width or 36

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "convy"

	vim.cmd(cfg.position == "right" and "botright vsplit" or "topleft vsplit")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_win_set_width(win, width)
	vim.wo[win].winfixwidth = true
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].statuscolumn = ""
	vim.wo[win].cursorline = true
	vim.wo[win].wrap = false

	local expanded = {}
	for _, group in ipairs(formats.groups) do
		expanded[group.key] = true
	end

	local state = {
		buf = buf,
		win = win,
		width = width,
		query = "",
		expanded = expanded,
		input_fixed = false,
		input_format = nil,
		input_value = origin.text,
		hover_format = "auto",
		hover_output = nil,
		on_confirm = on_confirm,
	}

	refresh(state)
	setup_keymaps(state)

	-- Start on the "auto" row.
	for line, row in pairs(state.line_map) do
		if row and row.kind == "auto" then
			place_cursor(state, line)
			break
		end
	end

	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = buf,
		callback = function()
			clamp_cursor(state)
			update_hover(state)
		end,
	})

	local on_open = require("convy").config.window.on_open
	if type(on_open) == "function" then
		on_open(buf, win)
	end

	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		buffer = buf,
		once = true,
		callback = function()
			M.close(state)
		end,
	})
end

return M
