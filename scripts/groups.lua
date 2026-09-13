local catalog = require("scripts.belt_catalog")
local M = { columns = 10, version = 1 }
-- Applied configurations are immutable until replaced by Apply. Keep indexes
-- outside storage; rebuild after loading and allow discarded drafts to be collected.
local indexes = setmetatable({}, { __mode = "k" })

function M.copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for k, v in pairs(value) do result[k] = M.copy(v) end
  return result
end

function M.supported(name)
  local item = prototypes.item[name]
  return item and item.type == "item" and item.place_result
    and not item.hidden and item.get_spoil_ticks() == 0 and item or nil
end

function M.defaults()
  local config = { version = M.version, enabled = true, next_id = 4, groups = {} }
  local function group(id, key, horizontal)
    local g = { id = id, title = { "quick-swap." .. key }, enabled = true,
      horizontal = horizontal, vertical = false, cells = {}, rows = 0 }
    config.groups[#config.groups + 1] = g
    return g
  end
  local belts = group(1, "belts", true)
  local speeds, seen = {}, {}
  for _, kind in ipairs({ "transport-belt", "underground-belt", "splitter" }) do
    for _, item in ipairs(catalog.by_kind[kind]) do
      if M.supported(item.name) and not seen[item.belt_speed] then
        seen[item.belt_speed] = true
        speeds[#speeds + 1] = item.belt_speed
      end
    end
  end
  table.sort(speeds)
  for row, speed in ipairs(speeds) do
    for col, kind in ipairs({ "transport-belt", "underground-belt", "splitter" }) do
      for _, item in ipairs(catalog.by_kind[kind]) do
        if item.belt_speed == speed and M.supported(item.name) then
          belts.cells[(row - 1) * 10 + col] = item.name
          break
        end
      end
    end
  end
  belts.rows = #speeds
  local pipes = group(2, "pipes", true)
  for col, kind in ipairs({ "pipe", "pipe-to-ground" }) do
    for _, item in ipairs(catalog.by_kind[kind]) do
      if M.supported(item.name) then pipes.cells[col] = item.name; pipes.rows = 1; break end
    end
  end
  local poles = group(3, "poles", false)
  local col = 0
  for _, item in ipairs(catalog.by_kind["electric-pole"]) do
    if M.supported(item.name) then
      if col == 10 then
        poles = group(config.next_id, "poles", false)
        config.next_id = config.next_id + 1
        col = 0
      end
      col = col + 1; poles.cells[col] = item.name; poles.rows = 1
    end
  end
  return config
end

function M.get(index)
  storage.quick_swap_players = storage.quick_swap_players or {}
  local state = storage.quick_swap_players[index]
  if not state then
    state = { config = M.defaults() }
    storage.quick_swap_players[index] = state
  end
  return state
end

function M.trim(group)
  local last = 0
  for slot in pairs(group.cells) do last = math.max(last, slot) end
  group.rows = math.ceil(last / 10)
end

function M.find(config, id)
  for index, group in ipairs(config.groups) do
    if group.id == id then return group, index end
  end
end

function M.reorder(config, id, direction)
  local group, index = M.find(config, id)
  if not group or (direction ~= -1 and direction ~= 1) then return nil end
  local target = index + direction
  if target < 1 or target > #config.groups then return nil end
  config.groups[index], config.groups[target] = config.groups[target], group
  indexes[config] = nil
  return index, target
end

function M.validate(config)
  indexes[config] = nil
  for _, group in ipairs(config.groups) do
    local seen = {}
    for slot, name in pairs(group.cells) do
      if type(slot) ~= "number" or slot < 1 or slot % 1 ~= 0 or type(name) ~= "string" then
        return false
      end
      if seen[name] then return false end
      seen[name] = true
    end
    M.trim(group)
  end
  return true
end

-- Scan only the selected row/column; never cross into a lower-priority group.
function M.target(config, name, axis, direction, usable)
  if not config.enabled then return nil end
  local index = indexes[config]
  if not index then
    index = {}
    for _, group in ipairs(config.groups) do
      for slot, item in pairs(group.cells) do
        index[item] = index[item] or {}
        index[item][#index[item] + 1] = { group = group, slot = slot }
      end
    end
    indexes[config] = index
  end
  for _, entry in ipairs(index[name] or {}) do
    local group, origin = entry.group, entry.slot
    if group.enabled then
      if origin then
        local row, col = math.floor((origin - 1) / 10) + 1, (origin - 1) % 10 + 1
        local size = axis == "horizontal" and 10 or group.rows
        local pos = axis == "horizontal" and col or row
        for offset = 1, size - 1 do
          local next_pos = pos + direction * offset
          if not group[axis] and (next_pos < 1 or next_pos > size) then break end
          next_pos = (next_pos - 1) % size + 1
          local slot = axis == "horizontal" and (row - 1) * 10 + next_pos
            or (next_pos - 1) * 10 + col
          local candidate = group.cells[slot]
          if candidate and M.supported(candidate) and usable(candidate) then return candidate end
        end
        return nil
      end
    end
  end
end

return M
