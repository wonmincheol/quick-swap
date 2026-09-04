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

local function can_use_candidate(player, candidate)
  if player.controller_type == defines.controllers.character then
    return cursor_swap.has_inventory_stack(player, candidate)
  end
  return is_unlocked_for_force(player.force, candidate)
end

local function swap(player, candidate)
  if player.controller_type == defines.controllers.character then
    cursor_swap.swap_from_inventory(player, candidate)
  else
    cursor_swap.swap_in_remote_view(player, candidate)
  end
end

local function cycle(kind, direction)
  return function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local current = belt_catalog.get_cursor_candidate(player)
    if not current then return end
    local target = belt_catalog["find_" .. kind .. "_target"](current, direction, function(candidate)
      return can_use_candidate(player, candidate)
    end)
    if target then swap(player, target) end
  end
end

script.on_event("quick-swap-belt-cycle-kind-next", cycle("kind", 1))
script.on_event("quick-swap-belt-cycle-kind-previous", cycle("kind", -1))
script.on_event("quick-swap-belt-cycle-tier-next", cycle("tier", 1))
script.on_event("quick-swap-belt-cycle-tier-previous", cycle("tier", -1))
