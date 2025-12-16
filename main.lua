-- ==========================================================
-- LOAD MODULES
-- ==========================================================
-- We import all our separate game components here
local Grid = require "grid"
local Player = require "player"
local Bullets = require "bullets"
local Enemies = require "enemies"
local Particles = require "particles"
local Camera = require "camera"
local Texts = require "texts"    
local Pickups = require "pickups"


-- ==========================================================
-- GAME STATE VARIABLES
-- ==========================================================

local score = 0
local multiplier = 1
local multiplier_timer = 0
local multiplier_limit = 2.0 -- You have 2 seconds to kill another enemy to keep the combo
local game_over = false    
local screen_flash = 0 -- 0 = transparent, 1 = full white


-- ==========================================================
-- LOVE: LOAD
-- Run once at startup
-- ==========================================================
function love.load()
    Grid.load() -- Initialize the background grid points
end

-- ==========================================================
-- LOVE: UPDATE
-- Run every frame (dt = time since last frame)
-- ==========================================================
function love.update(dt)
    -- Game Over Logic
    -- If the game is over, we stop updating the world.
    -- We only listen for the 'R' key to restart.
    if game_over then
        if love.keyboard.isDown("r") then
            resetGame()
        end
        return -- EXIT the function here (don't run code below)
    end

    -- Bomb Input
    if love.keyboard.isDown("space") then
        triggerBomb()
    end

    -- Update Flash (Fade out quickly)
    if screen_flash > 0 then
        screen_flash = screen_flash - 3.0 * dt -- Fade out in ~0.3 seconds
        if screen_flash < 0 then screen_flash = 0 end
    end

    -- Update All Subsystems
    -- Pass 'dt' to everyone so movement is smooth regardless of framerate
    Camera.update(dt) -- Fade out screen shake
    Grid.update(dt)
    Player.update(dt)
    Bullets.update(dt)
    Enemies.update(dt)
    Particles.update(dt)
    Texts.update(dt)
    Pickups.update(dt)
    checkCollisions() -- Check for interactions (collisions)
end

-- ==========================================================
-- LOVE: DRAW
-- Run every frame to render graphics
-- ==========================================================
function love.draw()
    -- 1. Apply "Neon" Glow
    -- Additive blending makes overlapping colors get brighter (simulating light)
    love.graphics.setBlendMode("add")
    
    -- 2. Apply Camera Shake
    -- Everything drawn AFTER this line will be shaken
    Camera.set() 
    
        -- Draw the game world
        Grid.draw()
        Particles.draw()
        Player.draw()
        Bullets.draw()
        Enemies.draw()
        Texts.draw() -- Draw floating text inside the world (so it shakes too!)
        Pickups.draw() -- Draw the pickup weapons

    -- 3. Remove Camera Shake
    -- We unset the camera so the UI (Score/Game Over text) stays still
    Camera.unset()

    -- === DRAW SCREEN FLASH ===
    -- Draw a full-screen white rectangle with transparency based on 'screen_flash'
    if screen_flash > 0 then
        love.graphics.setColor(1, 1, 1, screen_flash)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    
    -- Draw UI (User Interface)
    -- Switch back to normal Alpha blending so text looks crisp, not glowing/transparent
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1) -- Set color to White
    love.graphics.print("Score: " .. score, 10, 10)

    -- Draw Bomb Ammo (Under Score)
    love.graphics.print("Bombs: ", 10, 70)
    for i = 1, Player.bombs do
        -- Draw little circles for bombs
        love.graphics.setColor(1, 0, 0, 1) -- Red
        love.graphics.circle("fill", 60 + (i * 15), 78, 5)
    end
    
    -- Draw Score in top-left
    love.graphics.print("Score: " .. score, 10, 10)
    
    -- Draw FPS (Frames Per Second) for debugging
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 30)

    -- Draw Multiplier UI
    if multiplier > 1 then
        love.graphics.setColor(1, 1, 0, 1) -- Yellow
        love.graphics.print("Combo: " .. multiplier .. "x", 10, 30)
        -- Draw a little bar showing how much time is left
        local bar_width = 100 * (multiplier_timer / multiplier_limit)
        love.graphics.rectangle("fill", 10, 50, bar_width, 5)
    end

    -- Draw Game Over Screen if needed
    if game_over then
        love.graphics.push() -- Save transform
        love.graphics.scale(2, 2) -- Make text 2x bigger
        love.graphics.print("GAME OVER", 150, 130)
        love.graphics.scale(0.5, 0.5) -- Reset scale logic manually for next line (0.5 * 2 = 1)
        love.graphics.print("Press 'R' to Restart", 320, 290)
        love.graphics.pop() -- Restore transform
    end
end

-- ==========================================================
-- COLLISION LOGIC
-- Handles interactions between objects
-- ==========================================================
function checkCollisions()
    local enemies = Enemies.list
    local bullets = Bullets.list
    local pickups = Pickups.list -- Don't forget this if you added Pickups

    -- LOOP 1: Enemies vs Bullets
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        
        -- CRITICAL: This must be reset to false for EVERY enemy
        local enemyDead = false 
        
        -- Check collisions with Bullets
        for j = #bullets, 1, -1 do
            local b = bullets[j]
            local dist = math.sqrt((e.x - b.x)^2 + (e.y - b.y)^2)
            
            if dist < e.radius + 5 then
                enemyDead = true
                table.remove(bullets, j)
                break -- Bullet hit, stop checking other bullets
            end
        end
        
        -- If THIS specific enemy died
        if enemyDead then
            -- Effects
            Grid.applyForce(e.x, e.y, 150, 1200)
            Particles.spawn(e.x, e.y, e.color)
            Camera.addShake(15)
            
            -- Score Logic
            local base_score = 100
            score = score + (base_score * multiplier)
            Texts.spawn(e.x, e.y, base_score, multiplier)
            
            multiplier = multiplier + 1
            multiplier_timer = multiplier_limit
            
            -- Attempt to spawn Pickup
            if Pickups then Pickups.spawn(e.x, e.y) end
            
            -- Remove the enemy
            table.remove(enemies, i)
        end
    end

    -- LOOP 2: Player vs Enemies (Game Over)
    for _, e in ipairs(enemies) do
        local dist = math.sqrt((Player.x - e.x)^2 + (Player.y - e.y)^2)
        if dist < 25 then
            game_over = true
            Grid.applyForce(Player.x, Player.y, 300, 2000)
            Particles.spawn(Player.x, Player.y, {1, 1, 1})
            Camera.addShake(40)
        end
    end

    -- LOOP 3: Player vs Pickups
    if Pickups then
        for i = #pickups, 1, -1 do
            local p = pickups[i]
            local dist = math.sqrt((Player.x - p.x)^2 + (Player.y - p.y)^2)
            
            if dist < 25 then
                Player.setWeapon(p.type, 5.0)
                Texts.spawn(Player.x, Player.y - 30, string.upper(p.type).."!", 1.5)
                Particles.spawn(p.x, p.y, p.color)
                table.remove(pickups, i)
            end
        end
    end
end

-- ==========================================================
-- RESET LOGIC
-- Restores game to initial state
-- ==========================================================
function resetGame()
    score = 0
    multiplier = 1 
    multiplier_timer = 0
    game_over = false
    
    -- Clear all tables
    Enemies.list = {}
    Bullets.list = {}
    Particles.list = {}
    Texts.list = {}          -- Clear floating texts
    
    -- Reset Player to center
    Player.x = 400
    Player.y = 300
    
    -- Reset player weapons
    Player.weapon = "normal"
    Pickups.list = {}
    -- Reset Grid springs
    Grid.load() 
end

function triggerBomb()
    if Player.bombs > 0 and Player.bomb_cooldown <= 0 then
        Player.bombs = Player.bombs - 1
        Player.bomb_cooldown = 1.0 -- 1 second delay between bombs
        
        -- 1. Visuals: Massive Grid Warp
        -- We apply a huge force at the player's position
        Grid.applyForce(Player.x, Player.y, 800, 5000)
        
        -- 2. Visuals: Screen Shake & Flash
        Camera.addShake(40)
        screen_flash = 1.0 -- Set flash to full white
        
        -- 3. Gameplay: Kill ALL Enemies
        local enemies = Enemies.list
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            
            -- Spawn particles for every enemy
            Particles.spawn(e.x, e.y, e.color)
            
            -- Give score (but no combo increase for bombs, typically)
            score = score + 50
            
            table.remove(enemies, i)
        end
        
        -- 4. Gameplay: Clear all bullets (optional, but fair)
        Bullets.list = {}
    end
end