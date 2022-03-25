import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx = playdate.graphics

-- 0 is fully outside, 1 fully inside
local accumulatedNumber = 8
local controlRodSpeed = 1
local reactorfloor = 200
local reactormiddle = 175
local baseNumber = 10
local maximum = 1024

local lastDigitStart = {x = 352, y = 115}
local digitGap = 4
local digitHeight = 60


local function createDigit(x,y, power)
   
   local image = playdate.graphics.image.new('images/decimal')
   
   local digit = gfx.sprite.new()
   digit:setZIndex(800 + power)
   digit:setImage(image)
   digit:moveTo(x, y)
   digit:add()
    
    local shadowBehind = gfx.sprite.new()
    shadowBehind:setZIndex(900 + power)
    shadowBehind:setImage(image)
    shadowBehind:moveTo(x, y + digitHeight)
    shadowBehind:add()

   
   function digit:update()
       local value = (accumulatedNumber/(baseNumber ^ power)) % baseNumber
       local newCenter = value / baseNumber
       digit:setCenter(0.5, newCenter)
       shadowBehind:setCenter(0.5, ( value - baseNumber +1) / baseNumber)
   end
   return digit
 
end

local function createForeground()
    local foreground = gfx.sprite.new()
    foreground:setZIndex(1000)
    foreground:setImage(playdate.graphics.image.new('images/counter'))
    foreground:moveTo(200, 120)
    foreground:add()
end

local function createDigits()
    local image = playdate.graphics.image.new('images/decimal')
    local width, h = image:getSize()
    
    for power = 0, 7, 1
    do
        local xPos = lastDigitStart.x - power * width - power * digitGap + width / 2
       createDigit(xPos, lastDigitStart.y, power)
    end
end

createDigits()
createForeground()

function playdate.update()
    gfx.sprite.update()
    playdate.drawFPS(0,0)
end

function playdate.cranked(change)
    local newRodPosition = accumulatedNumber + change/360 * controlRodSpeed
    accumulatedNumber = math.max(0,math.min(maximum or 1, newRodPosition))
    -- print("accumulatedNumber " .. accumulatedNumber)
    
    -- gfx.drawText("*" .. change .. "*", 4, 4)
    -- gfx.drawText("*" .. accumulatedNumber .. "*", 4, 20)
    
end

function playdate.gameWillTerminate()

end

function playdate.deviceWillSleep()

end

function saveState()

end

function playdate.gameWillResume()

end