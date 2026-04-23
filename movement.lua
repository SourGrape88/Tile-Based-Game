-- MOVEMENT.lUA --------------------------------------------------------------
-- If it answers “where can a unit move?” it goes in movement.lua

local Movement = {}

local terrainCost = {
    [1] = 1, -- Grass 
    [2] = 2, -- Forest 
    [3] = math.huge -- Mountain
}

local function isEnemyAt(x, y, enemyUnits)
    for _, e in ipairs(enemyUnits) do
        if e.x == x and e.y == y then
            return true
        end
    end
    return false
end

local function isAllyAt(x, y, playerUnits, unit)
    for _, u in ipairs(playerUnits) do
        if u ~= unit and u.x == x and u.y == y then
            return true
        end
    end

    return false
end


function Movement.calculateReachable(unit, terrain, playerUnits, enemyUnits)
  local result = {}
  local cameFrom = {} -- Tracks Path History

  for y = 1, #terrain do
    result[y] = {}
    cameFrom[y] = {} 
  end

  -- Queue for Flood-Fill (x, y, remainingMove)
  local queue = {
    -- {x, y, remainingMovement}
    {unit.x, unit.y, unit.move}
  }

  -- Mark Starting Tile as Reachable 
  result[unit.y][unit.x] = unit.move
  cameFrom[unit.y][unit.x] = nil -- Starting Tile Has No Parent (Previous Tile)

    -- Pull the Oldest Tile from the Queue
  while #queue > 0 do
    local node = table.remove(queue, 1)
    local x, y, remaining = node[1], node[2], node[3]

    -- Try 4 Directions (Up, Down, Left, Right)
    -- Only Air Units can Move Diagonally 
    local directions = {
      {1, 0}, {-1, 0}, {0, 1}, {0,-1}
    }

    -- Try to Move 1 Tile in Each Direction 
    for _, d in ipairs(directions) do
      local nx = x + d[1]
      local ny = y + d[2]

    -- Bounds Check
    if terrain[ny] and terrain[ny][nx] then
      local tileType = terrain[ny][nx]
      local cost = terrainCost[tileType]

      -- remaining tiles after Cost has been calculated 
      -- {x, y, remaining total movement - cost}
      local newRemaining = remaining - cost 

      if newRemaining >= 0 then -- If the Unit cant afford the tile, the path ends here 
        -- Only Continue if we've never been here before
        -- Or we reached it with more remaining movement than last time 
       if isEnemyAt(nx, ny, enemyUnits) then
        goto continue
       end

        -- Prevents loops 
        if result[ny][nx] == nil or newRemaining > result[ny][nx] then
          -- Track the Best Movement for this tile
          -- Continue expanding outward from it 
          -- Allow Allies to Pass through but do not allow stopping
            local isAlly = isAllyAt(nx, ny, playerUnits, unit)

            --cameFrom[nx][ny] = {x, y}
            
            -- Only Mark as Reachable if NOT Ally
            if not isAlly then
                result[ny][nx] = newRemaining
                -- What Tile did I Come From 
                cameFrom[ny][nx] = {x, y}
            end

            table.insert(queue, {nx, ny, newRemaining})

          -- Remove from "reachable tiles" if it's an ally tile 
          if isAlly then
            result[ny][nx] = nil
          end
        end
      end
    end
    ::continue::
  end
end
  return result, cameFrom 

end

function Movement.calculateAttackable(unit, terrain)
    local result = {}

    -- Initialize Grid
    for y = 1, #terrain do
        result[y] = {}
    end

    -- Loop over the Entire Map
    for y = 1, #terrain do
        for x = 1, #terrain[y] do
            -- Manhattan Distance from Unit
            local dist = math.abs(unit.x - x) + math.abs(unit.y - y)
            
            -- If distance is inside attack range
            if dist <= unit.range and dist > 0 then
                result[y][x] = true -- Mark Tile as Attackable
            end
        end
    end

    return result 
end

-- Parent Path Helper (UI-side)
-- Build a Path from this Unit to this Hovered Tile
-- tx, ty = TargetX Coordinate and TargetY Coordinate
function Movement.buildPath(cameFrom, tx, ty)
  local path = {}

  -- While this Tile has a Recorded Previous Tile...
  while cameFrom[ty] and cameFrom[ty][tx] do
    -- Insert Tile before the Hovered Tile 
    table.insert(path, 1, { x = tx, y = ty })
    local prev = cameFrom[ty][tx]
    -- Move One Step Backwards
    tx, ty = prev[1], prev[2]
  end
  -- Return the Final Path 
  return path
end

return Movement 
