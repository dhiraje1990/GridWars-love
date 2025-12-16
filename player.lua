-- Import the Grid module so the player can interact with it
local Grid = require "grid" 

-- Define the Player table
local Player = { 
    x = 400,        -- Starting X position
    y = 300,        -- Starting Y position
    speed = 300,    -- Movement speed in pixels per second
    angle = 0,       -- Rotation angle in radians
    bombs = 3,         -- Start with 3 bombs
    bomb_cooldown = 0,  -- Prevent spamming
    weapon = "normal", -- Options: "normal", "spread", "rapid"
    weapon_timer = 0   -- How long the powerup lasts
}

-- Update function for Player
function Player.update(dt)
    -- Reduce cooldown
    if Player.bomb_cooldown > 0 then
        Player.bomb_cooldown = Player.bomb_cooldown - dt
    end

    -- Weapon Timer Logic
    if Player.weapon ~= "normal" then
        Player.weapon_timer = Player.weapon_timer - dt
        if Player.weapon_timer <= 0 then
            Player.weapon = "normal" -- Revert to default
        end
    end

    -- Variables to hold input direction
    local dx, dy = 0, 0

    -- Check Keyboard Input
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end     -- Up is Negative Y
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end   -- Down is Positive Y
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end   -- Left is Negative X
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end  -- Right is Positive X

    -- Check if we are moving (dx or dy is not 0)
    if dx ~= 0 or dy ~= 0 then
        -- Normalize the vector:
        -- If we hold Up+Right, length is roughly 1.41. We divide by length to make speed = 1.
        local length = math.sqrt(dx*dx + dy*dy)
        dx = dx / length
        dy = dy / length
        
        -- Update position based on direction, speed, and delta time
        Player.x = Player.x + dx * Player.speed * dt
        Player.y = Player.y + dy * Player.speed * dt
        
        -- Create a "wake" behind the ship by pushing the grid slightly
        Grid.applyForce(Player.x, Player.y, 80, 1500 * dt)
    end

    -- Calculate Angle: Look at the Mouse
    local mx, my = love.mouse.getPosition()
    -- atan2 gives us the angle in radians between two points
    Player.angle = math.atan2(my - Player.y, mx - Player.x)
end

-- Draw function for Player
function Player.draw()
    love.graphics.push() -- Save the current coordinate system
    
    -- Move the "camera" (origin) to the player's position
    love.graphics.translate(Player.x, Player.y)
    
    -- Rotate the coordinate system to match player angle
    love.graphics.rotate(Player.angle)
    
    -- Set color to Neon Pink
    love.graphics.setColor(1, 0, 0.5, 1) 
    
    -- Draw a triangle centered at (0,0) relative to the translation above
    -- Points: (Nose), (Back Left), (Back Right)
    love.graphics.polygon("line", 15, 0, -10, -10, -10, 10)
    
    love.graphics.pop() -- Restore the coordinate system to normal
end

function Player.setWeapon(type, duration)
    Player.weapon = type
    Player.weapon_timer = duration
end

return Player