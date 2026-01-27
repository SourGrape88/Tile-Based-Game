-- Tile Based Game

-- Define the Tile Size
local tileSize = 64

-- Number of tiles in x and y directions
local tilesX, tilesY

local playerUnit = {x=3, y=3, move=4, color={0, 0, 1}}
local enemyUnit = {x=5, y=5, color={0.9, 0, 0.3}}
local selectedUnit = nil -- Currently Selected Unit

-- 1 = Grass
-- 2 = Forest
-- 3 = Mountain
local terrain = {
  {1,1,1,1,1,1,1,1,1,1,1,1,2},
  {1,2,1,2,1,2,1,2,1,1,2,1,1},
  {1,1,1,3,3,3,3,1,1,1,1,1,1},
  {1,1,2,2,2,2,2,2,1,1,1,2,2},
  {1,1,1,1,1,1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1,1,1,1,2,1},
  {1,2,1,2,1,2,1,2,1,1,2,1,1},
  {1,1,1,3,3,3,3,1,1,1,1,1,1},
  {1,1,2,2,2,2,2,2,1,1,1,2,1},
  {1,1,1,1,1,1,1,1,1,1,1,1,1},
}

local terrainCost = {
  [1] = 1, -- Grass 
  [2] = 2, -- Forest
  [3] = math.huge -- Mountain (impassable)
}

local reachable = nil 

function love.load()
  love.window.setMode(800, 600)
  love.window.setTitle("Tile Based Game")

  -- Get the Window Size
  local windowWidth, windowHeight = love.graphics.getDimensions()

  -- Calculate how many tiles will Fit into the Window
  tilesX = math.ceil(windowWidth / tileSize) -- 800 / 32
  tilesY = math.ceil(windowHeight / tileSize) -- 600 / 32

end

function love.mousepressed(mx, my, button)
  if button == 1 then
    -- Convert Mouse Coordinates to Tile Coordinates
    local tileX = math.floor(mx / tileSize) + 1
    local tileY = math.floor(my / tileSize) + 1 
  
    -- If we clicked on the Player Unit, Select it 
    if tileX == playerUnit.x and tileY == playerUnit.y then
      selectedUnit = playerUnit 
      reachable = calculateReachable(playerUnit)
    elseif selectedUnit and reachable and reachable[tileY] and reachable[tileY][tileX] ~= nil then
      -- Move the selected unit to the Clicked Tile
      selectedUnit.x = tileX 
      selectedUnit.y = tileY 
      selectedUnit = nil -- Deselect after Moving
      reachable = nil 
    end
  end
  
end

function love.update(dt)
  
end

-- Calculates Which Tiles Can Be Reached 
function calculateReachable(unit)
  local result = {}

  for y = 1, #terrain do
  result[y] = {}
  end

  -- Queue for Flood-Fill (x, y, remainingMove)
  local queue = {
    -- {x, y, remainingMovement}
    {unit.x, unit.y, unit.move}
  }

  -- Mark Starting Tile as Reachable 
  result[unit.y][unit.x] = unit.move

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
          table.insert(queue, {nx, ny, newRemaining})
        end
      end
    end
  end
end
  return result 

end

function love.draw()
  for y = 1, #terrain do 
    for x = 1, #terrain[y] do 
      local t = terrain[y][x]
      if t == 1 then 
        love.graphics.setColor(0.2, 0.7, 0.2) -- Grass 
    elseif t == 2 then 
        love.graphics.setColor(0.1, 0.3, 0.1) -- Forest 
    elseif t == 3 then 
        love.graphics.setColor(0.3, 0.3, 0.3) -- Mountain 
    end 

    love.graphics.rectangle(
        "fill",
        (x - 1) * tileSize,
        (y - 1) * tileSize,
        tileSize,
        tileSize
      )
  end
end

  -- Draw the Grid Lines
  love.graphics.setColor(1, 1, 1, 1) -- White Grid Lines
  for y = 0, tilesY do
    love.graphics.line(0, y * tileSize, tilesX * tileSize, y * tileSize)
  end
  
  for x = 0, tilesX do
    love.graphics.line(x * tileSize, 0, x * tileSize, tilesY * tileSize)
  end


  -- Draw Unit Selector
  if selectedUnit and reachable then
    for y = 1, #terrain do 
      for x = 1, #terrain[y] do
        if reachable[y][x] ~= nil then   
          love.graphics.setColor(0.2, 0.4, 1, 1) -- Light Blue Highlight
          love.graphics.setLineWidth(8) -- 4 Pixels Thick
          love.graphics.rectangle(
            "line",
            (x - 1) * tileSize,
            (y - 1) * tileSize,
            tileSize,
            tileSize
          )
          love.graphics.setLineWidth(1)
          print("Remaining move at tile: ", x, y, reachable[y][x])
        end 
      end 
    end
  end 
  -- Draw Player Unit 
  love.graphics.setColor(playerUnit.color)
  love.graphics.rectangle(
    "fill",
    (playerUnit.x - 1) * tileSize, 
    (playerUnit.y - 1) * tileSize,
    tileSize,
    tileSize
  )
  
  -- Mouse to Tile Coordinates 
  local mx, my = love.mouse.getPosition()
  local hoverTileX = math.floor(mx / tileSize) + 1 
  local hoverTileY = math.floor(my / tileSize) + 1 

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(
    "Tile: (" .. hoverTileX ..", " .. hoverTileY .. ")", 10, 10
  )
  

  -- Draw Enemy Unit 
  love.graphics.setColor(enemyUnit.color)
  love.graphics.rectangle(
    "fill",
      (enemyUnit.x - 1) * tileSize,
      (enemyUnit.y - 1) * tileSize,
      tileSize,
      tileSize
  )

  -- Reset the Color so future drawings aren't tinted
  love.graphics.setColor(1, 1, 1, 1)
end

