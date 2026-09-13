local groups = require("scripts.groups")
local gui = require("scripts.gui")
local M = {}

function M.run(player, check)
  local state = groups.get(player.index)
  local original = groups.copy(state.config)
  local config = { enabled = true, groups = {
    { id = 10, enabled = true, horizontal = false, rows = 1, cells = { "transport-belt", "pipe" } },
    { id = 20, enabled = true, horizontal = false, rows = 1, cells = { "transport-belt", "splitter" } }
  } }
  local all = function() return true end
  check(groups.target(config, "transport-belt", "horizontal", 1, all) == "pipe", "priority before reorder")
  check(groups.reorder(config, 20, -1) == 2, "reorder by stable group ID")
  check(groups.target(config, "transport-belt", "horizontal", 1, all) == "splitter", "reorder invalidates position index")
  check(not groups.reorder(config, 20, -1), "top reorder boundary")
  gui.open(player)
  local root = player.gui.screen["quick-swap-window"]
  local function click(e, button) gui.click { player_index = player.index, element = e, button = button or defines.mouse_button_type.left } end
  local function grid(id) return root["quick-swap-body"]["quick-swap-group-" .. id]["quick-swap-slots"] end
  local function header(id) return root["quick-swap-body"]["quick-swap-group-" .. id]["quick-swap-header"] end
  click(header(2)["quick-swap-up"])
  check(state.draft.groups[1].id == 2 and state.config.groups[1].id == 1, "reorder is draft only")
  check(root["quick-swap-body"].children[1].name == "quick-swap-group-2"
    and not header(2)["quick-swap-up"].enabled, "native children order and boundary buttons")
  click(header(2)["quick-swap-down"])
  check(state.draft.groups[1].id == 1, "reorder down")
  check(root["quick-swap-move-mode"] == nil and not grid(1).children[1].locked, "position mode removed and picker available")
  local slot = grid(1).children[1]
  click(slot)
  check(not state.move_source and state.draft.groups[1].cells[1] == "transport-belt", "normal click does not select a move source")
  click(slot, defines.mouse_button_type.right)
  check(state.draft.groups[1].cells[1] == nil, "right-click still clears slots")
  click(root["quick-swap-footer"]["quick-swap-cancel"])
  check(state.config.groups[1].cells[1] == "transport-belt", "cancel restores cleared slot")
  gui.open(player); root = player.gui.screen["quick-swap-window"]
  click(header(2)["quick-swap-up"])
  click(root["quick-swap-footer"]["quick-swap-apply"])
  gui.open(player); root = player.gui.screen["quick-swap-window"]
  local applied_belt = groups.find(state.config, 1)
  check(state.config.groups[1].id == 2 and applied_belt.cells[1] == "transport-belt", "apply and reopen preserve order and slots")
  check(not state.move_mode and not state.move_source, "obsolete movement state is absent")
  check(root["quick-swap-keys-horizontal"].caption[1] == "quick-swap.keys-horizontal"
    and root["quick-swap-keys-vertical"].caption[1] == "quick-swap.keys-vertical", "four controls use native localisation")
  storage.quick_swap_editor_expected = groups.copy(state.config)
  gui.close(player)
  state.config = original
end

return M
