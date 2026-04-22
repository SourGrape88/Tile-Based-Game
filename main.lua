-- Tile Based Game

-- Imported Tools 
local Movement = require("movement")

-- Define the Tile Size
local tileSize = 64

-- Number of tiles in x and y directions
local tilesX, tilesY

local currentTurn = "player" -- "player" or "enemy"

local playerUnits = {
    {
  x=3, 
  y=3, 
  move=4, 
  color={0, 0, 1},
  isMoving = false,
  hasMoved = false,
  path = nil, -- Path that Unit will Walk 
  pathIndex = 1, -- Current Step in the Path 
  moveDelay = 0.25, -- Time Between Steps 
  moveTimer = 0 -- Counts Time 
},
    {
      x=4, 
      y=3, 
      move=3, 
      color={0, 0.5, 1},
      isMoving = false,
      hasMoved = false,
      path = nil, -- Path that Unit will Walk 
      pathIndex = 1, -- Current Step in the Path 
      moveDelay = 0.25, -- Time Between Steps 
      moveTimer = 0 -- Counts Time 
    }
}


local enemyUnit = {x=5, y=5, color={0.9, 0, 0.3}}
local selectedUnit = nil -- Currently Selected Unit
local hoverPath = nil  -- Shows the Path when hovering
local reachable = nil
local cameFrom = nil 
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
  
    -- Loop through all Player Units 
    for _, unit in ipairs(playerUnits) do
        if currentTurn == "player" and tileX == unit.x and tileY == unit.y and not unit.hasMoved then
            selectedUnit = unit
            reachable, cameFrom = Movement.calculateReachable(unit, terrain)
            return
        end

    end
      -- Only IF the Tile is Reachable 
      -- Move the selected unit to the Clicked Tile
    if selectedUnit and reachable and reachable[tileY] and reachable[tileY][tileX] ~= nil then
      selectedUnit.path = Movement.buildPath(cameFrom, tileX, tileY) -- Save the Best Path 
      selectedUnit.pathIndex = 1 -- Start at the Beginning of the Path 
      selectedUnit.isMoving = true -- Change State To "Moving"
      selectedUnit = nil -- Deselect after Moving
      reachable = nil -- Prevents Input During Movement 
    end
  end
  
end

function love.update(dt)
  -- If the Unit is Moving... 
  for _, unit in ipairs(playerUnits) do
      if unit.isMoving then 
        -- Start the moveTimer 
        unit.moveTimer = unit.moveTimer + dt
        -- If The Unit has Passed the Delay Timer...
        if unit.moveTimer >= unit.moveDelay then
          -- Reset the Timer 
          unit.moveTimer = 0

        -- Grab the Next Tile in the Path 
        local node = unit.path[unit.pathIndex]

          -- If there is Another Step in the Path...
          if node then
            -- Move the Unit to the Tile 
            unit.x = node.x 
            unit.y = node.y 
            -- Update the Unit's Path Index 
            unit.pathIndex = unit.pathIndex + 1
          else 
            -- If the Path is Finished
            -- Update "isMoving" state 
            unit.isMoving = false 
            -- Reset Path 
            unit.path = nil 
            unit.hasMoved = true

            endTurn()
          end
        end
        end
    end
end

function startPlayerTurn()
    for _, unit in ipairs(playerUnits) do
        unit.hasMoved = false
    end
end

function startEnemyTurn()
    enemyAct()
    --endTurn()
end

function enemyAct()
    -- Do Nothing for now
    print("Enemy Turn...")
end

function endTurn()
    if currentTurn == "player" then
        currentTurn = "enemy"
        startEnemyTurn()
    else
        currentTurn = "player"
        startPlayerTurn()
    end
end

-- END TURN -------------------------------------
function love.keypressed(key)
    if key == "space" then
        endTurn()
    end
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
  for _, unit in ipairs(playerUnits) do
      love.graphics.setColor(unit.color)
      love.graphics.rectangle(
        "fill",
        (unit.x - 1) * tileSize, 
        (unit.y - 1) * tileSize,
        tileSize,
        tileSize
      )
  end 
  -- Mouse to Tile Coordinates 
  local mx, my = love.mouse.getPosition() -- Get Mouse Coordinates
  -- Convert Mouse Position to Tile Position 
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

  if selectedUnit and reachable and reachable[hoverTileY] and reachable[hoverTileY][hoverTileX] then
    hoverPath = Movement.buildPath(cameFrom, hoverTileX, hoverTileY)
  else 
    hoverPath = nil 
  end

  -- Draw Hovering Path 
  if hoverPath then
    for _, node in ipairs(hoverPath) do
      love.graphics.setColor(1, 1, 0, 0.6) -- Yellow, Semi-Transparent
      love.graphics.rectangle(
        "fill",
        (node.x - 1) * tileSize,
        (node.y - 1) * tileSize,
        tileSize,
        tileSize
      )
      print(i, node.x, node.y)
    end
  end

    
  --Show Turn----------
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Turn: " .. currentTurn, 10, 30)

  -- Reset the Color so future drawings aren't tinted
  love.graphics.setColor(1, 1, 1, 1)
end

