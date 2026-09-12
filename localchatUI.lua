--== LOCALCHAT UI ==--
-- integrates fishText's localchat and makes local messages show up in the UI
-- made by: evergales

--== CONFIG ==--
local showSelf = true -- show your own messages in the localchat history
local showLocalchatIcon = true -- shows a small icon in your UI to tell if you're in localchat or not
local ticksPerSecond = 10 -- how often your client will check for new messages
local trackingUpdatesPerSecond = 1 -- how often your client will update the list of players who are tracked in your localchat
local trackingDistance = 64 -- how far away players can be while you still see their localchat messsages (note: players outside your render distance wont show no matter what)
local showBadges = true -- Whether to show people's badges in chat

-- INTERNAL VARIABLES, DO NOT TOUCH
local localchatUI = {}
local version = "1.6"
local newVersionWarningShown = false
local localchatPopup = models:newPart("", "HUD"):newText("")
    :setVisible(false)
    :setText(":speech_bubble:")
    :setScale(1.2)
    :setPos(-5, -client:getScaledWindowSize().y + 27)
    :setOutline(true)
    :setOutlineColor(0.37, 0.58, 0.74)

-- run this function under where you toggle your localchat
-- your localchat state is false by default, if you dont set it through this, it will stay false
function localchatUI.toggleLocalchat(state)
    local shouldShow = state and showLocalchatIcon
    localchatPopup:setVisible(shouldShow)
    pings.toggleLocalChat(state)
end

------------------------------------------------------------------

local trackedChatters = {}  -- uuid -> { player, lastMessage, lastSeen }

local function exportVariables()
    avatar:store("localchatUI.version", version)
    avatar:store("localchatUI.name", nameplate.CHAT:getText() or player:getName())
    avatar:store("localchatUI.badge", avatar:getBadges())
    avatar:store("localchatUI.color", avatar:getColor())
end

local function updateTrackedChatters(now)
    if now % math.floor(20 / trackingUpdatesPerSecond) ~= 0 then return end
    local nearby = {}

    -- scan nearby players
    for _, p in pairs(world.getPlayers()) do -- world.getPlayers() is indexed by player name, we'll index by uuid instead
        local distance = (player:getPos() - p:getPos()):length()
        if distance <= trackingDistance then
            local uuid = p:getUUID()
            nearby[uuid] = true

            -- if already tracked, just refresh the player reference and timestamp
            -- player reference is refreshed as a failsafe to not get stale playerdata later on
            if trackedChatters[uuid] then
                trackedChatters[uuid].player = p
                trackedChatters[uuid].lastSeen = now
            else
                -- new potential chatter: check fishText existence
                local playerVersion = p:getVariable("localchatUI.version")
                if playerVersion and (uuid ~= player:getUUID() or showSelf) then
                    trackedChatters[uuid] = {
                        player = p,
                        name = p:getVariable("localchatUI.name"),
                        badge = p:getVariable("localchatUI.badge"),
                        color = p:getVariable("localchatUI.color"),
                        lastMessage = nil,
                        lastSeen = now,
                        startedTracking = now
                    }

                    -- version check against other players to alert if a new version is available
                    -- only shown once per session
                    if not newVersionWarningShown then
                        if playerVersion and version < playerVersion then
                            printJson(toJson({
                                text = "Someone around you is using a newer version of Localchat UI! Your messages might be incompatible, Please update.",
                                color = "gold"
                            }))
                            newVersionWarningShown = true
                        end
                    end
                end
            end
        end
    end -- dont even

    -- remove chatters if they leave range or disappear after a 10 second grace period
    local timeout = 10 * 20  -- 10 seconds in ticks
    for uuid, data in pairs(trackedChatters) do
        if not nearby[uuid] and (now - data.lastSeen) > timeout then
            trackedChatters[uuid] = nil
        end
    end
end

--- @type Vector3
local lastPos = nil
local function tickLocalchat(now)
    if now % math.floor(20 / ticksPerSecond) ~= 0 then return end

    for _, data in pairs(trackedChatters) do
        local p = data.player
        local newMessage = p:getVariable("localchatUI.message")
        if newMessage -- check if the player has a message var
        and (not data.lastMessage or data.lastMessage.sent ~= newMessage.sent) -- check if the player has sent a new message since our stored one (or whether its the first)
        and (data.startedTracking < newMessage.sent) then -- check whether the player's last sent message was before we started tracking them
            data.lastMessage = newMessage
            local formattedBadge = data.badge and toJson({ text = data.badge, font = "figura:badges", color = data.badge == "△" and data.color or nil }) or nil
            if p:getVariable("localchatUI.isLocalChatting") then
                -- printJson is only visible to the host unless another player has logging for non-host enabled
                printJson(
                    toJson({ text = "[", color = "gray" }),
                    data.name,
                    showBadges and formattedBadge or "",
                    toJson({ text = "] "..newMessage.message, color = "gray"}),
                    "\n"
                )
            end
        end
    end

    -- periodically refresh the local chatting state from the host
    -- executed every 15 seconds or when the player moves a large amount of blocks in a single tick like teleporting (using the tracking distance as a base)
    if now % 300 == 0 or lastPos and (player:getPos().xy - lastPos.xy):length() > trackingDistance then
        pings.toggleLocalChat(player:getVariable("localchatUI.isLocalChatting"))
    end

    lastPos = player:getPos()
end

function pings.toggleLocalChat(state) avatar:store("localchatUI.isLocalChatting", state) end

function pings.updateMessage(msg) -- the CHAT_SEND_MESSAGE event is host only, so we have to tell other clients to actually update the message
    avatar:store("localchatUI.message", {message = msg, sent = world.getTime()})
end

local fishTextPresent = false
events.CHAT_SEND_MESSAGE:register(function (msg)
    if string.sub(msg, 1, 1) == "/" then return msg end -- ignore / commands

    if player:getVariable("localchatUI.isLocalChatting") then
        pings.updateMessage(msg)
        return fishTextPresent and msg or nil -- if fishtext is present, allow it to hide messages instead of this script, returning nil will error in that case
    end

    return msg
end)

-- this script should only ever run on the host, syncing is done via player variables
if host:isHost() then events.TICK:register(function()
    local now = world.getTime()
    updateTrackedChatters(now)
    tickLocalchat(now)
end) end

local function init()
    if not player:isLoaded() then return end -- wait until the entity is in range and then export vars
    fishTextPresent = pcall(require, "localchat") -- test whether fishText localchat is present (has to be in the same folder)
    exportVariables()
    events.TICK:remove(init)
end
events.TICK:register(init)

return localchatUI