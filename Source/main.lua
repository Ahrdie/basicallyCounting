import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/math"

local gfx = playdate.graphics

local accumulatedNumber = 0
local crankSpeed = 1
local baseSelection = 2
local base = {10,2}
local maximum = 1024
local accumulationChange = 0

local lastDigitStart = {x = 352, y = 115}
local digitGap = 5
local digitHeight = 60

local speed = 0

local function createDigit(x,y, power)
   local baseNumber = base[baseSelection]
   local digit = gfx.sprite.new()
   digit:setZIndex(800 + power)
   
    local shadowBehind = gfx.sprite.new()
    shadowBehind:setZIndex(900 + power)
    
   function digit:update()
       digit:checkBase()
       local value = (accumulatedNumber/(baseNumber ^ power)) % baseNumber
       local newCenter = value / baseNumber
       digit:setCenter(0.5, newCenter)
       shadowBehind:setCenter(0.5, ( value - baseNumber +1) / baseNumber)
   end
   
   function digit:setNewBase()
       baseNumber = base[baseSelection]
       local image = playdate.graphics.image.new('images/digit' .. baseNumber)
       digit:setImage(image)
       shadowBehind:setImage(image)
   end
   
   function digit:checkBase()
       if (baseNumber == base[baseSelection]) == false then
           digit:setNewBase()
       end
   end
   
   digit:setNewBase()
   digit:moveTo(x, y)
   digit:add()
    
    shadowBehind:moveTo(x, y + digitHeight)
    shadowBehind:add()
    
   return digit
end

local function createDigits()
    local image = playdate.graphics.image.new('images/digit10')
    local width, h = image:getSize()
    
    for power = 0, 7, 1
    do
        local xPos = lastDigitStart.x - power * width - power * digitGap + width / 2
       createDigit(xPos, lastDigitStart.y, power)
    end
end

local function createBaseSign(x,y, baseNumber)
    local signtable = gfx.imagetable.new('images/base' .. baseNumber .. '-sign')
    local animator = gfx.animator.new(800, 1, 1)
    print(signtable:getLength())
    local selected = false
    local extension = 0
    
    local middleStart = 0.5
    local extendedMiddle = 0.9
       
    local sign = gfx.sprite.new()
    sign:setZIndex(1100)
    sign:setImage(signtable:getImage(1))
    sign:moveTo(x, y)
    sign:add()
    
    function sign:update()
       local currentFrame = math.floor(animator:currentValue())
       print(baseNumber, selected, baseSelection, currentFrame)
       sign:setImage(signtable:getImage(currentFrame))
       sign:checkBase()
       
        if selected and extension < 1 then
            extension += 0.05
            extension = math.min(extension, 1)
        elseif (not selected) and extension > 0 then
            extension -= 0.07
            extension = math.max(extension, 0)
        end
        
    end
    
    function sign:checkBase()
      if selected ~= (baseNumber == base[baseSelection]) then
          if not selected then
             animator = gfx.animator.new(200, animator:currentValue(), signtable:getLength())
          else
             animator = gfx.animator.new(800, animator:currentValue(), 1)
          end
          
          selected = not selected
      end
    end
end

local function createBaseSigns()
    for i, power in ipairs(base) do
        createBaseSign(350 - i * 35, 94, power)
    end
end

local function createForeground()
    local foregroundMask = gfx.sprite.new()
    foregroundMask:setZIndex(1000)
    foregroundMask:setImage(playdate.graphics.image.new('images/digitMask'))
    foregroundMask:moveTo(200, 120)
    foregroundMask:add()
    
    local foreground = gfx.sprite.new()
    foreground:setZIndex(2000)
    foreground:setImage(playdate.graphics.image.new('images/counter'))
    foreground:moveTo(200, 120)
    foreground:add()
end

gfx.setBackgroundColor(playdate.graphics.kColorBlack)
createDigits()
createBaseSigns()
createForeground()

function playdate.update()
    if playdate.buttonJustPressed(playdate.kButtonLeft) then
        local newBase = baseSelection += 1
        baseSelection = math.min(newBase, #base)
    end
    if playdate.buttonJustPressed(playdate.kButtonRight) then
        local newBase = baseSelection -= 1
        baseSelection = math.max(newBase, 1)
    end
    if playdate.buttonIsPressed("B") then -- reduce
        if accumulationChange > 0 then
            accumulationChange = (accumulationChange - 0.05) * 0.95
        else
            accumulationChange = (accumulationChange - 0.05) * 1.05
        end
    elseif playdate.buttonIsPressed("A") then -- increase
        if accumulationChange > 0 then
            accumulationChange = (accumulationChange + 0.05) * 1.05
        else
            accumulationChange = (accumulationChange + 0.05) * 0.95
        end
    else
        if (accumulationChange > 0.1) then
            accumulationChange = math.min(0, ((accumulationChange -0.1) * 0.8))
        elseif (accumulationChange < - 0.1) then
            accumulationChange = math.max(0, ((accumulationChange +0.1) * 0.8))
        else
            accumulationChange = 0
        end
    end
    
    
    changeAccumulation()
    gfx.sprite.update()
    playdate.drawFPS(0,0)
end

function changeAccumulation()
    accumulatedNumber = math.min(math.max(0, accumulatedNumber += accumulationChange),20000000)
end

function playdate.cranked(change)
    local newAccumulation = accumulatedNumber + change/360 * crankSpeed
    accumulatedNumber = math.max(0,math.min(maximum or 1, newAccumulation))
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