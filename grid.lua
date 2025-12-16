-- Create a table to hold all our Grid functions and data
local Grid = {}

-- ==========================================================
-- CONFIGURATION
-- ==========================================================
local CONFIG = {
    cell_size = 40,             -- The width/height of each square in pixels
    stiffness = 80,             -- Spring tension: High = snaps back fast, Low = loose/wobbly
    damping = 0.9,              -- Friction: 0.0 = wobbles forever, 1.0 = no movement. 0.9 is good air resistance.
    line_width = 2,             -- Thickness of the grid lines
    grid_color = {0.2, 0.2, 1, 0.8} -- The color in (Red, Green, Blue, Alpha) format. This is Neon Blue.
}

-- Storage for the grid points
Grid.points = {} 
Grid.cols = 0
Grid.rows = 0

-- Function to initialize the grid (called once at startup)
function Grid.load()
    -- Get the width and height of the game window
    local width, height = love.graphics.getDimensions()
    
    -- Calculate how many columns/rows we need to fill the screen
    -- We add +2 to ensure the grid extends slightly off-screen so we don't see the edges
    Grid.cols = math.ceil(width / CONFIG.cell_size) + 2
    Grid.rows = math.ceil(height / CONFIG.cell_size) + 2

    -- Loop through every row (y)
    for y = 1, Grid.rows do
        -- Create a new empty table for this row
        Grid.points[y] = {}
        
        -- Loop through every column (x)
        for x = 1, Grid.cols do
            -- Calculate the pixel position based on the column index and cell size
            local px = (x - 1) * CONFIG.cell_size
            local py = (y - 1) * CONFIG.cell_size
            
            -- Store the point data
            Grid.points[y][x] = {
                x = px,         -- The CURRENT x position (this will change when warping)
                y = py,         -- The CURRENT y position
                tx = px,        -- The TARGET x position (where it wants to return to)
                ty = py,        -- The TARGET y position
                vx = 0,         -- Velocity X (speed of movement)
                vy = 0          -- Velocity Y
            }
        end
    end
end

-- Function to update physics (called every frame)
function Grid.update(dt)
    -- Iterate through every point in the grid
    for y = 1, Grid.rows do
        for x = 1, Grid.cols do
            local p = Grid.points[y][x]

            -- PHYSICS: Hooke's Law (Spring Force)
            -- Calculate how far the point is from its target (displacement)
            -- Multiply by stiffness to get the pulling force
            local forceX = (p.tx - p.x) * CONFIG.stiffness
            local forceY = (p.ty - p.y) * CONFIG.stiffness

            -- Apply the force to the velocity (Velocity = Velocity + Force * DeltaTime)
            p.vx = p.vx + forceX * dt
            p.vy = p.vy + forceY * dt

            -- Apply Damping (Friction)
            -- Reduce velocity slightly every frame so it eventually stops moving
            p.vx = p.vx * CONFIG.damping
            p.vy = p.vy * CONFIG.damping

            -- Apply Velocity to Position (Position = Position + Velocity * DeltaTime)
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
        end
    end
end

-- Function to create an explosion or push effect
function Grid.applyForce(x, y, radius, force)
    -- Loop through all grid points
    -- (In a massive game, you would optimize this to only check nearby points)
    for r = 1, Grid.rows do
        for c = 1, Grid.cols do
            local p = Grid.points[r][c]
            
            -- Calculate distance between the explosion center (x,y) and this point (p.x, p.y)
            local dx = p.x - x
            local dy = p.y - y
            local distSq = dx*dx + dy*dy -- Squared distance is faster (avoids square root for now)
            
            -- Check if the point is inside the blast radius
            if distSq < radius * radius then
                local dist = math.sqrt(distSq) -- Now we need the actual distance
                
                -- Calculate percentage: 1.0 (100%) at center, 0.0 (0%) at the edge of radius
                local pct = 1 - (dist / radius) 
                
                -- Avoid dividing by zero if the explosion is exactly on top of a point
                if dist > 0 then
                    -- Apply velocity to the point pushing it AWAY from the center
                    p.vx = p.vx + (dx / dist) * force * pct
                    p.vy = p.vy + (dy / dist) * force * pct
                end
            end
        end
    end
end

-- Function to draw the lines
function Grid.draw()
    -- Set the color and line thickness
    love.graphics.setColor(CONFIG.grid_color)
    love.graphics.setLineWidth(CONFIG.line_width)

    -- Loop through points
    for y = 1, Grid.rows do
        for x = 1, Grid.cols do
            local p = Grid.points[y][x]

            -- Draw a horizontal line to the neighbor on the RIGHT
            if x < Grid.cols then
                local pRight = Grid.points[y][x+1]
                love.graphics.line(p.x, p.y, pRight.x, pRight.y)
            end

            -- Draw a vertical line to the neighbor BELOW
            if y < Grid.rows then
                local pDown = Grid.points[y+1][x]
                love.graphics.line(p.x, p.y, pDown.x, pDown.y)
            end
        end
    end
end

-- Return the table so other files can use it
return Grid