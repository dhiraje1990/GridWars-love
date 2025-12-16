-- ==========================================================
-- CAMERA MODULE
-- Handles screen shake and coordinate transformations.
-- ==========================================================
local Camera = {}

-- The current amount of "trauma" or shake intensity
Camera.shake_amount = 0

-- Configuration: How fast the shake settles down
-- 0.9 = fast decay, 0.99 = slow decay
Camera.decay = 0.95

-- Function to add shake (Call this when explosions happen)
-- intensity: A number between 0 (none) and 100 (violent)
function Camera.addShake(intensity)
    -- Add the new intensity to the existing shake
    Camera.shake_amount = Camera.shake_amount + intensity
    
    -- Cap the maximum shake so the game doesn't become unplayable
    if Camera.shake_amount > 50 then
        Camera.shake_amount = 50
    end
end

-- Update function (call every frame)
function Camera.update(dt)
    -- Slowly reduce the shake amount over time (Linear Interpolation or simple multiplication)
    -- This makes the shake "fade out" smoothly instead of stopping instantly
    Camera.shake_amount = Camera.shake_amount * Camera.decay
    
    -- If shake is very small, just set it to 0 to stop micro-jittering
    if Camera.shake_amount < 0.1 then
        Camera.shake_amount = 0
    end
end

-- Call this BEFORE drawing the game world
function Camera.set()
    -- Save the current graphics state (so we can undo the shake later)
    love.graphics.push()
    
    -- Calculate random offsets based on the current shake amount
    -- math.random() returns 0.0 to 1.0
    -- We subtract 0.5 to get -0.5 to 0.5
    -- Then multiply by shake_amount * 2 to get a range of [-shake, +shake]
    local dx = (math.random() - 0.5) * Camera.shake_amount * 2
    local dy = (math.random() - 0.5) * Camera.shake_amount * 2
    
    -- Move the entire drawing coordinate system by this random amount
    love.graphics.translate(dx, dy)
end

-- Call this AFTER drawing the game world (but BEFORE drawing UI)
function Camera.unset()
    -- Restore the graphics state to normal (0,0 at top-left)
    love.graphics.pop()
end

return Camera