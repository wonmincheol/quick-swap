local cursor_swap = {}

local function definition(name, count, quality)
  return { name = name, count = count, quality = quality }
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

function cursor_swap.has_inventory_stack(player, candidate)
  local current, inventory = cursor_definition(player), player.get_main_inventory()
  return current and inventory and inventory.get_item_count({ name = candidate.name, quality = current.quality }) > 0
end

function cursor_swap.swap_from_inventory(player, candidate)
  local current, cursor, inventory = cursor_definition(player), player.cursor_stack, player.get_main_inventory()
  if not current or not cursor or not inventory then return false end
  local available_count = inventory.get_item_count({ name = candidate.name, quality = current.quality })
  local target = definition(candidate.name, target_count(current, candidate, available_count), current.quality)
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
  local current, cursor = cursor_definition(player), player.cursor_stack
  if not current or not cursor then return false end
  local target = definition(candidate.name, target_count(current, candidate), current.quality)
  return cursor.can_set_stack(target) and cursor.set_stack(target)
end

return cursor_swap
