-- ==========================================================
-- TEXTS MODULE
-- Handles floating score numbers (Popups)
-- ==========================================================
local Texts = {}
Texts.list = {}

-- Settings
local float_speed = 40  -- How fast text floats up
local fade_speed = 1.5  -- How fast text disappears

-- Spawn a new text popup
function Texts.spawn(x, y, amount, multiplier)
    local str = tostring(amount)
    
    -- If we have a multiplier > 1, show it! (e.g., "100 x2")
    if multiplier > 1 then
        str = str .. " x" .. multiplier
    end

    table.insert(Texts.list, {
        x = x,
        y = y,
        text = str,
        life = 1.0, -- visible for 1 second
        color = {1, 1, 1, 1}, -- Start White
        scale = 1.0 + (multiplier * 0.1) -- Higher multiplier = Bigger text
    })
end

function Texts.update(dt)
    for i = #Texts.list, 1, -1 do
        local t = Texts.list[i]
        
        -- Float Up
        t.y = t.y - float_speed * dt
        
        -- Fade Out (Reduce Alpha)
        t.life = t.life - dt
        t.color[4] = t.life -- Apply life to Alpha channel
        
        -- Remove if invisible
        if t.life <= 0 then
            table.remove(Texts.list, i)
        end
    end
end

function Texts.draw()
    for _, t in ipairs(Texts.list) do
        love.graphics.setColor(t.color)
        
        -- Draw text centered
        -- We scale it based on the combo multiplier
        local scale = t.scale
        
        -- Default font in LÖVE is roughly 12px high
        -- We offset by X and Y to center it
        love.graphics.print(t.text, t.x, t.y, 0, scale, scale, 10, 6)
    end
end

return Texts