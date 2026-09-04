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
  -- Custom inputs cannot decide at runtime whether to consume the input. Use
  -- game-only so the wheel never also triggers the game's zoom action while a
  -- belt swap binding is pressed.
  input.consuming = "game-only"
  input.action = "lua"
end

data:extend(inputs)
