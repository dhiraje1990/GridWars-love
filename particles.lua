-- ==========================================================
-- PARTICLES MODULE
-- Handles explosion effects (sparks)
-- ==========================================================
local Particles = {}
Particles.list = {} -- Stores all active particle data

-- Settings
local friction = 0.95 -- How fast particles slow down (air resistance)

-- Function to spawn an explosion
-- x, y: Position of explosion
-- color: A table like {1, 0, 0} for red
function Particles.spawn(x, y, color)
    -- Spawn 15 particles per explosion
    for i = 1, 15 do
        -- Random angle and speed for each spark
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 200) -- Random speed between 50 and 200
        
        table.insert(Particles.list, {
            x = x,
            y = y,
            dx = math.cos(angle) * speed, -- Velocity X
            dy = math.sin(angle) * speed, -- Velocity Y
            life = math.random(0.5, 1.0), -- Live for 0.5 to 1.0 seconds
            size = math.random(2, 4),     -- Random size
            color = color or {1, 1, 1}    -- Default to white if no color provided
        })
    end
end

-- Update Loop
function Particles.update(dt)
    -- Iterate backwards because we are removing items
    for i = #Particles.list, 1, -1 do
        local p = Particles.list[i]
        
        -- Move the particle
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        
        -- Apply Friction (slow down over time)
        p.dx = p.dx * friction
        p.dy = p.dy * friction
        
        -- Shrink the particle as it dies
        p.size = p.size * 0.95
        
        -- Reduce life timer
        p.life = p.life - dt
        
        -- Remove if dead
        if p.life <= 0 then
            table.remove(Particles.list, i)
        end
    end
end

-- Draw Loop
function Particles.draw()
    for _, p in ipairs(Particles.list) do
        -- Set the color (R, G, B, Alpha)
        -- We make Alpha equal to 'life' so it fades out smoothly
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.life)
        
        -- Draw a small square for the spark
        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end
end

return Particles