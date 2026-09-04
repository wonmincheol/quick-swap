local belt_catalog = require("scripts.belt_catalog")
local cursor_swap = require("scripts.cursor_swap")

local function is_unlocked_for_force(force, candidate)
  for _, recipe in pairs(force.recipes) do
    if recipe.enabled then
      for _, product in ipairs(recipe.products) do
        if product.type == "item" and product.name == candidate.name then
          return true
        end
      end
    end
  end
  return false
end

local function uses_character_inventory(player)
  return player.controller_type == defines.controllers.character
    and player.render_mode == defines.render_mode.game
end

local function can_use_candidate(player, candidate)
  if uses_character_inventory(player) then
    return cursor_swap.has_inventory_stack(player, candidate)
  end
  return is_unlocked_for_force(player.force, candidate)
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
    if not player then return end
    local use_inventory = uses_character_inventory(player)
    local current = belt_catalog.get_cursor_candidate(player, not use_inventory)
    if not current then return end
    local cursor = cursor_swap.get_definition(player, not use_inventory)
    if not cursor then return end
    local quality = cursor.quality
    local target = belt_catalog["find_" .. kind .. "_target"](current, direction, function(candidate)
      return can_use_candidate(player, candidate)
    end)
    if target then
      if swap(player, target) then lock_zoom_until_next_tick(player, event.tick) end
    end
  end
end

script.on_event("quick-swap-cycle-kind-next", cycle("kind", 1))
script.on_event("quick-swap-cycle-kind-previous", cycle("kind", -1))
script.on_event("quick-swap-cycle-tier-next", cycle("tier", 1))
script.on_event("quick-swap-cycle-tier-previous", cycle("tier", -1))
