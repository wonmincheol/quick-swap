local M = {}
  local groups = require("scripts.groups")
  local gui = require("scripts.gui")
  local unlocks = require("scripts.unlocks")
  local swap = require("scripts.cursor_swap")
  local editor = require("tests.editor")
function M.run(player)
  local checks = 0
  local function check(value, text)
    assert(value, "QUICK SWAP: " .. text); checks = checks + 1
  end
  if not player.character then
    player.set_controller { type = defines.controllers.god }
    player.create_character()
  end
  local state = groups.get(player.index)
  check(#state.config.groups >= 3, "default groups")
  check(state.config.groups[1].cells[1] == "transport-belt", "default belt")
  check(groups.supported("assembling-machine-1"), "custom building supported")
  check(not groups.supported("blueprint"), "blueprint excluded")
  local allowed = unlocks.items(player.force)
  check(allowed["transport-belt"] and not allowed["express-transport-belt"], "research filter")
  local all = function() return true end
  check(groups.target(state.config, "transport-belt", "horizontal", 1, all) == "underground-belt", "horizontal")
  check(groups.target(state.config, "transport-belt", "horizontal", -1, all) == "splitter", "wrap across blanks")
  check(groups.target(state.config, "transport-belt", "vertical", 1, all) == "fast-transport-belt", "vertical")
  check(not groups.target(state.config, "transport-belt", "vertical", -1, all), "no vertical wrap")
  local custom = { enabled = true, groups = {
    { enabled = true, horizontal = false, vertical = false, rows = 3,
      cells = { [1] = "transport-belt", [4] = "pipe", [21] = "small-electric-pole" } },
    { enabled = true, horizontal = true, rows = 1, cells = { "transport-belt", "splitter" } }
  } }
  check(groups.target(custom, "transport-belt", "horizontal", 1, all) == "pipe", "skip blank")
  check(groups.target(custom, "transport-belt", "vertical", 1, all) == "small-electric-pole", "skip blank row")
  check(not groups.target(custom, "transport-belt", "horizontal", -1, all), "priority does not fall through")
  check(not groups.target(custom, "transport-belt", "horizontal", 1, function() return false end), "unusable skipped")
  custom.enabled = false
  check(not groups.target(custom, "transport-belt", "horizontal", 1, all), "master off")

  gui.ensure_button(player); gui.open(player)
  local root = player.gui.screen["quick-swap-window"]
  check(root ~= nil, "GUI created")
  local function element(action, parent)
    parent = parent or root
    for _, child in pairs(parent.children) do
      if child.tags.action == action then return child end
      local found = element(action, child); if found then return found end
    end
  end
  local function click(e) gui.click { player_index = player.index, element = e } end
  local function change(e) gui.changed { player_index = player.index, element = e } end
  local grid = root["quick-swap-body"]["quick-swap-group-1"]["quick-swap-slots"]
  check(grid.column_count == 10 and #grid.children == (state.draft.groups[1].rows + 1) * 10, "ten columns plus blank row")
  click(element("add"))
  check(#state.draft.groups == #state.config.groups + 1, "add draft only")
  local g = state.draft.groups[#state.draft.groups]
  local box = root["quick-swap-body"]["quick-swap-group-" .. g.id]
  local slot = box["quick-swap-slots"].children[10]
  slot.elem_value = "transport-belt"; change(slot)
  check(g.rows == 1 and #box["quick-swap-slots"].children == 20, "automatic row expansion")
  slot = box["quick-swap-slots"].children[11]
  slot.elem_value = "transport-belt"; change(slot)
  check(g.cells[11] == nil, "reject same-group duplicate")
  slot.elem_value = "express-transport-belt"; change(slot)
  check(g.cells[11] == nil, "reject locked item")
  slot = box["quick-swap-slots"].children[10]
  slot.elem_value = nil; change(slot)
  check(g.rows == 0 and #box["quick-swap-slots"].children == 10, "clear trailing row")
  g.cells[11] = "quick-swap-removed-item"; groups.trim(g); gui.refresh(player)
  box = root["quick-swap-body"]["quick-swap-group-" .. g.id]
  slot = box["quick-swap-slots"].children[11]
  check(slot.elem_value == nil and g.rows == 2, "missing item retained")
  gui.click { player_index = player.index, element = slot, button = defines.mouse_button_type.right }
  check(g.cells[11] == nil and g.rows == 0, "right-click clears missing item")
  click(element("apply"))
  check(not gui.is_open(player) and #state.config.groups == 4, "apply")
  gui.open(player); root = player.gui.screen["quick-swap-window"]
  click(element("add")); gui.request_close(player)
  check(gui.is_open(player) and state.pending.action == "discard", "dirty close confirmation")
  click(element("confirm"))
  check(not gui.is_open(player) and #state.config.groups == 4, "discard")
  gui.open(player); root = player.gui.screen["quick-swap-window"]
  local last = root["quick-swap-body"]["quick-swap-group-4"]
  click(element("rename", last))
  root["quick-swap-prompt"]["quick-swap-name"].text = "My buildings"
  click(element("confirm"))
  check(state.draft.groups[4].title == "My buildings", "rename")
  last = root["quick-swap-body"]["quick-swap-group-4"]
  click(element("delete", last)); click(element("confirm"))
  check(#state.draft.groups == 3 and #state.config.groups == 4, "delete draft")
  click(element("cancel"))
  check(#state.config.groups == 4, "cancel deletion")
  local second = groups.get(999)
  second.config.enabled = false
  check(state.config.enabled, "personal settings isolated")
  editor.run(player, check)

  local inventory = player.get_main_inventory()
  inventory.clear(); player.cursor_stack.set_stack { name = "transport-belt", count = 50 }
  inventory.insert { name = "pipe", count = 23 }
  local candidate = { name = "pipe", item_prototype = prototypes.item.pipe }
  check(swap.swap_from_inventory(player, candidate), "inventory swap")
  check(player.cursor_stack.name == "pipe" and player.cursor_stack.count == 23
    and inventory.get_item_count("transport-belt") == 50, "counts preserved")
  inventory.clear(); player.cursor_stack.set_stack { name = "transport-belt", count = 50 }
  for i = 1, #inventory do inventory[i].set_stack { name = "stone", count = prototypes.item.stone.stack_size } end
  inventory[1].set_stack { name = "pipe", count = 100 }
  inventory[2].set_stack { name = "transport-belt", count = 95 }
  check(not swap.swap_from_inventory(player, candidate), "full inventory failure")
  check(inventory.get_item_count("transport-belt") == 95 and inventory.get_item_count("pipe") == 100
    and player.cursor_stack.count == 50, "partial insert rollback exact")
  if prototypes.quality.legendary then
    inventory.clear(); inventory.insert { name = "pipe", count = 7, quality = "legendary" }
    inventory.insert { name = "pipe", count = 20 }
    check(swap.swap_from_inventory(player, candidate) and player.cursor_stack.quality.name == "legendary"
      and player.cursor_stack.count == 7, "highest quality and available count")
  end
  inventory.clear()
  player.cursor_stack.set_stack { name = "transport-belt", count = 5 }
  inventory.insert { name = "underground-belt", count = 5 }
  player.force.recipes["underground-belt"].enabled = true; unlocks.invalidate()
  local input = script.get_event_handler("quick-swap-cycle-kind-next")
  input { player_index = player.index, tick = game.tick }
  check(player.cursor_stack.name == "underground-belt", "input handler connected")
  check(storage.quick_swap_zoom_locks[player.index] ~= nil, "successful input locks zoom")
  script.get_event_handler(defines.events.on_tick) { tick = game.tick + 1 }
  check(storage.quick_swap_zoom_locks[player.index] == nil, "zoom restored next tick")
  gui.open(player)
  input { player_index = player.index, tick = game.tick }
  check(player.cursor_stack.name == "underground-belt" and not storage.quick_swap_zoom_locks[player.index], "editor blocks swap")
  gui.close(player)
  player.set_controller { type = defines.controllers.remote }
  player.cursor_ghost = { name = "transport-belt", quality = "normal" }
  check(swap.swap_in_remote_view(player, candidate), "remote cursor swap")
  check(player.cursor_ghost.name.name == "pipe", "remote result")
  if prototypes.quality.legendary then
    player.cursor_ghost = { name = "transport-belt", quality = "legendary" }
    check(swap.swap_in_remote_view(player, candidate) and player.cursor_ghost.quality.name == "legendary", "remote quality preserved")
  end
  player.force.research_all_technologies()
  unlocks.invalidate()
  check(unlocks.items(player.force)["express-transport-belt"], "research refresh")
  state.config = storage.quick_swap_editor_expected
  state.config.groups[4] = nil
  gui.open(player)
  log("QUICK_SWAP_TESTS_PASSED " .. checks)
end
return M
