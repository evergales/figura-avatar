--[[==================================================
    Licensed under the MIT License.

    fishText v1.3.5
    Created by Lua_Fish

    Very customizable Figura dialog system

====================================================]]

--[[==================================================




                                        WARNING! READ THIS!

    Do NOT modify the code in here, use require("fishText") from a seperate script instead.

    Download the example avatar / scripts for more info. 




====================================================]]

local easingFuncs = {}
function easingFuncs.sineIn(t)
    return 1 - math.cos((t * math.pi) / 2)
end
function easingFuncs.sineOut(t)
    return math.sin((t * math.pi) / 2)
end
function easingFuncs.sineInOut(t)
    return 0.5 * (1 - math.cos(math.pi * t))
end

function easingFuncs.expIn(t)
    if t == 0 then return 0 end
    return math.pow(2, 10 * (t - 1))
end
function easingFuncs.expOut(t)
    if t == 1 then return 1 end
    return 1 - math.pow(2, -10 * t)
end

function easingFuncs.backOut(t)
    local s = 2
    t = t - 1
    return t * t * ((s + 1) * t + s) + 1
end
function easingFuncs.backIn(t, s)
    local s = 2
    return t * t * ((s + 1) * t - s)
end


local function getUniqueUUID()
    return client.intUUIDToString(client.generateUUID())
end

local colorFuncs = {}

function colorFuncs.hexToRgb(hex)
    hex = hex:gsub("#","")

    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)

    return vec(r, g, b)
end

function colorFuncs.rgbToHex(rgb)
    return string.format("#%02X%02X%02X", rgb.x, rgb.y, rgb.z)
end

function colorFuncs.srgbToLinear(c)
    c = c / 255

    if c <= 0.04045 then
        return c / 12.92
    end

    return ((c + 0.055) / 1.055) ^ 2.4
end

function colorFuncs.linearToSrgb(c)
    if c <= 0.0031308 then
        c = c * 12.92
    else
        c = 1.055 * (c ^ (1 / 2.4)) - 0.055
    end

    return math.clamp(c * 255, 0, 255)
end

function colorFuncs.lerpLinearRgb(c1, c2, t)
    local linear1 = vec(
        colorFuncs.srgbToLinear(c1.x),
        colorFuncs.srgbToLinear(c1.y),
        colorFuncs.srgbToLinear(c1.z)
    )

    local linear2 = vec(
        colorFuncs.srgbToLinear(c2.x),
        colorFuncs.srgbToLinear(c2.y),
        colorFuncs.srgbToLinear(c2.z)
    )

    local mixed = math.lerp(linear1, linear2, t)

    return vec(
        colorFuncs.linearToSrgb(mixed.x),
        colorFuncs.linearToSrgb(mixed.y),
        colorFuncs.linearToSrgb(mixed.z)
    )
end

local utf8 = {}

function utf8.len(s)
    local len = 0
    local i = 1
    local bytes = #s

    while i <= bytes do
        len = len + 1
        local c = s:byte(i)

        if c < 0x80 then
            i = i + 1
        elseif c < 0xE0 then
            i = i + 2
        elseif c < 0xF0 then
            i = i + 3
        else
            i = i + 4
        end
    end

    return len
end

function utf8.sub(s, i, j)
    local char_pos = 0
    local byte_pos = 1
    local byte_start, byte_end
    local bytes = #s

    while byte_pos <= bytes do
        char_pos = char_pos + 1

        if char_pos == i then
            byte_start = byte_pos
        end
        if j and char_pos == j + 1 then
            byte_end = byte_pos - 1
            break
        end

        local c = s:byte(byte_pos)
        if c < 0x80 then
            byte_pos = byte_pos + 1
        elseif c < 0xE0 then
            byte_pos = byte_pos + 2
        elseif c < 0xF0 then
            byte_pos = byte_pos + 3
        else
            byte_pos = byte_pos + 4
        end
    end

    if not byte_start then
        return ""
    end

    if not byte_end then
        byte_end = bytes
    end

    return s:sub(byte_start, byte_end)
end

function utf8.char(str, pos)
    if pos < 1 then return nil end

    local byte_pos = 1
    local char_count = 0
    local bytes = #str

    while byte_pos <= bytes do
        char_count = char_count + 1

        local c = str:byte(byte_pos)
        local char_len

        if c < 0x80 then
            char_len = 1
        elseif c < 0xE0 then
            char_len = 2
        elseif c < 0xF0 then
            char_len = 3
        else
            char_len = 4
        end

        if char_count == pos then
            return str:sub(byte_pos, byte_pos + char_len - 1)
        end

        byte_pos = byte_pos + char_len
    end

    return nil
end

function utf8.split(str, separators)
    local result = {}
    local sep_map = {}
    for _, s in ipairs(separators) do
        sep_map[s] = true
    end

    local chunk = ""

    for i = 1, #str do
        local ch = str:sub(i, i)
        if sep_map[ch] then
            if #chunk > 0 then
                table.insert(result, chunk)
                chunk = ""
            end
            table.insert(result, ch)
        else
            chunk = chunk .. ch
        end
    end

    if #chunk > 0 then
        table.insert(result, chunk)
    end

    return result
end

function utf8.toTable(str)
    local result = {}
    local bytes = #str
    local byte_pos = 1
    local out_i = 1

    while byte_pos <= bytes do
        local c = str:byte(byte_pos)
        local char_len

        if c < 0x80 then
            char_len = 1
        elseif c < 0xE0 then
            char_len = 2
        elseif c < 0xF0 then
            char_len = 3
        else
            char_len = 4
        end

        result[out_i] = str:sub(byte_pos, byte_pos + char_len - 1)
        out_i = out_i + 1
        byte_pos = byte_pos + char_len
    end

    return result
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

local fishText = {}
fishText.easingFuncs = easingFuncs
fishText.colorFuncs = colorFuncs

---------------------------------------------------------------------------------

local gradient = {}
gradient.__index = gradient

function gradient.new(colorListHex)
    assert(colorListHex ~= nil, "You must provide a colorList argument when creating a gradient")
    assert(type(colorListHex) == "table", "Argument is not a table")

    local new = setmetatable({}, gradient)

    local colorListRgb = {}
    for _,hex in pairs(colorListHex) do
        local rgb = colorFuncs.hexToRgb(hex)
        table.insert(colorListRgb, rgb)
    end

    new.colors = colorListRgb

    return new
end

function gradient:get(t)
    local i = (math.floor(t) % #self.colors) + 1
    local j = (math.floor(t+1) % #self.colors) + 1
    local k = t-math.floor(t)
    local color1 = self.colors[i]
    local color2 = self.colors[j]
    local blend = fishText.colorFuncs.lerpLinearRgb(color1, color2, k)
    --print("§9"..tostring(i) .. " §9" .. tostring(j) .. " §e" .. tostring(t) .. " §6" .. tostring(k) .. " §2" .. tostring(blend))
    return colorFuncs.rgbToHex(blend)
end

fishText.gradient = gradient

---------------------------------------------------------------------------------

local font = {}
font.__index = font

function font.new(texture, resolution, letters, letterWidths)
    assert(texture ~= nil, "Provided font texture is nil, Did you forget to import it into blockbench?")
    assert(type(texture) == "Texture", "Provided font texture is not a texture")
    assert(letterWidths.fallback, "Fallback width not provided")

    local new = setmetatable({}, font)

    new.texture = texture
    new.res = resolution or 8
    new.dim = texture:getDimensions()
    new.widths = letterWidths
    new.letterMap = {}

    local wa = new.dim.x / new.res
    local ha = new.dim.y / new.res
    for y = 1, ha do
        for x = 1, wa do
            local i = (y - 1) * wa + x
            local str = letters[i]
            if str then
                --print(i, str)
                new.letterMap[str] = vec((x-1)/wa, (y-1)/ha)
            end
        end
    end

    return new
end

function font:applyLetter(spriteTask, string)
    local region = self.letterMap[string]-- or self.letterMap.fallback
    --print(region, string)
    
    spriteTask:setTexture(self.texture, self.res, self.res)
    spriteTask:setDimensions(self.dim.x, self.dim.y)
    spriteTask:setUV(region)
end

function font:getWidth(string)
    return self.widths[string] or self.widths.fallback
end

fishText.templateFont = font

---------------------------------------------------------------------------------

local letter = {}
letter.__index = letter

function letter.new(string, word)
    local new = setmetatable({}, letter)

    new.string = string
    new.word = word
    new.display = nil

    new.pos = vec(0, 0, 0)
    new._pos = vec(0, 0, 0)
    new.posOffset = vec(0, 0, 0)

    new.rot = vec(0, 0, 0)
    new._rot = vec(0, 0, 0)
    new.rotOffset = vec(0, 0, 0)

    new.scale = vec(1, 1, 1)
    new._scale = vec(1, 1, 1)
    new.scaleOffset = vec(0, 0, 0)

    new._origin = vec(0, 0, 0)
    new.origin = vec(0, 0, 0)

    return new
end

function letter:resetTransform()
    self._pos = self.pos:copy()
    self._rot = self.rot:copy()
    self._scale = self.scale:copy()
end

function letter:getTransform(d)
    local pos = math.lerp(self._pos, self.pos, d) + self.posOffset + math.lerp(self._origin, self.origin, fishText.easingFuncs.sineInOut(d))
    local rot = math.lerp(self._rot, self.rot, d) + self.rotOffset
    local scale = math.lerp(self._scale, self.scale, d) + self.scaleOffset
    return pos, rot, scale
end

function letter:setOrigin(w, totalWidth, lineIndex, message)
    self._origin = self.origin:copy()
    self.origin = vec(-w, ((#message.lines - lineIndex) * message.instance.lineSpacing), 0) + vec(totalWidth/2, 0, 0)
end

function letter:applyFormatting()
    if self.display == nil then return end
    local dialog = self.word.message.instance

    local isItalic, isBold = false, false
    if self.italic ~= nil then
        isItalic = self.italic
    elseif  self.word.italic ~= nil then
        isItalic = self.word.italic
    else
        isItalic = dialog.textItalic
    end
    if self.bold ~= nil then
        isBold = self.bold
    elseif  self.word.bold ~= nil then
        isBold = self.word.bold
    else
        isBold = dialog.textBold
    end

    if type(self.display) == "SpriteTask" then
        local textColor = self.color or self.word.color or dialog.textColor
        self.display:setColor(colorFuncs.hexToRgb(textColor)/255)
    else
        self.display:setText(toJson({
            text = self.string, 
            color = self.color or self.word.color or dialog.textColor,
            italic = isItalic,
            bold = isBold,
            font = self.vanillaFont or self.word.vanillaFont or dialog.vanillaFont,
        }))
        if dialog.textOutlineColor then
            self.display:setOutline(true)
            local outlineColor = self.outlineColor or self.word.outlineColor or dialog.textOutlineColor
            self.display:setOutlineColor(colorFuncs.hexToRgb(outlineColor)/255)
        elseif dialog.textHasShadow then
            self.display:setShadow(true)
        end
    end
end

---------------------------------------------------------------------------------

local word = {}
word.__index = word

function word.new(str, message, index)
    local new = setmetatable({}, word)
    new.string = str
    new.i = index
    new.tags = {}-- ["shaking"] = true, ...etc
    new.letters = {}
    new.message = message

    return new
end

function word:init(message)
    local isSpace = self.string == " "


    if #message.lines == 0 then
       message:newLine()
    end

    local function addLetter(string, isEmoji)
        local letter = letter.new(string, self)
        letter.isEmoji = isEmoji
        table.insert(self.letters, letter)
    end

    if isSpace then
        addLetter(" ")
        return
    end

    local isEmoji = string.sub(self.string, 1, 1) == ":" and string.sub(self.string, -1, -1) == ":"

    if isEmoji then
        addLetter(self.string, true)
    else
        local letterStrings = utf8.toTable(self.string)
        for _, string in pairs(letterStrings) do
            addLetter(string)
        end
    end
end

---------------------------------------------------------------------------------

local message = {}
message.__index = message

function message.new(inst, str)
    local new = setmetatable({}, message)
    new.instance = inst
    new.string = str

    local wordStrings = utf8.split(
        str,
        new.instance.separators
    )

    new.despawnTime = utf8.len(str) * new.instance.despawnLengthMult + new.instance.despawnTime
    
    new.words = {}
    for i, string in ipairs(wordStrings) do
        local word = word.new(string, new, i)
        table.insert(new.words, word)
    end
    new.lines = {}

    new.currentTick = 0
    new.currentIndex = 0
    new.currentLineIndex = 0
    new.currentWordIndex = 0
    new.currentLetterIndex = 0
    new.currentPause = 0
    new.lastTick = nil

    return new
end

function message:next()
    self.currentTick = self.currentTick + 1
    if self.lastTick then
        if self.currentTick > self.lastTick + self.despawnTime then
            self.instance:clear()
            return false
        end
    else
        if self.currentPause > 0 then
            self.currentPause = self.currentPause - 1
        else
            if not self.noIncrement then
                self.currentLetterIndex = self.currentLetterIndex + 1
            end

            local currentWord = self.words[self.currentWordIndex]
            if self.currentWordIndex == 0 or self.currentLetterIndex > #currentWord.letters or self.noIncrement then
                if not self.noIncrement then
                    self.currentWordIndex = self.currentWordIndex + 1
                end
                self.currentLetterIndex = 1

                self.noIncrement = nil

                local exists = false
                repeat
                    currentWord = self.words[self.currentWordIndex]
                    if currentWord == nil then break end
                    if self.instance:onWordPreInit(currentWord) then
                        exists = true
                    else
                        table.remove(self.words, self.currentWordIndex)
                    end
                    if self.currentPause > 0 and exists == false then
                        self.currentPause = self.currentPause - 1
                        self.noIncrement = true
                        return true
                    end
                until exists
                if currentWord == nil then
                    self.lastTick = self.currentTick
                    self.instance:onStopped()
                    return true
                end
                self.instance:_wordInit(currentWord)
                currentWord:init(self)
            end

            self.currentIndex = self.currentIndex + 1
            self.currentLineIndex = self.currentLineIndex + 1
            local letter = currentWord.letters[self.currentLetterIndex]
            self.instance:_letterInit(letter)

            local currentLine = self.lines[#self.lines]
            if #currentLine.letters > self.instance.maxWrap then
                self:newLine()
            elseif letter.string == " " and #currentLine.letters > self.instance.minWrap then
                self:newLine()
            end

            local pause = self.instance.pauseLetters[letter.string]
            if pause then
                self.currentPause = pause
            end
        end
    end
    return true
end

function message:tick()
    local success = self:next()
    if not success then return end
    
    local dialogFont = self.instance.font

    for i, line in ipairs(self.lines) do
        local w = 0
        for j, letter in ipairs(line.letters) do
            if letter.string == " " then
                w = w + self.instance.spaceWidth
            else
                local font = letter.font or letter.word.font or dialogFont
                letter.w = w
                w = w + ((letter.isEmoji and 8) or (font and font:getWidth(letter.string)) or client.getTextWidth(letter.string)) + (letter.tracking or letter.word.tracking or self.instance.tracking)
            end
            
        end
        line.width = w
    end
    
    for i, line in ipairs(self.lines) do
        for j, letter in ipairs(line.letters) do
            if letter.string ~= " " then
                letter:setOrigin(letter.w, line.width, i, self)
                self.instance:_letterTick(letter)
            end
        end
    end
    
end

function message:newLine()
    self.currentLineIndex = 0
    table.insert(self.lines, {
        ["letters"] = {},
        ["width"] = 0,
    })
end

function message:remove()
    for i, line in ipairs(self.lines) do
        for j, letter in ipairs(line.letters) do
            local display = letter.display
            if display then
                display:remove()
            end
        end
    end
    self.instance.currentMessage = nil
end

---------------------------------------------------------------------------------
local liteDialog = {}
liteDialog.__index = liteDialog

fishText.liteDialog = liteDialog
liteDialog.despawnLengthMult = 2
liteDialog.despawnTime = 40

function liteDialog.new(parent, warn)
    assert(parent ~= nil, "You must provide a parent ModelPart when creating a new dialog instance")
    assert(type(parent) == "ModelPart", "Argument parent is not a ModelPart")

    local dialogInstance = setmetatable({}, liteDialog)
    dialogInstance.root = parent:newPart("root_"..getUniqueUUID(), "BILLBOARD")
    dialogInstance.visible = true

    if warn then
        dialogInstance.warn = dialogInstance.root:newText("warn_"..getUniqueUUID())
            :setAlignment("CENTER")
            :setPos(0, 16, 0)
            :setScale(0.2, 0.2, 0.2)
            :setText(toJson({
                text = "Set me to MAX for nicer dialog :crying_pancake:", 
                color = "#FFF3F8",
                italic = false,
                bold = false
            }))
            :setOutline(true)
            :setOutlineColor(0.1, 0.51, 0.357)
            :setVisible(false)
    end

    dialogInstance.display = dialogInstance.root:newText("text_"..getUniqueUUID())
        :setAlignment("CENTER")
        :setPos(0, 0, 0)
        :setScale(0.4, 0.4, 0.4)
        :setOutline(true)
        :setOutlineColor(0.82, 0.145, 0.404)

    return dialogInstance
end

function liteDialog:write(str)
    if str == nil then return end
    assert(type(str) == "string", "Argument is not a string")

    self:clear(true)
    if str == "" then return end

    local newStr = ""

    local rowIndex = 0
    local rows = 0
    for i = 1, string.len(str) do
        local letterStr = string.sub(str, i, i)
        newStr = newStr .. letterStr
        rowIndex = rowIndex + 1
        if letterStr == " " and rowIndex > 30 then
            newStr = newStr .. "\n"
            rowIndex = 0
            rows = rows + 1
        end
    end

    self.display:setText(newStr)
    self.display:setPos(0, rows*4 + 5, 0)

    if self.warn then
        self.warn:setPos(0, -4, 0):setVisible(true)
    end

    if fishText.primaryInstance == self then
        fishText:storePublic("message", str)
    end

    self.currentTick = 0
    self.lastTick = 0
    self.messageDespawnTime = utf8.len(str) * self.despawnLengthMult + self.despawnTime

    self:onWrite()
end

function liteDialog:clear(ignore)
    self.display:setText("")
    if self.warn then
        self.warn:setVisible(false)
    end

    if not ignore then
        self:onClear()
        self:onStopped()
    end

    self.currentTick = nil
    self.lastTick = nil
    self.messageDespawnTime = nil

    if fishText.primaryInstance == self then
        fishText:storePublic("message", nil)
    end
end

function liteDialog:setParentType(parentType)
    self.root:setParentType(parentType)
    return self
end
function liteDialog:setPos(pos)
    self.root:setPos(pos)
    return self
end
function liteDialog:setRot(rot)
    self.root:setRot(rot)
    return self
end
function liteDialog:setScale(scale)
    self.root:setScale(scale)
    return self
end

function liteDialog:setVisible(visible)
    self.display:setVisible(visible)
end
function liteDialog:onWrite()end
function liteDialog:onClear()end
function liteDialog:onStopped()end
function liteDialog:tick()
    if not self.lastTick then
        return
    end

    self.currentTick = self.currentTick + 1

    if self.currentTick > self.lastTick + self.messageDespawnTime then
        self:clear()
    end
end
function liteDialog:render()end

---------------------------------------------------------------------------------

local dialog = {}
dialog.__index = dialog

dialog.separators = {" ", ",", ".", "!", "?", '"', "'"}
dialog.textScale = 0.4
dialog.tracking = 0
dialog.spaceWidth = 5
dialog.lineSpacing = 10

dialog.pauseLetters = {
    [","] = 2,
    ["."] = 4,
    ["!"] = 4,
    ["?"] = 4,
}

dialog.minWrap = 35
dialog.maxWrap = 60

dialog.despawnLengthMult = 1
dialog.despawnTime = 40

dialog.textColor = "#D5E7EB"
dialog.textBold = false
dialog.textItalic = false
dialog.textHasShadow = true
dialog.textOutlineColor = nil
dialog.textSeeThrough = false

dialog.introDuration = 5
dialog.outroDuration = 10

function dialog.new(parent)
    assert(parent ~= nil, "You must provide a parent ModelPart when creating a new dialog instance")
    assert(type(parent) == "ModelPart", "Argument parent is not a ModelPart")

    local dialogInstance = setmetatable({}, dialog)
    dialogInstance.root = parent:newPart("root_"..getUniqueUUID(), "BILLBOARD")
    dialogInstance.visible = true

    return dialogInstance
end

function dialog:setParentType(parentType)
    self.root:setParentType(parentType)
    return self
end
function dialog:setPos(pos)
    self.root:setPos(pos)
    return self
end
function dialog:setRot(rot)
    self.root:setRot(rot)
    return self
end
function dialog:setScale(scale)
    self.root:setScale(scale)
    return self
end

function dialog:setVisible(visible)
    self.root:setVisible(visible)
    --[[
    if visible ~= self.visible then
        self.visible = visible
        self.root:setVisible(visible)
        
        local message = self.currentMessage
        if message == nil then return end
        for i, line in ipairs(message.lines) do
            for j, letter in ipairs(line.letters) do
                local display = letter.display
                if display then
                    display:setVisible(visible)
                end
            end
        end
        
    end
    ]]
end

function dialog:write(str)
    if str == nil then return end
    assert(type(str) == "string" or type(str) == "number", "Argument is not a string")

    self:clear(true)
    if str == "" then return end

    if fishText.primaryInstance == self then
        fishText:storePublic("message", str)
    end

    local message = message.new(self, str)
    self.currentMessage = message

    self:onWrite()

    return message
end

function dialog:clear(ignore)
    local message = self.currentMessage
    if message == nil then return end
    message:remove()

    if not ignore then
        self:onClear()
        self:onStopped()
    end

    if fishText.primaryInstance == self then
        fishText:storePublic("message", nil)
    end
end

function dialog:onWrite()end
function dialog:onClear()end
function dialog:onStopped()end

function dialog:onWordInit(word)end
function dialog:onLetterInit(letter, letterIndex, wordIndex, totalIndex, lineIndex)
    letter.i = totalIndex
end
function dialog:onLetterTick(letter, tick, intro, outro)
    local p = math.sin(tick/5 + letter.i/2)*0.5

    local expIntro = fishText.easingFuncs.expIn(intro)

    letter.pos = vec(
        0, 
        p - expIntro * 5 - outro*4
        , 0
    )

    letter.scale = vec(
        1, 
        1 - outro, 
        1
    )
end
function dialog:onLetterRender(letter, d)end
function dialog:onWordPreInit(word)
    return true
end

function dialog:_wordInit(word)
    self:onWordInit(word)
end
function dialog:_letterInit(letter)
    local message = self.currentMessage
    local line = message.lines[#message.lines]
    table.insert(line.letters, letter)

    if letter.string == " " then return end

    self:onLetterInit(letter, message.currentLetterIndex, message.currentWordIndex, message.currentIndex, message.currentLineIndex)
    
    local font = (letter.font or letter.word.font or self.font)
    if font then
        letter.display = self.root:newSprite("letter_"..getUniqueUUID())
        font:applyLetter(letter.display, letter.string)
        letter.display:setLight(15)
        local renderType = font.renderType or "TRANSLUCENT_CULL"
        if renderType then
            letter.display:setRenderType(renderType)
        end
    else
        letter.display = self.root:newText("letter_"..getUniqueUUID())
        letter.display:setSeeThrough(self.textSeeThrough)
    end
    letter.display:setVisible(false)
    letter.renderInit = true
    letter.initTick = message.currentTick

    local line = message.lines[#message.lines]
    letter:setOrigin(line.width, line.width, #message.lines, message)

    letter:applyFormatting()

    self:onLetterTick(letter, message.currentTick-1, 1, 0)
end
function dialog:_letterTick(letter)
    if letter.display == nil then return end
    local message = self.currentMessage

    letter:resetTransform()

    local ip = 1 - math.clamp((message.currentTick - letter.initTick) / self.introDuration, 0, 1)
    local op = (message.lastTick and math.clamp((message.currentTick - message.lastTick - message.despawnTime + self.outroDuration) /  self.outroDuration, 0, 1)) or 0

    self:onLetterTick(letter, message.currentTick, ip, op)
end
function dialog:_letterRender(letter, d)

    if letter.display then
        local pos, rot, scale = letter:getTransform(d)
        local font = (letter.font or letter.word.font or self.font)
        local fontMul = 1
        if font then
            local fontRes = font.res
            fontMul = fontRes and 1/(fontRes/8)
        end
        letter.display:setPos(pos * self.textScale)
        letter.display:setRot(rot)
        letter.display:setScale(scale * self.textScale * fontMul)

        if letter.renderInit then
            letter.renderInit = nil
            letter.display:setVisible(true)
        end
    end

    self:onLetterRender(letter)
end


dialog.lastStep = 1
dialog.framesPerTick = 2
dialog.lodEnabled = true
dialog.targetPos = nil

function dialog:setTargetFPS(_)
    if dialog.hasSetTargetFPSWarned then return end
    dialog.hasSetTargetFPSWarned = true
    print('§6An update (v1.0.4+) has caused your "localchat.lua" to no longer work correctly, redownload the example avatar and copy the script, sorry about that')
end

function dialog:setFramesPerTick(target)
    self.framesPerTick = target
end

function dialog:_lodTick()
    local pos = self.targetPos or (player:isLoaded() and player:getPos())
    if pos == nil then return end
    local camPos = client.getCameraPos()

    local dist = (pos-camPos):lengthSquared()

    local target = 
        (dist < 350 and 2.5) or    
        (dist < 500 and 1.5) or
        (dist < 1000 and 1) or
        0.75

    self:setFramesPerTick(target)
end

function dialog:render(d)
    assert(type(d) == "number", "Argument delta is not a number")
    local message = self.currentMessage
    if message == nil then return end

    local currentStep = math.floor((message.currentTick + d) * self.framesPerTick)

    if currentStep == self.lastStep then
        return
    end

    self.lastStep = currentStep

    for i, line in ipairs(message.lines) do
        for j, letter in ipairs(line.letters) do
            self:_letterRender(letter, d)
        end
    end

end

function dialog:tick()
    local message = self.currentMessage
    if message == nil then return end

    if self.lodEnabled then
        self:_lodTick()
    end
    message:tick()
end

function fishText:permissionCheck()
    local canUse = avatar:getPermissionLevel() == "MAX"

    return canUse
end

fishText.defaultDialog = dialog
fishText.primaryInstance = nil

fishText.public = {
    ["version"] = "1.3.5",
}
avatar:store("fishText", fishText.public)

function fishText:storePublic(key, value)
    fishText.public[key] = value
    avatar:store("fishText", fishText.public)
end

return fishText