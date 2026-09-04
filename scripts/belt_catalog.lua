local belt_kinds = { "transport-belt", "underground-belt", "splitter" }
local pipe_kinds = { "pipe", "pipe-to-ground" }
local catalog = { by_name = {}, by_kind = {} }

for _, kind in ipairs(belt_kinds) do catalog.by_kind[kind] = {} end
for _, kind in ipairs(pipe_kinds) do catalog.by_kind[kind] = {} end
catalog.by_kind["electric-pole"] = {}

local function contains(values, value)
  for _, candidate in ipairs(values) do
    if candidate == value then return true end
  end
  return false
end

local function prototype_name(value)
  return type(value) == "string" and value or value.name
end

local function compare(left, right)
  if left.sort_order ~= right.sort_order then return left.sort_order < right.sort_order end
  return left.name < right.name
end

-- Prototype data is fixed for the life of a save, so this deterministic
-- catalogue needs no persistent storage and automatically includes other mods.
for name, item in pairs(prototypes.item) do
  local entity = item.place_result
  if entity and (contains(belt_kinds, entity.type) or contains(pipe_kinds, entity.type)
    or entity.type == "electric-pole") then
    -- `speed` is used by robots and units. Transport-belt connectables expose
    -- their tier speed through `belt_speed`; using `speed` made every belt
    -- appear to have tier 0 and mixed unrelated tiers by item-name order.
    local candidate = {
      name = name,
      kind = entity.type,
      family = contains(belt_kinds, entity.type) and "belt"
        or contains(pipe_kinds, entity.type) and "pipe" or "electric-pole",
      belt_speed = entity.belt_speed,
      sort_order = contains(belt_kinds, entity.type) and entity.belt_speed or item.order or "",
      item_prototype = item
    }
    if candidate.family ~= "belt" or candidate.belt_speed then
      catalog.by_name[name] = candidate
      table.insert(catalog.by_kind[candidate.kind], candidate)
    end
  end
end
for _, candidates in pairs(catalog.by_kind) do table.sort(candidates, compare) end

function catalog.get_cursor_candidate(player, prefer_ghost)
  if prefer_ghost then
    local ghost = player.cursor_ghost
    if ghost then return catalog.by_name[prototype_name(ghost.name)] end
  end
  local cursor = player.cursor_stack
  return cursor and cursor.valid_for_read and catalog.by_name[cursor.name] or nil
end

function catalog.find_kind_target(current, direction, usable)
  if current.family == "electric-pole" then
    local poles = catalog.by_kind["electric-pole"]
    local index
    for i, candidate in ipairs(poles) do
      if candidate.name == current.name then index = i break end
    end
    if not index or #poles < 2 then return nil end

    -- Electric poles have a meaningful size/capability progression. Walk only
    -- in the requested direction, skipping unavailable poles, and stop at the
    -- ends instead of wrapping between the smallest pole and the substation.
    local target_index = index + direction
    while target_index >= 1 and target_index <= #poles do
      local target = poles[target_index]
      if usable(target) then return target end
      target_index = target_index + direction
    end
    return nil
  end

  local kinds = current.family == "belt" and belt_kinds
    or current.family == "pipe" and pipe_kinds or nil
  if not kinds then return nil end
  local index
  for i, kind in ipairs(kinds) do if kind == current.kind then index = i break end end
  if not index then return nil end
  local target_kind = kinds[((index - 1 + direction) % #kinds) + 1]
  for _, candidate in ipairs(catalog.by_kind[target_kind]) do
    if (current.family ~= "belt" or candidate.belt_speed == current.belt_speed)
      and usable(candidate) then return candidate end
  end
end

function catalog.find_tier_target(current, direction, usable)
  if current.family ~= "belt" then return nil end
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
