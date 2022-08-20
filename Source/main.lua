import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/math"
import "CoreLibs/animation"
import "CoreLibs/easing"

local accumulatedNumber = 0
local crankSpeed = 1
local baseSelection = 2
local base = {10,2}
local accumulationChange = 0
local maximumAccumulation = 20000000
local maximumPowerDigit = 5
local analogueModeEnabled = false

local gfx = playdate.graphics

-- Digit stuff
local lastDigitStart = {x = 352, y = 115}
local digitGap = 5
local digitHeight = 60
local digitalSnapSpeed = 700
local digitEaseFunction = playdate.easingFunctions.outBounce

-- sound stuff
local smplayer = playdate.sound.sampleplayer
local clicks = {high={}, low={}}
local snd = playdate.sound
local overflowSynth = snd.synth.new(snd.kWaveSine)
overflowSynth:setADSR(0.9,0.0,0.1,0.1)

local menu = playdate.getSystemMenu()

local checkmarkMenuItem, error = menu:addCheckmarkMenuItem("analogue", analogueModeEnabled, function(value)
    analogueModeEnabled = value
end)

local function createDigit(x,y, power)
   local baseNumber = base[baseSelection]
   local digit = gfx.sprite.new()
   digit:setZIndex(800 + power)
   local animator = gfx.animator.new(digitalSnapSpeed, 0, 0)
   local lastValue = math.floor((accumulatedNumber/(baseNumber ^ power)) % baseNumber)
   
   local shadowBehind = gfx.sprite.new()
   shadowBehind:setZIndex(700 + power)
    
   function digit:update()
      digit:checkBase()
      
      local value = digit:getValue()
      local newCenter = value / baseNumber
      
      if not analogueModeEnabled then
         value = (accumulatedNumber/(baseNumber ^ power)) % (baseNumber)
         local flooredValue = math.floor(value)
         local lastFlooredValue = math.floor(lastValue)
         
         if lastFlooredValue ~=  flooredValue then
            -- positive overroll
            if (lastFlooredValue == baseNumber -1) and flooredValue == 0 and (playdate.getCrankChange() > 0) then
               animator = gfx.animator.new(digitalSnapSpeed, baseNumber -1, baseNumber, digitEaseFunction)
            -- negative overroll
            elseif (lastFlooredValue == 0) and flooredValue == baseNumber -1 and (playdate.getCrankChange() < 0) then
               animator = gfx.animator.new(digitalSnapSpeed, baseNumber, baseNumber -1, digitEaseFunction)
            else
               animator = gfx.animator.new(digitalSnapSpeed, lastFlooredValue, flooredValue, digitEaseFunction)
            end
         end
         newCenter = animator:currentValue()/baseNumber
         
         if animator:currentValue() >= baseNumber then
            newCenter = 0
         end
         
         lastValue = value
      end
      
      digit:setCenter(0.5, newCenter)
      shadowBehind:setCenter(0.5, newCenter)
   end
   
   function digit:setNewBase()
       baseNumber = base[baseSelection]
       local image = playdate.graphics.image.new('images/digit' .. baseNumber)
       digit:setImage(image)
       shadowBehind:setImage(image)
       local value = math.floor(digit:getValue())
       animator = gfx.animator.new(10, value, value)
   end
   
   function digit:checkBase()
       if (baseNumber == base[baseSelection]) == false then
           digit:setNewBase()
       end
   end
   
   function digit:getValue()
      return (accumulatedNumber/(baseNumber ^ power)) % (baseNumber)
   end
   
   digit:setNewBase()
   digit:moveTo(x, y)
   digit:add()
    
   shadowBehind:moveTo(x, y + baseNumber * digitHeight)
   shadowBehind:add()
   digit:setNewBase()
    
   return digit
end

local function createDigits()
    local image = playdate.graphics.image.new('images/digit10')
    local width, h = image:getSize()
    
    for power = 0, maximumPowerDigit, 1
    do
        local xPos = lastDigitStart.x - power * width - power * digitGap + width / 2
       createDigit(xPos, lastDigitStart.y, power)
    end
end

local function createBaseSign(x,y, baseNumber)
    local signtable = gfx.imagetable.new('images/base' .. baseNumber .. '-sign')
    local animator = gfx.animator.new(800, 1, 1)
    local selected = false
    local extension = 0

    local sign = gfx.sprite.new()
    sign:setZIndex(1100)
    sign:setImage(signtable:getImage(1))
    sign:moveTo(x, y)
    sign:add()
    
    function sign:update()
       local currentFrame = math.floor(animator:currentValue())
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
             animator = gfx.animator.new(400, animator:currentValue(), signtable:getLength(), playdate.easingFunctions.inCubic)
          else
             animator = gfx.animator.new(500, animator:currentValue(), 1, playdate.easingFunctions.inCubic)
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

local function createBaseSelector(x,y, baseNumber)
   
   local lastBaseSelection = baseSelection
   
   function getAngleTarget()
      local baseTableSize = 0
      for _ in pairs(base) do baseTableSize = baseTableSize + 1 end
      local baseFraction = ( baseSelection -1 ) / baseTableSize
      return 360 * baseFraction
   end
   
   local image = playdate.graphics.image.new('images/base-disk')
   
   -- The sign has to fit the list of selectable bases
   local baseSelector = gfx.sprite.new()
   local angle = getAngleTarget()
   local animator = gfx.animator.new(800, angle, angle, playdate.easingFunctions.easeInOutCirc)
   
   function baseSelectionHasChanged()
      if baseSelection ~= lastBaseSelection then
         lastBaseSelection = baseSelection
         return true
      end
      lastBaseSelection = baseSelection
      return false
   end
   
   function baseSelector:update()
      if baseSelectionHasChanged() then
         animator = gfx.animator.new(500, animator:currentValue(), getAngleTarget(), playdate.easingFunctions.inOutCubic)
      end
      baseSelector:setImage(image:rotatedImage(animator:currentValue()))
   end
   
   baseSelector:setCenter(0.5, 0.5)
   baseSelector:setZIndex(1100)
   baseSelector:setImage(image)
   baseSelector:moveTo(x, y)
   baseSelector:add()

end

local function createOverflow(x,y)
   local lightFrames = gfx.imagetable.new('images/rotatingLight')
   local animation = gfx.animation.loop.new(50, lightFrames, true)
   
   local selected = false
   local extension = 0
      
   local light = gfx.sprite.new()
   light:setZIndex(500)
   light:setImage(lightFrames:getImage(7))
   light:moveTo(x, y)
   light:add()
   
   function light:update()
      light:setImage(animation:image())
      light:checkOverflow()
      
       if selected and extension < 1 then
           extension += 0.05
           extension = math.min(extension, 1)
       elseif (not selected) and extension > 0 then
           extension -= 0.07
           extension = math.max(extension, 0)
       end

       if selected then
            local noteVariation = math.sin(playdate.getCurrentTimeMilliseconds()/65)
            local note = 361.63 + noteVariation * 100
            overflowSynth:playNote(note, 0.07 * extension, 0.1)
       end
      
      light:setCenter(extension, 0.5)
   end
   
   function light:checkOverflow()
      local largerThanDigits = accumulatedNumber >= base[baseSelection] ^ (maximumPowerDigit +1)
      if largerThanDigits then
         selected = true
      else
        selected = false
      end
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

local function loadClickSamples()
    for i=0,2 do
        table.insert(clicks["high"], smplayer.new("samples/click-high-" .. i))
        table.insert(clicks["low"], smplayer.new("samples/click-low-" .. i))
    end
end

gfx.setBackgroundColor(playdate.graphics.kColorBlack)
createDigits()
-- createBaseSigns()
createBaseSelector(360,119)
createOverflow(122, 130)
-- createForeground()
loadClickSamples()

function playdate.update()
    if playdate.buttonJustPressed(playdate.kButtonLeft) then
        local newBase = baseSelection += 1
        baseSelection = math.min(newBase, #base)
    end
    if playdate.buttonJustPressed(playdate.kButtonRight) then
        local newBase = baseSelection -= 1
        baseSelection = math.max(newBase, 1)
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) then -- reduce
        if accumulationChange > 0 then
            accumulationChange = (accumulationChange - 0.05) * 0.95
        else
            accumulationChange = (accumulationChange - 0.05) * 1.05
        end
    elseif playdate.buttonIsPressed(playdate.kButtonUp) then -- increase
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
    playValueChangedSound()
    gfx.sprite.update()
    playdate.drawFPS(0,0)
    
end

function displayCrankIndicator()
    if shown then
        playdate.ui.crankIndicator:update()
    end
end

function playValueChangedSound()
   local currentFlooredNumber = math.floor(accumulatedNumber)
   local crankChange = playdate:getCrankChange()/360 * crankSpeed
   local lastFlooredNumber = math.max(0,math.floor(accumulatedNumber - crankChange))

   if currentFlooredNumber > lastFlooredNumber then
    local randomSample = math.random(1,3)
    clicks["high"][randomSample]:play()
   elseif currentFlooredNumber < lastFlooredNumber then
    local randomSample = math.random(1,3)
    clicks["low"][randomSample]:play()
   end
end

function changeAccumulation()
    accumulatedNumber = math.min(math.max(0, accumulatedNumber += accumulationChange), maximumAccumulation)
end

function playdate.cranked(change)
    local newAccumulation = accumulatedNumber + change/360 * crankSpeed
   
    accumulatedNumber = math.max(0,math.min(maximumAccumulation or 1, newAccumulation))
    
end


function playdate.gameWillTerminate()
    saveState()
end

function playdate.deviceWillSleep()
    saveState()
end

function saveState()
    playdate.datastore.write({accumulatedNumber, baseSelection, analogueModeEnabled}, "countYourBase")
end

function playdate.gameWillResume()
    local config = playdate.datastore.read("countYourBase")
    if config ~= nil then
        accumulatedNumber = config.accumulatedNumber
        baseSelection = config.baseSelection
        analogueModeEnabled = config.analogueModeEnabled
    end
end