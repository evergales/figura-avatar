--== LOCALCHAT UI ==--
-- integrates fishText's localchat and makes local messages show up in the UI
-- made by: evergales

-- INTERNAL VARIABLES, DO NOT TOUCH
local localchatUI = {}
local version = "1.4"
local newVersionWarningShown = false

--== CONFIG ==--
local showSelf = true -- show your own messages in the localchat history
local ticksPerSecond = 10 -- how often your client will check for new messages
local trackingUpdatesPerSecond = 2 -- how often your client will update the list of players who are tracked in your localchat
local trackingDistance = 50 -- how far away players can be while you still see their localchat messsages (note: players outside your render distance wont show no matter what)
local showBadges = true -- Whether to show people's badges in chat

-- run this function under where you toggle your localchat
-- your localchat state is false by default, if you dont set it through this, it will stay false
function localchatUI.toggleLocalchat(state)
    pings.toggleLocalChat(state)
end

------------------------------------------------------------------

local trackedChatters = {}  -- uuid -> { player, lastMessage, lastSeen }

local function exportVariables()
    avatar:store("localchatUI.version", version)
    avatar:store("localchatUI.name", nameplate.CHAT:getText())
    avatar:store("localchatUI.badge", avatar:getBadges())
end

local function updateTrackedChatters()
    if world.getTime() % math.floor(20 / trackingUpdatesPerSecond) ~= 0 then return end
    local now = world.getTime()
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

    -- remove chatters if they leave range or disappear after a 5 second grace period
    local timeout = 5 * 20  -- 5 seconds in ticks
    for uuid, data in pairs(trackedChatters) do
        if not nearby[uuid] and (now - data.lastSeen) > timeout then
            trackedChatters[uuid] = nil
        end
    end
end

local function tickLocalchat()
    if world.getTime() % math.floor(20 / ticksPerSecond) ~= 0 then return end

    for _, data in pairs(trackedChatters) do
        local p = data.player
        local newMessage = p:getVariable("localchatUI.message")
        if newMessage -- check if the player has a message var
        and (not data.lastMessage or data.lastMessage.sent ~= newMessage.sent) -- check if the player has sent a new message since our stored one (or whether its the first)
        and (data.startedTracking < newMessage.sent) then -- check whether the player's last sent message was before we started tracking them
            data.lastMessage = newMessage
            local playerName = p:getVariable("localchatUI.name")
            local isLocalChatting = p:getVariable("localchatUI.isLocalChatting")
            local badge = p:getVariable("localchatUI.badge")

            local formattedName = playerName or string.format('{ text = %s, color = "gray"}', p:getName())
            local formattedBadge = badge and toJson({ text = badge, font = "figura:badges" }) or nil
            if isLocalChatting then
                -- printJson is only visible to the host unless another player has logging for non-host enabled
                printJson(
                    toJson({ text = "[", color = "gray" }),
                    formattedName,
                    (showBadges and formattedBadge ~= nil) and formattedBadge or "",
                    toJson({ text = "] "..newMessage.message, color = "gray"})
                )
            end
        end
    end
end

function pings.toggleLocalChat(state) avatar:store("localchatUI.isLocalChatting", state) end

function pings.updateMessage(msg) -- the CHAT_SEND_MESSAGE event is host only, so we have to tell other clients to actually update the message
    avatar:store("localchatUI.message", {message = msg, sent = world.getTime()})
end

local fishTextPresent = false
events.CHAT_SEND_MESSAGE:register(function (msg)
    if string.sub(msg, 1, 1) == "/" then return msg end

    if player:getVariable("localchatUI.isLocalChatting") then
        pings.updateMessage(msg)
        return fishTextPresent and msg or nil -- if fishtext is present, allow it to hide messages instead of this script, returning nil will error in that case
    end

    return msg
end)

-- this script should only ever run on the host, syncing is done via player variables
if host:isHost() then events.TICK:register(function()
    updateTrackedChatters()
    tickLocalchat()
end) end

local function init()
    if not player:isLoaded() then return end -- wait until the entity is in range and then export vars
    fishTextPresent = pcall(require, "localchat") -- test whether fishText localchat is present (has to be in the same folder)
    exportVariables()
    events.TICK:remove(init)
end
events.TICK:register(init)

-- clear tracked chatter list when resource reload
pings.reinit = exportVariables
if host:isHost() then events.RESOURCE_RELOAD:register(function ()
    for chatter in pairs (trackedChatters) do
        trackedChatters[chatter] = nil
    end
    pings.reinit()
end) end

return localchatUI