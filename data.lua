-- Prototype-stage entry point. Every input is namespaced to avoid conflicts
-- with Factorio, DLC, and other mods.
local inputs = {
  { name = "quick-swap-cycle-kind-next", key_sequence = "SHIFT + mouse-wheel-up" },
  { name = "quick-swap-cycle-kind-previous", key_sequence = "SHIFT + mouse-wheel-down" },
  { name = "quick-swap-cycle-tier-next", key_sequence = "CONTROL + mouse-wheel-up" },
  { name = "quick-swap-cycle-tier-previous", key_sequence = "CONTROL + mouse-wheel-down" }
}

for _, input in ipairs(inputs) do
  input.type = "custom-input"
  -- Remote/map controllers are treated as spectating for custom-input
  -- dispatch. Without this flag the wheel event never reaches control.lua.
  input.enabled_while_spectating = true
  -- Block conflicting game actions before they reach the camera. Changing
  -- zoom_limits in a Lua event is too late to reliably suppress local zoom.
  -- Consumption is unconditional, so offer an explicit vanilla-input opt-out.
  input.consuming = settings.startup["quick-swap-allow-vanilla-inputs"].value and "none" or "game-only"
  input.action = "lua"
end

data:extend(inputs)
