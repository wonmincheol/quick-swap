local M = {}
local groups = require("scripts.groups")

function M.run(player, check, initialize)
  local state = groups.get(player.index)
  local original_config = state.config
  state.config = { enabled = true, groups = {
    { id = 1, enabled = true, horizontal = true, vertical = false, rows = 2,
      cells = { [1] = "transport-belt", [2] = "underground-belt", [11] = "fast-transport-belt" } }
  } }
  local actions = {
    { "quick-swap-cycle-kind-next", "transport-belt", "underground-belt" },
    { "quick-swap-cycle-kind-previous", "underground-belt", "transport-belt" },
    { "quick-swap-cycle-tier-next", "transport-belt", "fast-transport-belt" },
    { "quick-swap-cycle-tier-previous", "fast-transport-belt", "transport-belt" }
  }
  local consuming = settings.startup["quick-swap-allow-vanilla-inputs"].value and "none" or "game-only"
  for _, action in ipairs(actions) do
    local prototype = prototypes.custom_input[action[1]]
    check(prototype.consuming == consuming and prototype.enabled_while_spectating,
      "native input policy: " .. action[1])
  end

  for _, mode in ipairs({ defines.controllers.character, defines.controllers.remote }) do
    player.set_controller { type = mode, character = player.character }
    local original_limits, original_zoom = player.zoom_limits, player.zoom
    local limits = { closest = { zoom = 2.5 }, furthest = { zoom = 0.2 },
      furthest_game_view = { zoom = 0.3 } }
    player.zoom_limits = limits
    player.zoom = 0.75
    local function unchanged()
      local actual = player.zoom_limits
      return actual.closest.zoom == 2.5 and actual.furthest.zoom == 0.2
        and actual.furthest_game_view.zoom == 0.3 and math.abs(player.zoom - 0.75) < 0.000001
        and storage.quick_swap_zoom_locks == nil
    end
    local function cursor(name)
      player.clear_cursor()
      if mode == defines.controllers.character then
        local inventory = player.get_main_inventory()
        inventory.clear()
        for _, item in ipairs({ "transport-belt", "underground-belt", "fast-transport-belt" }) do
          inventory.insert { name = item, count = 20 }
        end
        player.cursor_stack.set_stack { name = name, count = 5 }
      else
        player.cursor_ghost = { name = name, quality = "normal" }
      end
    end
    local function held()
      return mode == defines.controllers.character and player.cursor_stack.name or player.cursor_ghost.name.name
    end
    local function input(name, in_gui)
      script.get_event_handler(name) { player_index = player.index, tick = game.tick, in_gui = in_gui }
    end
    for _, action in ipairs(actions) do
      cursor(action[2])
      input(action[1])
      check(held() == action[3] and unchanged(), "swap keeps camera: " .. mode .. " " .. action[1])
    end
    cursor("fast-transport-belt")
    input("quick-swap-cycle-tier-next")
    check(held() == "fast-transport-belt" and unchanged(), "end of column keeps camera: " .. mode)
    cursor("transport-belt")
    input("quick-swap-cycle-kind-next", true)
    check(held() == "transport-belt" and unchanged(), "GUI input ignored: " .. mode)
    state.config.enabled = false
    input("quick-swap-cycle-kind-next")
    check(held() == "transport-belt" and unchanged(), "disabled input keeps camera: " .. mode)
    state.config.enabled = true
    if mode == defines.controllers.character then
      player.get_main_inventory().clear()
      input("quick-swap-cycle-kind-next")
      check(held() == "transport-belt" and unchanged(), "missing inventory keeps camera")
    end

    -- A save made during the old one-tick lock must not retain that lock on upgrade.
    storage.quick_swap_zoom_locks = {
      [player.index] = { zoom_limits = limits, unlock_tick = game.tick + 1 },
      [65535] = { zoom_limits = limits, unlock_tick = game.tick + 1 }
    }
    player.zoom_limits = { closest = { zoom = 0.75 }, furthest = { zoom = 0.75 } }
    initialize()
    check(unchanged(), "legacy lock restored and removed: " .. mode)
    player.zoom_limits = original_limits
    player.zoom = original_zoom
  end
  state.config = original_config
end

return M
