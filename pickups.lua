local Pickups = {}
Pickups.list = {}

-- Settings
local size = 20

function Pickups.spawn(x, y)
    -- 10% Chance to spawn a pickup when enemy dies
    if math.random() > 0.10 then return end
    
    local type = "spread"
    local color = {0, 1, 1} -- Cyan
    
    -- 50/50 chance between Rapid and Spread
    if math.random() > 0.5 then
        type = "rapid"
        color = {1, 0.6, 0} -- Orange
    end
    
    table.insert(Pickups.list, {
        x = x,
        y = y,
        type = type,
        color = color,
        life = 10.0, -- Disappears after 10 seconds if not picked up
        angle = 0
    })
end

function Pickups.update(dt)
    for i = #Pickups.list, 1, -1 do
        local p = Pickups.list[i]
        
        -- Spin visuals
        p.angle = p.angle + 2 * dt
        p.life = p.life - dt
        
        -- Blink when about to disappear
        if p.life < 2 then
            p.color[4] = math.abs(math.sin(p.life * 10)) -- Flicker alpha
        end
        
        if p.life <= 0 then
            table.remove(Pickups.list, i)
        end
    end
end

function Pickups.draw()
    for _, p in ipairs(Pickups.list) do
        love.graphics.setColor(p.color)
        
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.rotate(p.angle)
        
        -- Draw a hollow square
        love.graphics.rectangle("line", -size/2, -size/2, size, size)
        -- Draw a smaller solid square inside
        love.graphics.rectangle("fill", -size/4, -size/4, size/2, size/2)
        
        love.graphics.pop()
    end
end

return Pickups