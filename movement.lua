-- If it answers “where can a unit move?” it goes in movement.lua

local Movement = {}

local terrainCost = {
    [1] = 1, -- Grass 
    [2] = 2, -- Forest 
    [3] = math.huge -- Mountain
}

function Movement.calculateReachable(unit, terrain)
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
        -- Prevents loops 
        if result[ny][nx] == nil or newRemaining > result[ny][nx] then
          -- Track the Best Movement for this tile
          -- Continue expanding outward from it 
          result[ny][nx] = newRemaining
            -- What Tile did I Come From 
            cameFrom[ny][nx] = {x, y}

          table.insert(queue, {nx, ny, newRemaining})
        end
      end
    end
  end
end
  return result, cameFrom 

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