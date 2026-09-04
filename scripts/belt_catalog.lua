local catalog = { by_name = {}, by_kind = {
  ["transport-belt"] = {}, ["underground-belt"] = {}, ["splitter"] = {}
} }
local kinds = { "transport-belt", "underground-belt", "splitter" }

local function is_belt_kind(entity)
  return entity and (entity.type == "transport-belt" or entity.type == "underground-belt" or entity.type == "splitter")
end

local function compare(left, right)
  return left.belt_speed == right.belt_speed and left.name < right.name or left.belt_speed < right.belt_speed
end

-- Prototype data is fixed for the life of a save, so this deterministic
-- catalogue needs no persistent storage and automatically includes other mods.
for name, item in pairs(prototypes.item) do
  local entity = item.place_result
  if is_belt_kind(entity) then
    -- `speed` is used by robots and units. Transport-belt connectables expose
    -- their tier speed through `belt_speed`; using `speed` made every belt
    -- appear to have tier 0 and mixed unrelated tiers by item-name order.
    local candidate = {
      name = name,
      kind = entity.type,
      belt_speed = entity.belt_speed,
      item_prototype = item
    }
    if candidate.belt_speed then
      catalog.by_name[name] = candidate
      table.insert(catalog.by_kind[candidate.kind], candidate)
    end
  end
end
for _, candidates in pairs(catalog.by_kind) do table.sort(candidates, compare) end

function catalog.get_cursor_candidate(player)
  local cursor = player.cursor_stack
  return cursor and cursor.valid_for_read and catalog.by_name[cursor.name] or nil
end

function catalog.find_kind_target(current, direction, usable)
  local index
  for i, kind in ipairs(kinds) do if kind == current.kind then index = i break end end
  if not index then return nil end
  local target_kind = kinds[((index - 1 + direction) % #kinds) + 1]
  for _, candidate in ipairs(catalog.by_kind[target_kind]) do
    if candidate.belt_speed == current.belt_speed and usable(candidate) then return candidate end
  end
end

function catalog.find_tier_target(current, direction, usable)
  local selected
  for _, candidate in ipairs(catalog.by_kind[current.kind]) do
    local valid_direction = direction > 0 and candidate.belt_speed > current.belt_speed
      or direction < 0 and candidate.belt_speed < current.belt_speed
    if valid_direction and usable(candidate) and (not selected
      or direction > 0 and candidate.belt_speed < selected.belt_speed
      or direction < 0 and candidate.belt_speed > selected.belt_speed
      or candidate.belt_speed == selected.belt_speed and candidate.name < selected.name) then
      selected = candidate
    end
  end
  return selected
end

return catalog
