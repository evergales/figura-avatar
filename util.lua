local Util = {}

function Util.ParticleCircle(radius, count, particle)
    local pos = player:getPos()

    for i = 0, count - 1 do
        local angle = (math.pi * 2) * (i / count)

        local x = pos.x + math.cos(angle) * radius
        local z = pos.z + math.sin(angle) * radius
        local y = pos.y + 1

        particles:newParticle(
            particle or "minecraft:end_rod",
            x, y, z
        )
    end
end

return Util


