local groups = require("scripts.groups")
local M = {}
local cache = {}

function M.invalidate() cache = {} end

function M.items(force)
  if not cache[force.index] then
    local result = {}
    for _, recipe in pairs(force.recipes) do
      if recipe.enabled then
        for _, product in ipairs(recipe.products) do
          if product.type == "item" and groups.supported(product.name) then result[product.name] = true end
        end
      end
    end
    cache[force.index] = result
  end
  return cache[force.index]
end

function M.filters(force)
  local names, filters = {}, {}
  for name in pairs(M.items(force)) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do filters[#filters + 1] = { filter = "name", name = name } end
  -- An empty filter would expose every item. Use an impossible conjunction instead.
  if #filters == 0 then
    filters = { { filter = "type", type = "item" }, { filter = "type", type = "item", invert = true, mode = "and" } }
  end
  return filters
end

return M
