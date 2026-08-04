-- LOCALCHAT UI --
-- integrates fishText's localchat and makes local messages show up in the UI
-- made by: evergales
local localchatUI = {} -- IGNORE, defines exported things

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

local trackedChatters = {}
local Chatter = {}
Chatter.__index = Chatter.uuid

function Chatter.new(player)
    local self = setmetatable({}, Chatter)

    self.uuid = player:getUUID()
    self.player = player
    self.lastMessage = nil

    return self
end

local function updateTrackedChatters()
    if world.getTime() % math.floor(20 / trackingUpdatesPerSecond) ~= 0 then return end
    local nearby = {}
    -- Scan nearby players
    for _, p in pairs(world.getPlayers()) do
        local distance = (player:getPos() - p:getPos()):length()

        if distance <= trackingDistance then -- ignore if outside of tracking distance
            local uuid = p:getUUID()
            nearby[uuid] = true

            -- add to tracking list if they have fishText
            local playerFishText = p:getVariable("fishText")
            if playerFishText and not trackedChatters[uuid] then
                if uuid ~= player:getUUID() or showSelf then
                    trackedChatters[uuid] = Chatter.new(p)
                end
            end
        end
    end

    -- Remove players that disappeared or left range
    for uuid, _ in pairs(trackedChatters) do
        if not nearby[uuid] then
            trackedChatters[uuid] = nil
        end
    end
end

local function tickLocalchat()
    if world.getTime() % math.floor(20 / ticksPerSecond) ~= 0 then return end

    for _, chatter in pairs(trackedChatters) do
        local fishText = chatter.player:getVariable("fishText")
        local newMessage = fishText and fishText.message or nil

        -- check if the player has sent a new message since our stored one
        if newMessage and chatter.lastMessage ~= newMessage then
            chatter.lastMessage = newMessage
            local playerName = chatter.player:getVariable("localchatUI.name")
            local isLocalChatting = chatter.player:getVariable("localchatUI.isLocalChatting")
            local formattedName = playerName or string.format('{ text = %s, color = "gray"}', chatter.player:getName())

            -- show a message in chat with their fishText message
            if isLocalChatting
            or (isLocalChatting == nil and not ignoreNonScriptUsers) then
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
-- and store the player's custom nameplate as their name
if host:isHost() then events.ENTITY_INIT:register(function()
    local function nextTick()
        avatar:store("localchatUI.name", nameplate.CHAT:getText() or player:getName())
        avatar:store("localchatUI.isLocalChatting", defaultLocalchatEnabled)

        events.TICK:remove(nextTick)
    end
    events.TICK:register(nextTick)
end) end

return localchatUI