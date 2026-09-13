local groups = require("scripts.groups")
local unlocks = require("scripts.unlocks")
local M = {}
local root_name = "quick-swap-window"
local function loc(key) return { "quick-swap." .. key } end
local function add(parent, kind, action, args)
  args = args or {}; args.type = kind
  args.name = "quick-swap-" .. action
  args.tags = args.tags or {}; args.tags.action = args.tags.action or action
  return parent.add(args)
end
local function stretch(parent, action)
  local e = add(parent, "empty-widget", action)
  e.style.horizontally_stretchable = true
  return e
end
function M.ensure_button(player)
  if not player.gui.top["quick-swap-open"] then
    add(player.gui.top, "button", "open", { caption = "Quick Swap", tooltip = loc("open") })
  end
end

function M.is_open(player) return player.gui.screen[root_name] ~= nil end

local function render_slots(player, group, table_element)
  table_element.clear()
  local allowed, filters = unlocks.items(player.force), unlocks.filters(player.force)
  for slot = 1, (group.rows + 1) * 10 do
    local name = group.cells[slot]
    local exists = name and prototypes.item[name]
    local button = add(table_element, "choose-elem-button", "slot-" .. slot, {
      elem_type = "item", item = exists and name or nil, elem_filters = filters,
      tags = { action = "slot", group = group.id, slot = slot },
      tooltip = name and { "", exists and prototypes.item[name].localised_name or name,
        "\n", allowed[name] and loc("slot-help") or loc("locked") } or loc("slot-help")
    })
    button.style.width = 40; button.style.height = 40
    if name and (not exists or not allowed[name]) then
      local overlay = button.add { type = "sprite", name = "quick-swap-lock",
        sprite = "utility/crafting_machine_recipe_not_unlocked", ignored_by_interaction = true }
      overlay.style.width = 16; overlay.style.height = 16
    end
  end
end

local function section(player, parent, group, index, total)
  local box = add(parent, "flow", "group-" .. group.id, { direction = "vertical" })
  box.style.vertical_spacing = 0
  local header = add(box, "frame", "header", { style = "logistic_section_subheader_frame", direction = "horizontal" })
  header.style.width = 400; header.style.padding = 4
  add(header, "checkbox", "enabled", { state = group.enabled, caption = "", tags = { action = "enabled", group = group.id } })
  local title = add(header, "label", "title", { caption = group.title })
  title.style.maximal_width = 88
  title.tooltip = group.title
  add(header, "sprite-button", "rename", { sprite = "utility/rename_icon", style = "mini_button_aligned_to_text_vertically",
    tooltip = loc("rename"), tags = { action = "rename", group = group.id } })
  for _, option in ipairs({ { "up", "↑", index > 1 }, { "down", "↓", index < total } }) do
    local button = add(header, "button", option[1], { caption = option[2], enabled = option[3],
      style = "mini_button_aligned_to_text_vertically", tooltip = loc("group-" .. option[1]),
      tags = { action = option[1], group = group.id } })
    button.style.width = 20
  end
  stretch(header, "space")
  add(header, "checkbox", "horizontal", { state = group.horizontal, caption = loc("horizontal"),
    tooltip = loc("wrap-help"), tags = { action = "horizontal", group = group.id } })
  add(header, "checkbox", "vertical", { state = group.vertical, caption = loc("vertical"),
    tooltip = loc("wrap-help"), tags = { action = "vertical", group = group.id } })
  add(header, "sprite-button", "delete", { sprite = "utility/trash", style = "mini_tool_button_red",
    tooltip = loc("delete"), tags = { action = "delete", group = group.id } })
  local grid = add(box, "table", "slots", { column_count = 10 })
  grid.style.horizontal_spacing = 0; grid.style.vertical_spacing = 0
  render_slots(player, group, grid)
end

local function render_body(player)
  local window = player.gui.screen[root_name]
  local body = window["quick-swap-body"]
  body.clear()
  local draft = groups.get(player.index).draft
  for index, group in ipairs(draft.groups) do section(player, body, group, index, #draft.groups) end
  local button = add(body, "button", "add", { caption = loc("add"), style = "add_logistic_section_button" })
  button.style.width = 400; button.style.height = 28
end

function M.close(player)
  local window = player.gui.screen[root_name]
  if window then window.destroy() end
  local state = groups.get(player.index)
  state.draft = nil; state.dirty = nil; state.pending = nil
  -- Discard obsolete transient state from the removed position editor.
  state.move_mode = nil; state.move_source = nil
end

function M.open(player)
  if M.is_open(player) then return end
  local state = groups.get(player.index)
  state.draft = groups.copy(state.config); state.dirty = false
  local window = player.gui.screen.add { type = "frame", name = root_name, direction = "vertical" }
  local titlebar = add(window, "flow", "titlebar", { direction = "horizontal" })
  add(titlebar, "label", "title", { caption = "Quick Swap", style = "frame_title" })
  local drag = stretch(titlebar, "drag"); drag.style = "draggable_space_header"
  drag.style.horizontally_stretchable = true; drag.style.height = 24; drag.drag_target = window
  add(titlebar, "sprite-button", "close", { sprite = "utility/close", style = "frame_action_button" })
  add(window, "checkbox", "master", { state = state.draft.enabled, caption = loc("master") })
  local body = add(window, "scroll-pane", "body", { direction = "vertical",
    horizontal_scroll_policy = "never", vertical_scroll_policy = "auto" })
  body.style.width = 424
  body.style.height = math.max(120, math.min(540, player.display_resolution.height / player.display_scale - 280))
  local help = add(window, "label", "help", { caption = loc("slot-help") })
  help.style.maximal_width = 410; help.style.single_line = false
  for _, axis in ipairs({ "horizontal", "vertical" }) do
    local keys = add(window, "label", "keys-" .. axis, { caption = loc("keys-" .. axis) })
    keys.style.maximal_width = 410; keys.style.single_line = false
  end
  add(window, "label", "size", { caption = loc("size") })
  local message = add(window, "label", "message", { caption = "" })
  message.style.maximal_width = 410; message.style.single_line = false
  local prompt = add(window, "flow", "prompt", { direction = "horizontal", visible = false })
  add(prompt, "textfield", "name", { text = "" })
  add(prompt, "button", "confirm", { caption = loc("confirm") })
  add(prompt, "button", "dismiss", { caption = loc("cancel") })
  local footer = add(window, "flow", "footer", { direction = "horizontal" })
  stretch(footer, "space")
  add(footer, "button", "cancel", { caption = loc("cancel") })
  add(footer, "button", "apply", { caption = loc("apply"), style = "confirm_button" })
  render_body(player)
  window.force_auto_center(); player.opened = window
end

local function message(player, key)
  player.gui.screen[root_name]["quick-swap-message"].caption = key and loc(key) or ""
end

local function prompt(player, action, id)
  local state = groups.get(player.index)
  state.pending = { action = action, group = id }
  local row = player.gui.screen[root_name]["quick-swap-prompt"]
  row.visible = true
  local field = row["quick-swap-name"]
  field.visible = action == "rename"
  if action == "rename" then
    local g = groups.find(state.draft, id)
    field.text = type(g.title) == "string" and g.title or ""
    field.focus(); field.select_all()
  end
  message(player, action == "rename" and "rename" or action == "delete" and "confirm-delete" or "confirm-discard")
end

function M.request_close(player)
  if not M.is_open(player) then return end
  if groups.get(player.index).dirty then prompt(player, "discard")
  else M.close(player) end
end

function M.click(event)
  local e = event.element
  if not e or not e.valid or not e.name:find("^quick%-swap%-") then return end
  local player = game.get_player(event.player_index)
  local action = e.tags.action
  if action == "open" then
    if M.is_open(player) then M.request_close(player) else M.open(player) end
    return
  end
  if not M.is_open(player) then return end
  local state = groups.get(player.index)
  if action == "up" or action == "down" then
    local from, to = groups.reorder(state.draft, e.tags.group, action == "up" and -1 or 1)
    if from then
      local body = player.gui.screen[root_name]["quick-swap-body"]
      body.swap_children(from, to)
      for index, group in ipairs(state.draft.groups) do
        local header = body["quick-swap-group-" .. group.id]["quick-swap-header"]
        header["quick-swap-up"].enabled = index > 1
        header["quick-swap-down"].enabled = index < #state.draft.groups
      end
      state.dirty = true
      message(player, "order-help")
    end
  elseif action == "slot" and event.button == defines.mouse_button_type.right then
    local g = groups.find(state.draft, e.tags.group)
    if g and g.cells[e.tags.slot] then
      g.cells[e.tags.slot] = nil; groups.trim(g); state.dirty = true
      render_slots(player, g, e.parent); message(player)
    end
  elseif action == "close" then M.request_close(player)
  elseif action == "cancel" then M.close(player)
  elseif action == "apply" then
    if groups.validate(state.draft) then state.config = state.draft; M.close(player)
    else message(player, "invalid") end
  elseif action == "add" then
    local d = state.draft
    d.groups[#d.groups + 1] = { id = d.next_id, title = { "quick-swap.new-group", d.next_id },
      enabled = true, horizontal = false, vertical = false, cells = {}, rows = 0 }
    d.next_id = d.next_id + 1; state.dirty = true; render_body(player)
    player.gui.screen[root_name]["quick-swap-body"].scroll_to_bottom()
  elseif action == "rename" or action == "delete" then prompt(player, action, e.tags.group)
  elseif action == "dismiss" then
    state.pending = nil; player.gui.screen[root_name]["quick-swap-prompt"].visible = false; message(player)
  elseif action == "confirm" and state.pending then
    local p = state.pending
    if p.action == "discard" then M.close(player); return end
    local g, index = groups.find(state.draft, p.group)
    if g then
      if p.action == "delete" then
        table.remove(state.draft.groups, index)
      else
        local text = player.gui.screen[root_name]["quick-swap-prompt"]["quick-swap-name"].text
        text = text:match("^%s*(.-)%s*$")
        if text == "" then message(player, "name-required"); return end
        g.title = text
      end
      state.dirty = true; render_body(player)
    end
    state.pending = nil; player.gui.screen[root_name]["quick-swap-prompt"].visible = false; message(player)
  end
end

function M.changed(event)
  local e = event.element
  if not e or not e.valid or not e.name:find("^quick%-swap%-") then return end
  local player = game.get_player(event.player_index)
  if not M.is_open(player) then return end
  local state, tags = groups.get(player.index), e.tags
  if tags.action == "master" then state.draft.enabled = e.state; state.dirty = true; return end
  local g = groups.find(state.draft, tags.group)
  if not g then return end
  if tags.action == "slot" then
    local name = e.elem_value
    if name and (not groups.supported(name) or not unlocks.items(player.force)[name]) then
      e.elem_value = prototypes.item[g.cells[tags.slot] or ""] and g.cells[tags.slot] or nil
      message(player, "unavailable"); return
    end
    for slot, other in pairs(g.cells) do
      if name and other == name and slot ~= tags.slot then
        e.elem_value = prototypes.item[g.cells[tags.slot] or ""] and g.cells[tags.slot] or nil
        message(player, "duplicate"); return
      end
    end
    g.cells[tags.slot] = name; groups.trim(g); state.dirty = true
    local duplicate = false
    for _, other in ipairs(state.draft.groups) do
      if other.id ~= g.id then
        for _, value in pairs(other.cells) do if name and value == name then duplicate = true end end
      end
    end
    render_slots(player, g, e.parent)
    message(player, duplicate and "priority" or nil)
  elseif tags.action == "enabled" or tags.action == "horizontal" or tags.action == "vertical" then
    g[tags.action] = e.state; state.dirty = true
  end
end

function M.refresh(player)
  if M.is_open(player) then render_body(player) end
end

return M
