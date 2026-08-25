--============================================================================--

-- The file path to fishTextAssets
local assetsPath = "fishTextAssets"

local fishText = require(assetsPath..".fishText")
local defaultDialog = fishText.defaultDialog

--============================================================================--

-- Creates a new custom dialog using the default one provided.
local customDialog = setmetatable({}, { __index = defaultDialog })
customDialog.__index = customDialog

local activeMessage = ""

--To add a custom font, drag the texture and lua file into fishTextAssets.fonts, then import the texture into the fishTextAssets.fontModel bbmodel file.
--customDialog.font = require(assetsPath..".fonts.template")

customDialog.textScale = 0.4
customDialog.tracking = 0
customDialog.spaceWidth = 5
customDialog.lineSpacing = 12

-- Amount of letters before starting a new line at the next space.
customDialog.minWrap = 35
-- Absolute maximum amount of letters before forcibly starting a new line mid word.
customDialog.maxWrap = 60

-- Amount of ticks before the text despawns.
customDialog.despawnTime = 40
-- Message length multiplied by "despawnLengthMult" gets added to the despawn time, so that longer words take more time to despawn. Set to 0 to disable it and only use "despawnTime" instead.
customDialog.despawnLengthMult = 1

-- Default text formatting.
customDialog.textColor = "#FFE6F2"
customDialog.textOutlineColor = "#B8204E"-- Set to nil to remove outline
customDialog.textBold = false
customDialog.textItalic = false
customDialog.textHasShadow = false
customDialog.textSeeThrough = true

-- Intro & outro animation duration.
customDialog.introDuration = 8
customDialog.outroDuration = 10

customDialog.pauseLetters = {
    [","] = 4,
    ["."] = 7,
    ["!"] = 7,
    ["?"] = 7,
}

local italicCharacter = "*"

--============================================================================--

local textFormatting = {
    {
        formatting = {
            ["color"] = "#FF0000",
            ["outlineColor"] = "#600030",
            ["italic"] = true,
            ["bold"] = true,
            ["tags"] = {
                ["shaky"] = true,
            },
        },
        strings = {
            "scary", "kill", "fuck"
        }
    },
    {
        formatting = {
            ["color"] = "#D7FFD4",
            ["outlineColor"] = "#E29221",
        },
        strings = {
            "orange", "clock", "clockwork", "samy", 
        }
    },
    {
        formatting = {
            ["color"] = "#30AFEF",
            ["outlineColor"] = "#0A4265",
        },
        strings = {
            "SushiSharkS", "sushi", ":sushi::shark:", "shime", "Szymoon8", "szy", "blue", "shark", 
        }
    },
    {
        formatting = {
            ["color"] = "#CD8FD5",
            ["outlineColor"] = "#5B3069",
        },
        strings = {
            "nomad", "purple", 
        }
    },
    {
        formatting = {
            ["color"] = "#80C3A8",
            ["outlineColor"] = "#155430",
        },
        strings = {
            "jade", "green", 
        }
    },

    --{
    --    formatting = {
    --        ["tags"] = {
    --            ["test"] = 0.5,-- You can have parameters on tags instead of "true"
    --        },
    --    },
    --    strings = {
    --        "test", 
    --    }
    --},
}

local dialogPitch = 1.2
local dialogPitchVariation = 0.2
local dialogVolume = 1.0
local defaultDialogAudio = "entity.axolotl.idle_water"
local textAnimations = {
    ["shaky"] = function(letter, tick, intro, outro, _)
        letter.posOffset = vec(math.random()-0.5, math.random()-0.5, 0)
    end,
    --[[ 
    ["wavy"] = function(letter, tick, intro, outro, _)
        letter.pos = vec(0, math.sin(tick/2 + letter.i/2)*2, 0)
    end,
    ]]
}

--============================================================================--
local textFormattingMapped = {}--Don't touch

--Not used, uncomment if needed
--[[
function customDialog:onWordPreInit(word)
    if word.string == "fuck" then
        word.string = "frick"
        return false
    end

    if word.string == ";" then
        self.currentMessage:newLine()
        return false
    end

    if word.string == "|" then
        self.currentMessage.currentPause = 20
        return false
    end

    return true
end
]]

-- Runs right before the first letter of a new word starts
local italicMode = false
function customDialog:onWordInit(word)

    local formatting = textFormattingMapped[string.lower(word.string)]
    if formatting then
        for key, value in pairs(formatting) do
            word[key] = value
        end
    end

    --Adds shaky tag if text is in all CAPS, more than 1 letter, is alphanumeric
    if word.string:match("%a") and word.string:len() > 1 and word.string:upper() == word.string then
        word.tags.shaky = true
    end

    -- Starts italic
    if word.string:sub(1,1) == italicCharacter then
        -- check if the remaining text has a closing character, and only enter italic mode if so
        local idx = activeMessage:find(word.string, 1, true)
        if idx and word.string ~= italicCharacter and activeMessage:sub(idx + 1):find("%"..italicCharacter) then
            italicMode = true
            word.string = word.string:sub(2)
        end
    end

    if italicMode then
        word.italic = true
    end

    -- Ends italic
    if italicMode and word.string:sub(-1) == italicCharacter then
        word.string = word.string:sub(1, -2)
        italicMode = false
    end
end

-- Runs when a letter spawns
function customDialog:onLetterInit(letter, letterIndex, wordIndex, totalIndex, lineIndex)
    if letter == nil then letter.string = "" end
    letter.i = totalIndex-- Saves the letters index to be used for the text animation
    --Dialog audio
    if not self.muted and player:isLoaded() and letter.string ~= " " then
        local sound = defaultDialogAudio
        local snd = sounds[sound]
            :setSubtitle(nameplate.CHAT:getText().." speaks")
            :setPitch(dialogPitch + (math.random()-0.5)*2 * dialogPitchVariation)
            :setVolume(dialogVolume)
            :setPos(player:getPos())
            :play()
    end
end

function customDialog:onLetterTick(letter, tick, intro, outro)
    local p = math.sin(tick/4 + letter.i/2)*0.25
    local r = math.cos(tick/8 + letter.i/2)*3

    local expIntro = fishText.easingFuncs.expIn(intro)
    local sinOutro = fishText.easingFuncs.sineIn(outro)

    -- Applies default animation
    letter.pos = vec(0, p, 0)
    letter.rot = vec(0, 0, r)
    letter.scale = vec(1, 1, 1)

    -- Applies other animations from textAnimations depending on tag
    for tag, value in pairs(letter.word.tags) do
        textAnimations[tag](letter, tick, intro, outro, value)
    end

    -- Applies intro & outro animations
    letter.pos = letter.pos + vec(
        0, 
        (expIntro * 12) - (sinOutro * 4), 
        0
    )
    letter.scale = letter.scale + vec(
        0, 
        expIntro - sinOutro, 
        0
    )
end

--Not used, uncomment if needed
--[[

function customDialog:onLetterRender(letter, d)
end

function customDialog:onLetterRemove(letter)
end

]]

for i, formatTable in pairs(textFormatting) do
    for _, string in pairs(formatTable.strings) do
        textFormattingMapped[string] = formatTable.formatting
    end
    formatTable.strings = nil
    formatTable.formatting = nil
end
textFormatting = nil

--============================================================================--

function customDialog.new(parent)
    local obj = setmetatable(defaultDialog.new(parent), customDialog)
    obj.muted = false-- Custom "muted" property for the dialog audio
    return obj
end

function customDialog:onWrite()
    -- All of these functions will run for every dialog instace, if you have subtitles that means it runs twice, we don't want that here so lets return it if it's not the primary dialog
    if fishText.primaryInstance ~= self then return end
    ActiveNameplate:setVisible(false)
    activeMessage = player:getVariable("fishText")["message"]
end
-- Runs when the text is cleared, writing a new message will clear text but wont run this function, only onWrite(). 
function customDialog:onClear()
    if fishText.primaryInstance ~= self then return end
    ActiveNameplate:setVisible(true)
end

--Not used, uncomment if needed
--[[

-- Runs when the last letter of the message has spawned (When you stop talking basically, useful for speaking animations)
function customDialog:onStopped()
end

]]

return customDialog