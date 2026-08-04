--============================================================================--

-- This script adds localchat functionality to fishText.
-- Check the customDialog.lua file for further customization.
-- Don't forget to download & add fishText to this avatar, it does not come pre-installed. 
-- When updates & bugfixes are released to fishText you can safely replace the fishText.lua without ruining your own customizations.

-- The file path to fishTextAssets
local assetsPath = "fishTextAssets"

-- The file name of the dialog lua file you want to use
local dialogName = "customDialog"

-- Chat prefix.
local prefix = "."

-- Should the prefix make you send a localchat message or a globalchat message.
local isPrefixLocal = true

-- Should messages sent in globalchat also be shown above head.
local displayGlobal = true

-- Should a warning be shown when people have your permissions too low.
local permissionWarn = true

-- The model part where the dialog should appear.
local dialogPivot = models.fishTextAssets.dialogModel.root.dialogPivot

-- Should first person subtitles be shown (Only visible for you).
local showSubtitle = false
local subtitleOffset = 60
local subtitleSize = 0.6
local subtitlePivot = models.fishTextAssets.dialogModel

--============================================================================--

local success, fishText = pcall(function ()
    return require(assetsPath..".fishText")
end)
assert(success, ((type(fishText) == "string" and string.find(fishText, "nonexistent") and "fishText was not found. Please download and add the script to the fishTextAssets folder.") or fishText))

local success, dialog = pcall(function ()
    return require(assetsPath..".dialogs."..dialogName)
end)
if not success then
    print("§4Failed to find your custom dialog (or it errored), reverting to default")
    dialog = fishText.defaultDialog
end

local canUseDialog = fishText:permissionCheck()
if canUseDialog then
    
    dialog = dialog.new(dialogPivot)
    fishText.primaryInstance = dialog

else-- If permissions are too low then change to extremely basic dialog to avoid erroring. 
    
    showSubtitle = false

    dialog = fishText.liteDialog.new(dialogPivot, permissionWarn)
    dialog.color = dialog.textColor

end

function pings.sendMessage(msg)
    if player:isLoaded() == false or not ENABLE_DIALOGUE then return end
    dialog:write(msg)
end

events.TICK:register(function()
    dialog:tick()
end, "localchat_dialog")

events.RENDER:register(function(delta, context)
    if context == "RENDER" or (showSubtitle == false and context == "PAPERDOLL") then
        dialog:render(delta)
        dialog:setVisible(true)
    else
        dialog:setVisible(false)
    end
end, "localchat_dialog")

-- Host only code
if host:isHost() then
    local windowSize = client.getScaledWindowSize().xy_

    local subtitle
    if showSubtitle then
        subtitle = dialog.new(subtitlePivot)
        subtitle:setParentType("GUI")
        subtitle:setPos(vec(-windowSize.x/2, -windowSize.y + subtitleOffset, 1))
        subtitle.textScale = subtitleSize
        subtitle.muted = true
        subtitle.lodEnabled = false
        subtitle:setFramesPerTick(1.5)
    end

    local function isSMPONLINE()
        local serverData = client:getServerData()
        return (serverData and serverData.ip and (string.find(serverData.ip, "carson") or string.find(serverData.ip, "online")))
    end

    local function showLocalchat(msg)
        pings.sendMessage(msg)
        if subtitle then subtitle:write(msg) end
    end

    function events.chat_send_message(msg)
        if string.sub(msg, 1, 1) == "/" then return msg end

        local isPrefixed = string.sub(msg, 1, 1) == prefix
        local useLocalchat = (isPrefixLocal and isPrefixed) or (isPrefixLocal == false and isPrefixed == false) or (USE_LOCALCHAT and ENABLE_DIALOGUE)
        local unprefixedMsg = (isPrefixed and string.sub(msg, 2, -1)) or msg

        if useLocalchat then
            
            showLocalchat(unprefixedMsg)
            host:appendChatHistory(msg)

            -- Uses the built in localchat if you are on the SMPONLINE server
            return (isSMPONLINE() and "/lc"..unprefixedMsg) or nil

        else
            if displayGlobal then showLocalchat(unprefixedMsg) end
            return unprefixedMsg
        end
    end

    if subtitle then
        events.TICK:register(function()
            subtitle:tick()
        end, "localchat_subtitle")

        events.RENDER:register(function(delta, context)
            if context == "FIRST_PERSON" and ENABLE_DIALOGUE then
                subtitle:setVisible(true)
                subtitle:render(delta)
            else
                subtitle:setVisible(false)
            end
        end, "localchat_subtitle")
    end

end