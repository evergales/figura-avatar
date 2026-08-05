--== LOCALCHAT UI ==--
-- integrates fishText's localchat and makes local messages show up in the UI
-- made by: evergales

-- INTERNAL VARIABLES, DO NOT TOUCH
local localchatUI = {}
local version = "1.2"
local newVersionWarningShown = false

--== CONFIG ==--
local defaultLocalchatEnabled = false -- whether localchat is enabled by default on your avatar
local ignoreNonScriptUsers = true -- doesnt show messages for people who dont have this script installed
local showSelf = true -- show your own messages in the localchat history
local ticksPerSecond = 10 -- how often your client will check for new messages
local trackingUpdatesPerSecond = 2 -- how often your client will update the list of players who are tracked in your localchat
local trackingDistance = 50 -- how far away players can be while you still see their localchat messsages (note: players outside your render distance wont show no matter what)

-- run this function under where you toggle your localchat
-- if you dont do this, you will always show up in chat for other people regardless of if localchat is enabled for you
function localchatUI.toggleLocalchat(state)
    avatar:store("localchatUI.isLocalChatting", state)
end

local trackedChatters = {}  -- uuid -> { player, lastMessage, lastSeen }

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
                local fishText = p:getVariable("fishText")
                if fishText and (uuid ~= player:getUUID() or showSelf) then
                    trackedChatters[uuid] = {
                        player = p,
                        lastMessage = fishText.message,
                        lastSeen = now
                    }

                    -- version check against other players to alert if a new version is available
                    -- only shown once per session
                    if not newVersionWarningShown then
                        local theirVersion = p:getVariable("localchatUI.version")
                        if theirVersion and version < theirVersion then
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
        local fishText = p:getVariable("fishText")
        local newMessage = fishText and fishText.message
        if newMessage and data.lastMessage ~= newMessage then -- check if the player has sent a new message since our stored one
            data.lastMessage = newMessage
            local playerName = p:getVariable("localchatUI.name")
            local isLocalChatting = p:getVariable("localchatUI.isLocalChatting")
            local formattedName = playerName or string.format('{ text = %s, color = "gray"}', p:getName())
            if isLocalChatting or (isLocalChatting == nil and not ignoreNonScriptUsers) then
                -- printJson is only visible to the host unless another player has logging for non-host enabled
                printJson(
                    toJson({ text = "[", color = "gray" }),
                    formattedName,
                    toJson({ text = "] "..newMessage, color = "gray"})
                )
            end
        end
    end
end

-- this script should only ever run on the host, syncing is done via player variables
if host:isHost() then events.TICK:register(function()
    updateTrackedChatters()
    tickLocalchat()
end) end

-- wait 1 tick for the nameplate to be loaded because of entity init registration order T-T
-- and store synced variables
events.ENTITY_INIT:register(function()
    local function nextTick()
        avatar:store("localchatUI.version", version)
        avatar:store("localchatUI.name", nameplate.CHAT:getText() or player:getName())
        avatar:store("localchatUI.isLocalChatting", defaultLocalchatEnabled)

        events.TICK:remove(nextTick)
    end
    events.TICK:register(nextTick)
end)

-- clear tracked chatter list when resource reload
if host:isHost() then events.RESOURCE_RELOAD:register(function () trackedChatters = {} end) end

return localchatUI