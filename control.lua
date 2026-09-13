local groups = require("scripts.groups")
local unlocks = require("scripts.unlocks")
local gui = require("scripts.gui")
local cursor_swap = require("scripts.cursor_swap")

local function uses_character_inventory(player)
  return player.controller_type == defines.controllers.character
    and player.render_mode == defines.render_mode.game
end

local function can_use_candidate(player, candidate)
  if not unlocks.items(player.force)[candidate.name] then return false end
  if uses_character_inventory(player) then
    return cursor_swap.has_inventory_stack(player, candidate)
  end
  return true
end

local function swap(player, candidate)
  if uses_character_inventory(player) then
    return cursor_swap.swap_from_inventory(player, candidate)
  else
    return cursor_swap.swap_in_remote_view(player, candidate)
  end
end

local function lock_zoom_until_next_tick(player, tick)
  storage.quick_swap_zoom_locks = storage.quick_swap_zoom_locks or {}
  local pending = storage.quick_swap_zoom_locks[player.index]
  if pending then
    -- Several wheel steps can arrive during one tick. Keep the original limits
    -- and postpone unlocking until all normal input handling has completed.
    pending.unlock_tick = tick + 1
  else
    local zoom = player.zoom
    local zoom_limits = player.zoom_limits
    storage.quick_swap_zoom_locks[player.index] = {
      zoom_limits = zoom_limits,
      unlock_tick = tick + 1
    }

    -- The custom-input event runs before Factorio's normal input event. Clamp
    -- both ends to the current zoom so the following wheel action cannot move
    -- the camera; retain the view threshold to avoid changing render modes.
    player.zoom_limits = {
      closest = { zoom = zoom },
      furthest = { zoom = zoom },
      furthest_game_view = zoom_limits.furthest_game_view
    }
  end
end

script.on_event(defines.events.on_tick, function(event)
  local locks_by_player = storage.quick_swap_zoom_locks
  if not locks_by_player then return end

  for player_index, pending in pairs(locks_by_player) do
    if event.tick >= pending.unlock_tick then
      local player = game.get_player(player_index)
      if player then player.zoom_limits = pending.zoom_limits end
      locks_by_player[player_index] = nil
    end
  end
end)

local function cycle(kind, direction)
  return function(event)
    local player = game.get_player(event.player_index)
    if not player or gui.is_open(player) then return end
    local use_inventory = uses_character_inventory(player)
    local cursor = cursor_swap.get_definition(player, not use_inventory)
    if not cursor or not groups.supported(cursor.name) then return end
    local name = groups.target(groups.get(player.index).config, cursor.name, kind, direction, function(item)
      return can_use_candidate(player, { name = item, item_prototype = prototypes.item[item] })
    end)
    if name then
      local target = { name = name, item_prototype = prototypes.item[name] }
      if swap(player, target) then lock_zoom_until_next_tick(player, event.tick) end
    end
  end
end

script.on_event("quick-swap-cycle-kind-next", cycle("horizontal", 1))
script.on_event("quick-swap-cycle-kind-previous", cycle("horizontal", -1))
script.on_event("quick-swap-cycle-tier-next", cycle("vertical", 1))
script.on_event("quick-swap-cycle-tier-previous", cycle("vertical", -1))

local function initialize()
  unlocks.invalidate()
  for _, player in pairs(game.players) do
    gui.close(player)
    groups.get(player.index)
    gui.ensure_button(player)
  end
end
script.on_init(initialize)
script.on_configuration_changed(initialize)
script.on_event({ defines.events.on_player_created, defines.events.on_player_joined_game }, function(event)
  local player = game.get_player(event.player_index)
  groups.get(player.index); gui.ensure_button(player)
end)
script.on_event(defines.events.on_player_removed, function(event)
  if storage.quick_swap_players then storage.quick_swap_players[event.player_index] = nil end
end)
script.on_event(defines.events.on_gui_click, gui.click)
script.on_event(defines.events.on_gui_checked_state_changed, gui.changed)
script.on_event(defines.events.on_gui_elem_changed, gui.changed)
script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.valid and event.element.name == "quick-swap-window" then
    local player = game.get_player(event.player_index)
    gui.request_close(player)
    if gui.is_open(player) then player.opened = event.element end
  end
end)
local function refresh_unlocks()
  unlocks.invalidate()
  for _, player in pairs(game.players) do gui.refresh(player) end
end
script.on_event({ defines.events.on_research_finished, defines.events.on_research_reversed,
  defines.events.on_force_reset, defines.events.on_technology_effects_reset,
  defines.events.on_player_changed_force, defines.events.on_forces_merged }, refresh_unlocks)
