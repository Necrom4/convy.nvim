local M = {}

local formats = require("convy.formats")
local converters = require("convy.converters")
local utils = require("convy.utils")

local ns = vim.api.nvim_create_namespace("convy")

local HEADER_LINES = 3 -- blank, title, divider
local FOOTER_LINES = 5 -- divider, input, output, blank, help

local function setup_highlights()
	local defs = {
		ConvyTitle = { fg = "Cyan", bold = true },
		ConvyAuto = { link = "Identifier" },
		ConvyGroup = { link = "Title" },
		ConvyUnit = { link = "Normal" },
		ConvyDim = { link = "Comment" },
		ConvyStrong = { link = "String" },
		ConvyHover = { link = "String" },
		ConvyLabel = { link = "Comment" },
		ConvyPick = { underline = true },
	}
	for name, def in pairs(defs) do
		if vim.fn.hlexists(name) == 0 then
			def.default = true
			vim.api.nvim_set_hl(0, name, def)
		end
	end
end

local function divider(width)
	return "  " .. string.rep("─", math.max(0, width - 4))
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

-- Returns the input and output result lines as { unit, value } pairs (or nil).
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
	local in_line = { unit = formats.display(detected), value = value }

	if not state.input_fixed or not state.hover_output then
		return in_line, nil
	end

	local ok, result = pcall(converters.convert, value, detected, state.hover_output)
	if not ok then
		return in_line, nil
	end
	return in_line, { unit = formats.display(state.hover_output), value = result }
end

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

local function tree_height(state)
	local h = vim.api.nvim_win_get_height(state.win)
	return math.max(1, h - HEADER_LINES - FOOTER_LINES)
end

-- Index (into state.rows) of the currently selected tree row.
local function selected_index(state)
	local line = vim.api.nvim_win_get_cursor(state.win)[1]
	return state.line_map[line]
end

local function current_row(state)
	local idx = selected_index(state)
	return idx and state.rows[idx]
end

local function render(state)
	setup_highlights()
	local width = state.width
	local vh = tree_height(state)
	local lines, hls = {}, {}
	state.line_map = {}

	-- Header
	local title = "convy.nvim"
	local pad = math.max(0, math.floor((width - #title) / 2))
	table.insert(lines, "")
	table.insert(lines, string.rep(" ", pad) .. title)
	table.insert(hls, { line = 1, s = pad, e = pad + #title, hl = "ConvyTitle" })
	table.insert(lines, divider(width))

	-- Tree viewport: rows[scroll .. scroll + vh - 1]
	local agroup = active_group(state)
	local total = #state.rows
	state.scroll = math.max(1, math.min(state.scroll, math.max(1, total - vh + 1)))

	for i = 0, vh - 1 do
		local idx = state.scroll + i
		local row = state.rows[idx]
		local buf_line = HEADER_LINES + i + 1
		local text, hl = "", nil
		if row then
			if row.kind == "auto" then
				text, hl = "  auto", "ConvyAuto"
			elseif row.kind == "group" then
				local arrow = state.expanded[row.key] and "▾" or "▸"
				text, hl = string.format("  %s %s", arrow, row.label), "ConvyGroup"
			elseif row.kind == "unit" then
				text = "      " .. formats.display(row.name)
				hl = (agroup ~= nil and row.group ~= agroup) and "ConvyDim" or "ConvyUnit"
			end
			state.line_map[buf_line] = idx
			if idx == state.selected then
				hl = "ConvyHover"
			end
		end
		table.insert(lines, text)
		if hl then
			table.insert(hls, { line = buf_line - 1, s = 0, e = -1, hl = hl })
		end
	end

	-- Footer
	table.insert(lines, divider(width))
	local in_res, out_res = compute_preview(state)
	local function add_result(res, picking)
		local unit = res and res.unit or "..."
		local value = res and res.value or "..."
		table.insert(lines, string.format("  %s: %s", unit, value))
		local l = #lines - 1
		if res then
			table.insert(hls, { line = l, s = 2, e = 2 + #unit, hl = "ConvyStrong" })
		else
			table.insert(hls, { line = l, s = 2, e = -1, hl = "ConvyDim" })
		end
		if picking then
			table.insert(hls, { line = l, s = 2, e = 2 + #unit, hl = "ConvyPick" })
		end
	end
	add_result(in_res, not state.input_fixed)
	add_result(out_res, state.input_fixed)
	table.insert(lines, "")
	table.insert(lines, "  / search  i input  ⏎ select")
	table.insert(hls, { line = #lines - 1, s = 0, e = -1, hl = "ConvyLabel" })

	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = false

	vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
	for _, h in ipairs(hls) do
		vim.api.nvim_buf_add_highlight(state.buf, ns, h.hl, h.line, h.s, h.e)
	end
end

-- Place the cursor on the buffer line showing tree index `idx`, scrolling
-- the viewport if needed so the selection stays visible.
local function focus_index(state, idx)
	local total = #state.rows
	idx = math.max(1, math.min(idx, total))
	state.selected = idx

	local vh = tree_height(state)
	if idx < state.scroll then
		state.scroll = idx
	elseif idx > state.scroll + vh - 1 then
		state.scroll = idx - vh + 1
	end

	render(state)
	local line = HEADER_LINES + (idx - state.scroll) + 1
	pcall(vim.api.nvim_win_set_cursor, state.win, { line, 0 })
end

local function update_hover(state)
	local row = state.rows[state.selected]
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

local function move(state, delta)
	local total = #state.rows
	local idx = state.selected + delta
	while idx >= 1 and idx <= total do
		if is_tree_row(state.rows[idx]) then
			focus_index(state, idx)
			update_hover(state)
			return
		end
		idx = idx + delta
	end
end

local function move_group(state, delta)
	local total = #state.rows
	local idx = state.selected + delta
	while idx >= 1 and idx <= total do
		if state.rows[idx].kind == "group" then
			focus_index(state, idx)
			update_hover(state)
			return
		end
		idx = idx + delta
	end
end

-- Re-select the row matching `keep` (by identity) after a rebuild.
local function refresh(state, keep)
	state.rows = build_rows(state)
	local idx = 1
	if keep then
		for i, r in ipairs(state.rows) do
			if r == keep then
				idx = i
				break
			end
		end
	else
		idx = math.min(state.selected or 1, #state.rows)
	end
	focus_index(state, idx)
	update_hover(state)
end

local function open_or_select(state)
	local row = current_row(state)
	if row and row.kind == "group" then
		if not state.expanded[row.key] then
			state.expanded[row.key] = true
			refresh(state, row)
		end
		return
	end
	M.select(state)
end

local function toggle_group(state)
	local row = current_row(state)
	if row and row.kind == "group" then
		state.expanded[row.key] = not state.expanded[row.key]
		refresh(state, row)
		return true
	end
	return false
end

local function toggle_all(state)
	local any_open = false
	for _, v in pairs(state.expanded) do
		any_open = any_open or v
	end
	for _, group in ipairs(formats.groups) do
		state.expanded[group.key] = not any_open
	end
	local keep = current_row(state)
	if keep and keep.kind == "unit" then
		keep = nil
	end
	refresh(state, keep)
end

local function select_or_toggle(state)
	if toggle_group(state) then
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
		state.expanded[row.group] = false
		local rows = build_rows(state)
		local keep
		for _, r in ipairs(rows) do
			if r.kind == "group" and r.key == row.group then
				keep = r
				break
			end
		end
		refresh(state, keep)
	elseif row.kind == "group" and state.expanded[row.key] then
		state.expanded[row.key] = false
		refresh(state, row)
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
		state.on_confirm(state.input_format, out, state.input_value)
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

	map("j", function(s) move(s, 1) end)
	map("k", function(s) move(s, -1) end)
	map("<Down>", function(s) move(s, 1) end)
	map("<Up>", function(s) move(s, -1) end)
	map("l", open_or_select)
	map("<Right>", open_or_select)
	map("h", close_or_collapse)
	map("<Left>", close_or_collapse)
	map("za", toggle_all)
	map("<Tab>", function(s) move_group(s, 1) end)
	map("<S-Tab>", function(s) move_group(s, -1) end)
	map("<Space>", select_or_toggle)
	map("<CR>", select_or_toggle)
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
		rows = {},
		scroll = 1,
		selected = 1,
		input_fixed = false,
		input_format = nil,
		input_value = origin.text,
		hover_format = "auto",
		hover_output = nil,
		on_confirm = on_confirm,
	}

	state.rows = build_rows(state)
	focus_index(state, 1)
	update_hover(state)
	setup_keymaps(state)

	-- Keep the cursor inside the tree region.
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = buf,
		callback = function()
			local line = vim.api.nvim_win_get_cursor(win)[1]
			if not state.line_map[line] then
				focus_index(state, state.selected)
			elseif state.line_map[line] ~= state.selected then
				state.selected = state.line_map[line]
				update_hover(state)
			end
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
