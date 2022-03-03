local gfx = playdate.graphics
local x = 0

-- 0 is fully outside, 1 fully inside
local controlRodPosition = 0
local controlRodSpeed = 0.5
local reactorfloor = 200
local reactormiddle = 175

gfx.setColor(gfx.kColorBlack)

function playdate.update()
    
    gfx.fillRect(0, 220, 400*(controlRodPosition), 240)
    --playdate.drawFPS(0,0)
end

function playdate.cranked(change)
    gfx.clear()

    local newRodPosition = controlRodPosition + change/360 * controlRodSpeed
    controlRodPosition = math.max(0,math.min(1, newRodPosition))

    gfx.drawText("*" .. change .. "*", 4, 4)
    gfx.drawText("*" .. controlRodPosition .. "*", 4, 20)
end
