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

function Util.getAttribute(attribute_name)
    local attrs = player:getNbt().attributes or {}
    for _, attr in ipairs(attrs) do
        if attr.id == attribute_name then
            return attr.base
        end
    end
    return 1 -- default
end

function Util.setClothes(texture)
    models.gali:setPrimaryTexture("CUSTOM", textures[texture])
    models.gali.root.Torso.Head.Face:setPrimaryTexture("CUSTOM", textures["expressions"])
end

return Util


