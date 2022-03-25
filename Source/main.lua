import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx = playdate.graphics

-- 0 is fully outside, 1 fully inside
local accumulatedNumber = 0
local controlRodSpeed = 0.5
local reactorfloor = 200
local reactormiddle = 175
local baseNumber = 10
local maximum = 1024


local function createDigit(x,y)
   
   local digit = gfx.sprite.new()
   
    digit:setZIndex(800)
       
    digit:setImage(playdate.graphics.image.new('images/decimal'))
    digit:moveTo(x, y)
    digit:add()
   
   function digit:update()
       local value = ( accumulatedNumber % baseNumber ) / baseNumber + 0.05
       print("value " .. value)
       digit:setCenter(0.5, value)
   end
   return digit
 
end

createDigit(100, 100)

function playdate.update()
    gfx.sprite.update()
    playdate.drawFPS(0,0)
end

function playdate.cranked(change)
    -- gfx.clear()

    local newRodPosition = accumulatedNumber + change/360 * controlRodSpeed
    accumulatedNumber = math.max(0,math.min(maximum or 1, newRodPosition))
    print("accumulatedNumber " .. accumulatedNumber)
    -- digit.updateClone(accumulatedNumber)
    
    gfx.drawText("*" .. change .. "*", 4, 4)
    gfx.drawText("*" .. accumulatedNumber .. "*", 4, 20)
    
end

function playdate.gameWillTerminate()

end

function playdate.deviceWillSleep()

end

function saveState()

end

function playdate.gameWillResume()

end