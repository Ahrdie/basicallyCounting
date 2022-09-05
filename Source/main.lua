import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/math"
import "CoreLibs/animation"
import "CoreLibs/easing"

local accumulatedNumber = 0
local crankSpeed = 1
local baseSelection = 2
local base = {2, 10, 16, 60}
local accumulationChange = 0
local maximumAccumulation = 20000000
local maximumPowerDigit = 5
local analogueModeEnabled = false
local lastSuggestion = 0

local gfx = playdate.graphics

-- Digit stuff
local lastDigitStart = {x = 353, y = 115}
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

local speedMenuItem, error = menu:addOptionsMenuItem("speed", {"0.5x","1x","2x","4x","8x","16x","32x"},"1x", function(value)
   local speed = value:gsub("x","")
   crankSpeed = tonumber(speed)
end)

function saveState()
   local state = {}
   state["accumulatedNumber"] = accumulatedNumber
   state["baseSelection"] = baseSelection
   state["analogueModeEnabled"] = analogueModeEnabled
   state["crankSpeed"] = crankSpeed
   playdate.datastore.write(state, "countYourBase")
end

local function createDigit(x,y, power)
   local baseNumber = base[baseSelection]
   local digit = gfx.sprite.new()
   digit:setZIndex(800 + power)
   local countingAnimator = gfx.animator.new(digitalSnapSpeed, 0, 0)
   local sidewayAnimator = gfx.animator.new(500, -0.5, 0.5, playdate.easingFunctions.outBounce)
   local lastValue = math.floor((accumulatedNumber/(baseNumber ^ power)) % baseNumber)
   local settingNewBase = false
   
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
            if (lastFlooredValue == baseNumber -1) and flooredValue == 0 then
               countingAnimator = gfx.animator.new(digitalSnapSpeed, lastFlooredValue, baseNumber, digitEaseFunction)
            -- negative overroll
            elseif (lastFlooredValue == 0) and flooredValue == baseNumber -1 then
               countingAnimator = gfx.animator.new(digitalSnapSpeed, baseNumber, baseNumber -1, digitEaseFunction)
            else
               countingAnimator = gfx.animator.new(digitalSnapSpeed, lastFlooredValue, flooredValue, digitEaseFunction)
            end
         end
         newCenter = countingAnimator:currentValue()/baseNumber
         
         lastValue = value
      end
      
      digit:setCenter(sidewayAnimator:currentValue(), newCenter)
      shadowBehind:setCenter(sidewayAnimator:currentValue(), newCenter)
   end
   
   function digit:setNewBase()
       baseNumber = base[baseSelection]
       local image = playdate.graphics.image.new('images/digit' .. baseNumber)
       digit:setImage(image)
       shadowBehind:setImage(image)
       shadowBehind:moveTo(x, y + baseNumber * digitHeight)
       local value = math.floor(digit:getValue())
       countingAnimator = gfx.animator.new(10, value, value)
   end
   
   function digit:checkBase()
      if not settingNewBase and (baseNumber == base[baseSelection]) == false then
         settingNewBase = true
         sidewayAnimator = gfx.animator.new(700 * (sidewayAnimator:currentValue()+0.5), sidewayAnimator:currentValue(), -0.5, playdate.easingFunctions.inQuint)
      end
      if (sidewayAnimator:ended() and settingNewBase) then
        digit:setNewBase()
        sidewayAnimator = gfx.animator.new(500, -0.5, 0.5,playdate.easingFunctions.inQuint)
        settingNewBase = false
      end
   end
   
   function digit:getValue()
      return (accumulatedNumber/(baseNumber ^ power)) % (baseNumber)
   end
   
   function digit:moveDigitToY(y)
      digit:moveTo(digit.x, y)
      digit:setClipRect(digit.x - digit.width/2, y, digit.width, digitHeight)
      shadowBehind:setClipRect(digit.x - digit.width/2, y, digit.width, digitHeight)
   end
   
   digit:setNewBase()
   digit:moveTo(x, y)
   digit:moveDigitToY(y)
   digit:add()
    
   shadowBehind:moveTo(x, y + baseNumber * digitHeight)
   shadowBehind:add()
   digit:setNewBase()
    
   return {digit, shadowBehind}
end

local function createDigits()
    local image = playdate.graphics.image.new('images/digit10')
    local width, h = image:getSize()
    local digits = {}
    
    for power = 0, maximumPowerDigit, 1
    do
       local xPos = lastDigitStart.x - power * width - power * digitGap + width / 2
       table.insert(digits, createDigit(xPos, lastDigitStart.y, power))
    end
    return digits
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
      baseSelector:setClipRect(337, 96, 46, 13)
   end
   
   baseSelector:setCenter(0.5, 0.5)
   baseSelector:setZIndex(1100)
   baseSelector:setImage(image)
   baseSelector:moveTo(x, y)
   baseSelector:add()
   return baseSelector
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
   local inside = gfx.sprite.new()
   inside:setZIndex(600)
   inside:setImage(playdate.graphics.image.new('images/counter-inner'))
   inside:moveTo(200, 120)
   inside:add()
   
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

function getIndexInTable(table, value)
   local index={}
   for k,v in pairs(table) do
      index[v]=k
   end
   return index[value]
end

function changeMenuImage()
   local suggestionsFile, err = playdate.file.open("countSuggestions.json", playdate.file.kFileRead)
   local suggestions = json.decodeFile(suggestionsFile)
   
   local countCardImage = gfx.image.new("images/suggestionCard")
   gfx.lockFocus(countCardImage)
   local bgRect = playdate.geometry.rect.new(10, 10, 180, 220)
   local textRect = playdate.geometry.rect.new(20, 20, 150, 190)
   local numberRect = playdate.geometry.rect.new(20, 200, 150, 20)
   gfx.setColor(gfx.kColorWhite)
   gfx.fillRoundRect(bgRect, 10)
   gfx.setColor(gfx.kColorBlack)
   gfx.drawRoundRect(bgRect, 10)
   
   local randomLineNumber = math.random(1,#suggestions)
   if (randomLineNumber == lastSuggestion) then
      if (randomLineNumber ~= #suggestions) then
         randomLineNumber = randomLineNumber +1
      else
         randomLineNumber = randomLineNumber -1
      end
   end
   lastSuggestion = randomLineNumber
   
   local randomLine = suggestions[randomLineNumber]
   
   local text = "*You could count…*\n…" .. randomLine
   local numberLine = "#" .. getIndexInTable(suggestions, randomLine)
   gfx.drawTextInRect(text, textRect, 0, "...", kTextAlignment.left)
   gfx.drawTextInRect(numberLine, numberRect, 0, "...", kTextAlignment.center)
   
   gfx.unlockFocus()
   playdate.setMenuImage(countCardImage)
end

gfx.setBackgroundColor(playdate.graphics.kColorBlack)
local digits = createDigits()
local baseSelector = createBaseSelector(360,119)
createOverflow(122, 130)
createForeground()
loadClickSamples()
saveState()
changeMenuImage()

function playdate.update()
    if playdate.buttonJustPressed(playdate.kButtonLeft) then
        local newBase = baseSelection += 1
        baseSelection = math.min(newBase, #base)
    end
    if playdate.buttonJustPressed(playdate.kButtonRight) then
        local newBase = baseSelection -= 1
        baseSelection = math.max(newBase, 1)
    end
    if playdate.buttonJustPressed(playdate.kButtonUp) then
         accumulatedNumber = math.floor(accumulatedNumber +1)
    elseif playdate.buttonJustPressed(playdate.kButtonUp) then
         accumulatedNumber = math.floor(accumulatedNumber -1)
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then -- reduce
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

function playdate.gameWillPause()
    saveState()
end

function playdate.gameWillTerminate()
    saveState()
end

function playdate.deviceWillSleep()
    saveState()
end

function playdate.gameWillResume()
    local config = playdate.datastore.read("countYourBase")
    if config ~= nil then
        accumulatedNumber = config.accumulatedNumber
        baseSelection = config.baseSelection
        analogueModeEnabled = config.analogueModeEnabled
        crankSpeed = config.crankSpeed
    end
    changeMenuImage()
end