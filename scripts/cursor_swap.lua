local cursor_swap = {}

local function definition(name, count, quality)
  return { name = name, count = count, quality = quality }
end

local function prototype_name(value)
  return type(value) == "string" and value or value.name
end

local function cursor_definition(player)
  local cursor = player.cursor_stack
  if not cursor or not cursor.valid_for_read then return nil end
  return definition(cursor.name, cursor.count, cursor.quality.name)
end

local function target_count(current, candidate, available_count)
  local count = math.min(current.count, candidate.item_prototype.stack_size)
  return available_count and math.min(count, available_count) or count
end

local function cursor_ghost_definition(player)
  local ghost = player.cursor_ghost
  if not ghost then return nil end
  return definition(prototype_name(ghost.name), 1, prototype_name(ghost.quality))
end

function cursor_swap.get_definition(player, prefer_ghost)
  if prefer_ghost then
    return cursor_ghost_definition(player) or cursor_definition(player)
  end
  return cursor_definition(player)
end

local function inventory_quality(inventory, item_name)
  local selected
  for _, stack in ipairs(inventory.get_contents()) do
    if stack.name == item_name and stack.count > 0 then
      local quality = prototypes.quality[stack.quality]
      if quality then
        local choice = {
          name = stack.quality,
          count = stack.count,
          level = quality.level
        }
        if not selected
          or choice.level > selected.level
          or choice.level == selected.level and choice.name < selected.name then
          selected = choice
        end
      end
    end
  end
  return selected
end

function cursor_swap.has_inventory_stack(player, candidate)
  local current, inventory = cursor_definition(player), player.get_main_inventory()
  return current and inventory and inventory_quality(inventory, candidate.name) ~= nil
end

function cursor_swap.swap_from_inventory(player, candidate)
  local current, cursor, inventory = cursor_definition(player), player.cursor_stack, player.get_main_inventory()
  if not current or not cursor or not inventory then return false end
  local selected = inventory_quality(inventory, candidate.name)
  if not selected then return false end
  local target = definition(
    candidate.name,
    target_count(current, candidate, selected.count),
    selected.name
  )
  if target.count < 1 or not cursor.can_set_stack(target) then return false end

  -- Removing the target first makes room for the original cursor stack. Every
  -- failure path restores the inventory before returning.
  if inventory.remove(target) ~= target.count then return false end
  if inventory.insert(current) ~= current.count then
    inventory.remove(current); inventory.insert(target); return false
  end
  if not cursor.set_stack(target) then
    inventory.remove(current); inventory.insert(target); return false
  end
  return true
end

function cursor_swap.swap_in_remote_view(player, candidate)
  local current = cursor_swap.get_definition(player, true)
  if not current then return false end

  -- Remote view uses a cursor ghost rather than an inventory-backed stack.
  -- Assigning the ghost also works when entering the map with a real stack and
  -- avoids consuming or creating inventory items.
  player.cursor_ghost = { name = candidate.name, quality = current.quality }
  local ghost = player.cursor_ghost
  return ghost and prototype_name(ghost.name) == candidate.name
    and prototype_name(ghost.quality) == current.quality
end

return cursor_swap
