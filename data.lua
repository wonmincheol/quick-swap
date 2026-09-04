-- Prototype-stage entry point. Every input is namespaced to avoid conflicts
-- with Factorio, DLC, and other mods.
local inputs = {
  { name = "quick-swap-belt-cycle-kind-next", key_sequence = "SHIFT + mouse-wheel-up" },
  { name = "quick-swap-belt-cycle-kind-previous", key_sequence = "SHIFT + mouse-wheel-down" },
  { name = "quick-swap-belt-cycle-tier-next", key_sequence = "CONTROL + mouse-wheel-up" },
  { name = "quick-swap-belt-cycle-tier-previous", key_sequence = "CONTROL + mouse-wheel-down" }
}

for _, input in ipairs(inputs) do
  input.type = "custom-input"
  -- Remote/map controllers are treated as spectating for custom-input
  -- dispatch. Without this flag the wheel event never reaches control.lua.
  input.enabled_while_spectating = true
  -- Let Factorio process the same wheel input so context-sensitive vanilla
  -- actions, such as cycling a blueprint book, remain available. When a swap
  -- succeeds, control.lua temporarily locks zoom until the following tick.
  input.consuming = "none"
  input.action = "lua"
end

data:extend(inputs)
