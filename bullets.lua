-- Import dependencies
local Grid = require "grid"
local Player = require "player" -- We need to know where the Player is to spawn bullets

local Bullets = {}

-- A list to hold all active bullet objects
Bullets.list = {} 

-- Configuration
local bullet_speed = 600
local fire_rate = 0.15 -- Time in seconds between shots
local fire_timer = 0   -- Countdown timer for the next shot

function Bullets.update(dt)
    -- 1. Firing Logic
    fire_timer = fire_timer - dt
    
    if love.mouse.isDown(1) and fire_timer <= 0 then
        -- DETERMINE WEAPON BEHAVIOR
        
        if Player.weapon == "normal" then
            table.insert(Bullets.list, {
                x = Player.x, y = Player.y, 
                dx = math.cos(Player.angle), dy = math.sin(Player.angle),
                life = 2.0
            })
            fire_rate = 0.15 -- Standard speed
            
        elseif Player.weapon == "rapid" then
            -- Fires straight, but very fast
            table.insert(Bullets.list, {
                x = Player.x, y = Player.y, 
                dx = math.cos(Player.angle), dy = math.sin(Player.angle),
                life = 2.0
            })
            fire_rate = 0.05 -- Machine gun speed!
            
        elseif Player.weapon == "spread" then
            -- Fires 3 bullets: Center, Left -15deg, Right +15deg
            local angles = {0, -0.25, 0.25} -- Radians
            
            for _, offset in ipairs(angles) do
                local a = Player.angle + offset
                table.insert(Bullets.list, {
                    x = Player.x, y = Player.y, 
                    dx = math.cos(a), dy = math.sin(a),
                    life = 1.5 -- Short range shotgun
                })
            end
            fire_rate = 0.20 -- Slightly slower fire rate
        end

        -- Recoil for all weapons
        Grid.applyForce(Player.x, Player.y, 20, 100)
        
        -- Reset timer
        fire_timer = fire_rate
    end

    -- 2. Update Bullets (Keep existing movement code...)
    for i = #Bullets.list, 1, -1 do
        local b = Bullets.list[i]
        b.x = b.x + b.dx * bullet_speed * dt
        b.y = b.y + b.dy * bullet_speed * dt
        b.life = b.life - dt
        if b.life <= 0 then table.remove(Bullets.list, i) end
    end
end

function Bullets.draw()
    -- Set color to Yellow
    love.graphics.setColor(1, 1, 0.4, 1)
    love.graphics.setLineWidth(3)
    
    -- Loop through all bullets
    for _, b in ipairs(Bullets.list) do
        -- Draw a short line behind the bullet to simulate motion blur/laser
        love.graphics.line(b.x, b.y, b.x - b.dx * 10, b.y - b.dy * 10)
    end
end

return Bullets