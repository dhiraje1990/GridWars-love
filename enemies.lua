local Grid = require "grid"
local Player = require "player"

local Enemies = {}
Enemies.list = {}

-- Settings
local spawn_timer = 0
local spawn_rate = 2.0 -- Spawns slower initially because new enemies are harder

-- ==========================================================
-- HELPER: SPAWN LOGIC
-- ==========================================================
function Enemies.spawn()
    -- Pick a random angle off-screen
    local angle = math.random() * math.pi * 2
    local dist = 800
    local spawn_x = 400 + math.cos(angle) * dist
    local spawn_y = 300 + math.sin(angle) * dist
  
    -- Pick a random type based on probability
    -- 60% Seeker, 25% Pinwheel, 15% Dasher
    local roll = math.random()
    local e_type = "seeker"
    
    if roll > 0.85 then
        e_type = "dasher"
    elseif roll > 0.60 then
        e_type = "pinwheel"
    end
    
    -- Define the base enemy object
    local enemy = {
        x = spawn_x,
        y = spawn_y,
        type = e_type,
        angle = 0,        -- For rotation visuals
        timer = 0         -- Generic timer for abilities (used by Dasher/Pinwheel)
    }

    -- Set stats based on Type
    if e_type == "seeker" then
        enemy.speed = 150
        enemy.radius = 15
        enemy.color = {1, 0.2, 0.2} -- Red
        
    elseif e_type == "pinwheel" then
        enemy.speed = 200 -- Faster than seeker
        enemy.radius = 12
        enemy.color = {0.2, 1, 0.2} -- Green
        
    elseif e_type == "dasher" then
        enemy.speed = 50  -- Initial slow speed
        enemy.radius = 18
        enemy.color = {1, 1, 0.2} -- Yellow
        enemy.state = "aiming" -- Dasher needs a state machine
    end
    
    table.insert(Enemies.list, enemy)
end

-- ==========================================================
-- UPDATE LOOP
-- ==========================================================
function Enemies.update(dt)
    -- 1. Spawning System
    spawn_timer = spawn_timer - dt
    if spawn_timer <= 0 then
        Enemies.spawn()
        -- Increase difficulty (spawn faster)
        spawn_rate = math.max(0.4, spawn_rate * 0.98) 
        spawn_timer = spawn_rate
    end

    -- 2. Enemy AI Logic
    for i = #Enemies.list, 1, -1 do
        local e = Enemies.list[i]
        
        -- Basic vector to player
        local dx = Player.x - e.x
        local dy = Player.y - e.y
        local dist_to_player = math.sqrt(dx*dx + dy*dy)
        local angle_to_player = math.atan2(dy, dx)
        
        -- BEHAVIOR: SEEKER (Simple Chase)
        if e.type == "seeker" then
            e.x = e.x + math.cos(angle_to_player) * e.speed * dt
            e.y = e.y + math.sin(angle_to_player) * e.speed * dt
            
            -- Rotate visual to face player
            e.angle = angle_to_player

        -- BEHAVIOR: PINWHEEL (Snake Movement)
        elseif e.type == "pinwheel" then
            -- Increase internal timer to do the math wave
            e.timer = e.timer + dt * 5 
            
            -- Calculate a perpendicular offset (Sine wave)
            -- We add math.sin(e.timer) to the angle to make it wiggle left and right
            local wiggle_angle = angle_to_player + math.sin(e.timer) * 0.5
            
            e.x = e.x + math.cos(wiggle_angle) * e.speed * dt
            e.y = e.y + math.sin(wiggle_angle) * e.speed * dt
            
            -- Spin the visual constantly
            e.angle = e.angle + 10 * dt

        -- BEHAVIOR: DASHER (Aim -> Dash -> Rest)
        elseif e.type == "dasher" then
            if e.state == "aiming" then
                -- Move very slowly towards player while aiming
                e.x = e.x + math.cos(angle_to_player) * 50 * dt
                e.y = e.y + math.sin(angle_to_player) * 50 * dt
                e.angle = angle_to_player -- Look at player
                
                -- Charge up timer
                e.timer = e.timer + dt
                if e.timer > 2.0 then -- After 2 seconds, DASH!
                    e.state = "dashing"
                    e.timer = 0
                    -- Lock in the dash direction (current angle)
                    e.dash_vx = math.cos(e.angle) * 600 -- Very fast!
                    e.dash_vy = math.sin(e.angle) * 600
                end
                
            elseif e.state == "dashing" then
                -- Move in the locked direction
                e.x = e.x + e.dash_vx * dt
                e.y = e.y + e.dash_vy * dt
                
                -- Dash for 0.5 seconds
                e.timer = e.timer + dt
                if e.timer > 0.5 then
                    e.state = "tired"
                    e.timer = 0
                end
                
            elseif e.state == "tired" then
                -- Sit still for a bit
                e.timer = e.timer + dt
                if e.timer > 1.0 then
                    e.state = "aiming" -- Restart cycle
                    e.timer = 0
                end
            end
        end

        -- Grid Gravity Effect (All enemies pull the grid slightly)
        Grid.applyForce(e.x, e.y, 40, -100 * dt)
    end
end

-- ==========================================================
-- DRAW LOOP
-- ==========================================================
function Enemies.draw()
    for _, e in ipairs(Enemies.list) do
        love.graphics.setColor(e.color)
        
        -- Save coordinate state
        love.graphics.push()
        love.graphics.translate(e.x, e.y)
        love.graphics.rotate(e.angle)
        
        if e.type == "seeker" then
            -- Draw Diamond
            love.graphics.polygon("line", 15, 0, 0, 15, -15, 0, 0, -15)
            
        elseif e.type == "pinwheel" then
            -- Draw 'X' or Pinwheel shape
            local r = e.radius
            love.graphics.line(-r, -r, r, r)
            love.graphics.line(-r, r, r, -r)
            love.graphics.rectangle("line", -r/2, -r/2, r, r)
            
        elseif e.type == "dasher" then
            -- Draw Triangle (Arrow)
            -- If dashing, draw it filled to look dangerous
            local mode = (e.state == "dashing") and "fill" or "line"
            love.graphics.polygon(mode, 15, 0, -10, 10, -10, -10)
        end
        
        love.graphics.pop()
    end
end

return Enemies