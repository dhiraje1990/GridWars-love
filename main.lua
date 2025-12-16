-- ==========================================================
-- LOAD MODULES
-- ==========================================================
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
local high_score = 0
local high_score_name = "CPU" -- NEW: Who holds the high score?

local player_name = ""        -- NEW: Buffer for typing name
local entering_name = false   -- NEW: State for name entry mode

local multiplier = 1
local multiplier_timer = 0
local multiplier_limit = 2.0
local game_over = false
local paused = false
local screen_flash = 0

-- ==========================================================
-- SAVE/LOAD SYSTEM (UPDATED)
-- ==========================================================
function loadHighScore()
    if love.filesystem.getInfo("highscore.txt") then
        local content = love.filesystem.read("highscore.txt")
        
        -- We split the string "Name|Score"
        -- This pattern looks for anything before a pipe (|) and digits after it
        local name, scr = content:match("^(.*)|(%d+)$")
        
        if name and scr then
            high_score_name = name
            high_score = tonumber(scr)
        end
    end
end

function saveHighScore()
    -- Save format: "Name|Score"
    local data = high_score_name .. "|" .. tostring(high_score)
    love.filesystem.write("highscore.txt", data)
end

-- ==========================================================
-- LOVE: LOAD
-- ==========================================================
function love.load()
    Grid.load()
    loadHighScore()
    print("Save Directory: " .. love.filesystem.getSaveDirectory())
end

-- ==========================================================
-- LOVE: INPUT HANDLING (NEW)
-- ==========================================================

-- Called when the user types a character (e.g. "a", "B", "1")
function love.textinput(t)
    if entering_name then
        -- Limit name to 12 characters
        if #player_name < 12 then
            player_name = player_name .. t
        end
    end
end

-- Called for special keys (Enter, Backspace, etc.)
function love.keypressed(key)
    if entering_name then
        if key == "backspace" then
            -- Remove the last character
            -- (Note: string.sub(s, 1, -2) keeps everything except last char)
            player_name = string.sub(player_name, 1, -2)
            
        elseif key == "return" then
            -- CONFIRM NAME
            high_score = score
            high_score_name = player_name
            
            if high_score_name == "" then high_score_name = "Anonymous" end
            
            saveHighScore()
            entering_name = false -- Return to standard Game Over screen
        end
        return -- Stop processing other keys while typing
    end

    -- Normal Keys
    if key == "p" or key == "escape" then
        if not game_over and not entering_name then
            paused = not paused
        end
    end
end

-- ==========================================================
-- LOVE: UPDATE
-- ==========================================================
function love.update(dt)
    if paused then return end

    if game_over then
        -- If we are entering a name, do NOT allow restarting yet
        if not entering_name and love.keyboard.isDown("r") then 
            resetGame() 
        end
        return
    end
    
    -- Inputs
    if love.keyboard.isDown("space") then triggerBomb() end
    
    -- Timers
    if multiplier > 1 then
        multiplier_timer = multiplier_timer - dt
        if multiplier_timer <= 0 then multiplier = 1 end
    end
    
    if screen_flash > 0 then
        screen_flash = screen_flash - 3.0 * dt
        if screen_flash < 0 then screen_flash = 0 end
    end

    -- Updates
    Camera.update(dt)
    Grid.update(dt)
    Player.update(dt)
    Bullets.update(dt)
    Enemies.update(dt)
    Particles.update(dt)
    Texts.update(dt)
    Pickups.update(dt)
    
    checkCollisions()
end

-- ==========================================================
-- LOVE: DRAW
-- ==========================================================
function love.draw()
    love.graphics.setBlendMode("add")
    
    Camera.set() 
        Grid.draw()
        Pickups.draw()
        Particles.draw()
        Player.draw()
        Bullets.draw()
        Enemies.draw()
        Texts.draw()
    Camera.unset()
    
    -- Screen Flash
    if screen_flash > 0 then
        love.graphics.setColor(1, 1, 1, screen_flash)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    
    -- UI
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Score UI
    love.graphics.print("Score: " .. score, 10, 10)
    love.graphics.print("Best:  " .. high_score .. " (" .. high_score_name .. ")", 10, 30)
    
    if multiplier > 1 then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print("Combo: " .. multiplier .. "x", 10, 50)
        local bar_width = 100 * (multiplier_timer / multiplier_limit)
        love.graphics.rectangle("fill", 10, 70, bar_width, 5)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Bombs: ", 10, 90)
    for i = 1, Player.bombs do
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.circle("fill", 60 + (i * 15), 98, 5)
    end
    
    -- PAUSE MENU
    if paused then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("PAUSED", 350, 250)
    end

    -- GAME OVER & NAME ENTRY UI
    if game_over then
        love.graphics.setColor(0, 0, 0, 0.8) -- Darken background for readability
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.scale(2, 2)
        love.graphics.print("GAME OVER", 150, 100)
        love.graphics.scale(0.5, 0.5)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Final Score: " .. score, 350, 260)
        
        -- NEW: NAME ENTRY BOX
        if entering_name then
            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.print("NEW HIGH SCORE!", 340, 300)
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("Enter Name:", 360, 330)
            
            -- Draw Input Box
            love.graphics.rectangle("line", 300, 350, 200, 30)
            
            -- Draw Typed Name (with a blinking cursor effect)
            local cursor = (love.timer.getTime() % 1 > 0.5) and "|" or ""
            love.graphics.print(player_name .. cursor, 310, 358)
            
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.print("Press ENTER to Confirm", 325, 400)
            
        else
            -- Standard Game Over Options
            if score >= high_score and score > 0 then
                love.graphics.setColor(1, 1, 0, 1)
                love.graphics.print("High Score: " .. high_score_name, 340, 300)
            end
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("Press 'R' to Restart", 330, 350)
        end
    end
end

-- ==========================================================
-- BOMB LOGIC
-- ==========================================================
function triggerBomb()
    if Player.bombs > 0 and Player.bomb_cooldown <= 0 then
        Player.bombs = Player.bombs - 1
        Player.bomb_cooldown = 1.0
        
        Grid.applyForce(Player.x, Player.y, 800, 5000)
        Camera.addShake(40)
        screen_flash = 1.0
        
        local enemies = Enemies.list
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            Particles.spawn(e.x, e.y, e.color)
            score = score + 50
            table.remove(enemies, i)
        end
        Bullets.list = {}
    end
end

-- ==========================================================
-- COLLISION LOGIC
-- ==========================================================
function checkCollisions()
    local enemies = Enemies.list
    local bullets = Bullets.list
    local pickups = Pickups.list

    -- 1. Bullets vs Enemies
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        local enemyDead = false
        
        for j = #bullets, 1, -1 do
            local b = bullets[j]
            if (e.x - b.x)^2 + (e.y - b.y)^2 < (e.radius + 5)^2 then
                enemyDead = true
                table.remove(bullets, j)
                break
            end
        end
        
        if enemyDead then
            Grid.applyForce(e.x, e.y, 150, 1200)
            Particles.spawn(e.x, e.y, e.color)
            Camera.addShake(15)
            
            local base_score = 100
            score = score + (base_score * multiplier)
            Texts.spawn(e.x, e.y, base_score, multiplier)
            
            multiplier = multiplier + 1
            multiplier_timer = multiplier_limit
            
            Pickups.spawn(e.x, e.y)
            table.remove(enemies, i)
        end
    end

    -- 2. Player vs Enemies (Death Logic UPDATED)
    for _, e in ipairs(enemies) do
        if (Player.x - e.x)^2 + (Player.y - e.y)^2 < 25^2 then
            
            -- Trigger visual death effects
            Grid.applyForce(Player.x, Player.y, 300, 2000)
            Particles.spawn(Player.x, Player.y, {1, 1, 1})
            Camera.addShake(40)
            
            game_over = true
            
            -- NEW: Check if we need to enter name
            if score > high_score then
                entering_name = true
                player_name = "" -- Reset input buffer
            else
                entering_name = false
            end
        end
    end
    
    -- 3. Player vs Pickups
    for i = #pickups, 1, -1 do
        local p = pickups[i]
        if (Player.x - p.x)^2 + (Player.y - p.y)^2 < 25^2 then
            Player.setWeapon(p.type, 5.0)
            Texts.spawn(Player.x, Player.y - 30, string.upper(p.type).."!", 1.5)
            Particles.spawn(p.x, p.y, p.color)
            table.remove(pickups, i)
        end
    end
end

-- ==========================================================
-- RESET
-- ==========================================================
function resetGame()
    -- Only save here if we aren't in name entry mode (standard restart)
    if score > high_score and not entering_name then
        saveHighScore()
    end

    score = 0
    multiplier = 1
    multiplier_timer = 0
    game_over = false
    paused = false
    entering_name = false
    player_name = ""
    
    Enemies.list = {}
    Bullets.list = {}
    Particles.list = {}
    Texts.list = {}
    Pickups.list = {}
    
    Player.x = 400
    Player.y = 300
    Player.bombs = 3
    Player.weapon = "normal"
    
    Grid.load() 
end