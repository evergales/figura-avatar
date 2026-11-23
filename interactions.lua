local Util = require "util"
if not Util.Highperms() then return end

local lastTick
events.TICK:register(function ()
    local thisTick = world.getTime()
    if not player:isLoaded() or thisTick % 10 ~= 0 or thisTick == lastTick then return end
    lastTick = thisTick

    local pos = player:getPos() + vec(0, player:getEyeHeight(), 0);
    local rot = math.rad(player:getRot().y)
    local playerScale = Util.getAttribute("minecraft:generic.scale")

    local blockAtHead = world.getBlockState(pos)
    if blockAtHead.id == "minecraft:water" or blockAtHead.properties.waterlogged == "true" then
        local bubbleVel = vec(math.map(math.random(),0,1,-0.15,0.15), 0.15, math.map(math.random(),0,1,-0.15,0.15))
        local bubblePos = pos + vec(math.cos(rot), 0, -math.sin(rot)) * (math.random(2) == 1 and playerScale * 0.4 or -playerScale * 0.4)
        particle = particles:newParticle("minecraft:bubble", bubblePos, bubbleVel)
            :scale(0.2)
            :setGravity(-0.1)
            :setLifetime(60)
            :setPhysics(true)
    end
end)