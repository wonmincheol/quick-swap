local belt_kinds = { "transport-belt", "underground-belt", "splitter" }
local pipe_kinds = { "pipe", "pipe-to-ground" }
local catalog = { by_kind = {} }

for _, kind in ipairs(belt_kinds) do catalog.by_kind[kind] = {} end
for _, kind in ipairs(pipe_kinds) do catalog.by_kind[kind] = {} end
catalog.by_kind["electric-pole"] = {}

local function contains(values, value)
  for _, candidate in ipairs(values) do
    if candidate == value then return true end
  end
  return false
end

local function compare(left, right)
  if left.sort_order ~= right.sort_order then return left.sort_order < right.sort_order end
  return left.name < right.name
end

-- Build deterministic default-group candidates from the current prototypes.
-- Actual cursor navigation is handled by scripts.groups.
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
    }
    if candidate.family ~= "belt" or candidate.belt_speed then
      table.insert(catalog.by_kind[candidate.kind], candidate)
    end
  end
end
for _, candidates in pairs(catalog.by_kind) do table.sort(candidates, compare) end

return catalog
