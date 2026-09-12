-- ExplodeYourself by Gali
-- this is a simple script that adds a keybind to explode you

-- Config
local sampleTexture = "skin"              -- YOU HAVE TO CHANGE THIS TO YOUR SKIN TEXTURE, find the texture your avatar uses, and input its name here
local explosionKeybind = "key.keyboard.g" -- what keybind you want to explode with
local randomPalletteColors = 15           -- the amount of different colors for each explosion, these are randomly selected from your texture, !!! setting it too high will result in Ping Too Large !!!
local maxParticles = 500                  -- the amount of particles you spawn depends on what permissions other people have you at, but for MAX, this is your limit

if textures[sampleTexture] == nil then
    print("Failed to create texture pallette, supplied texture invalid or unset")
    return
end

-- Helper Functions
local function randomVelocity(speed)
    local theta = math.random() * math.pi * 2
    local z = math.random() * 2 - 1
    local r = math.sqrt(1 - z * z)

    return vec(
        r * math.cos(theta),
        z,
        r * math.sin(theta)
    ) * speed
end

local function randomSubset(tbl, count)
    local result = {}

    for i = 1, math.min(count, #tbl) do
        result[i] = tbl[i]
    end

    for i = count + 1, #tbl do
        local j = math.random(i)

        if j <= count then
            result[j] = tbl[i]
        end
    end

    return result
end

local function truncateVec(v)
    return vec(
        math.floor(v.x * 100) / 100,
        math.floor(v.y * 100) / 100,
        math.floor(v.z * 100) / 100
    )
end

local function textureToPallette(texture)
    local dim = texture:getDimensions()
    local width = dim.x
    local height = dim.y

    local pallette = {}
    local seen = {}

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local rgba = texture.getPixel(texture, x, y)

            if rgba.w >= 0.1 then
                local key = vectors.rgbToInt(rgba.xyz)

                if not seen[key] then
                    seen[key] = true

                    -- we truncate the colors to 2 decimals to save on size, because we're limited by the max ping size / sec
                    table.insert(pallette, truncateVec(rgba.xyz))
                end
            end
        end
    end

    return pallette
end

-- build pallette on init on the host, we dont build if the host is not on MAX (building the pallette is pretty heavy)
local explosionPallette = (host:isHost() and avatar:getPermissionLevel() == "MAX") and textureToPallette(textures[sampleTexture]) or nil
local nameplateState = true
events.ENTITY_INIT:register(function () nameplateState = nameplate.ENTITY:isVisible() end)

-- ping for spawning them
function pings.Explode(pressed, pallette)
    if not player:isLoaded() then return end

    if pressed then
        models.gali:visible(false)
        nameplate.ENTITY:setVisible(false)
    else
        models.gali:visible(true)
        nameplate.ENTITY:setVisible(nameplateState)
        return
    end

    local pos = player:getPos() + vec(0, player:getEyeHeight(), 0)
    for _ = 1, math.min(maxParticles, avatar:getRemainingParticles()) do
        particles["end_rod"]
            :pos(pos)
            :lifetime(200)
            :gravity(0)
            :scale(1)
            :color(pallette[math.random(#pallette)])
            :velocity(randomVelocity(math.random(10, 80) * 0.01))
            :spawn()
    end
end

local f3 = keybinds:newKeybind("explodeyourself-f3-check", "key.keyboard.f3")
local function explodeButton(pressed, modifiers)
    -- we make sure no modifiers are active and that we have permissions
    if f3:isPressed() or modifiers ~= 0 or not avatar:getPermissionLevel() == "MAX" then return end
    pings.Explode(pressed, randomSubset(explosionPallette, randomPalletteColors))
end

local key = keybinds:newKeybind("explode", explosionKeybind)
key.press = function(m) explodeButton(true, m) end
key.release = function(m) explodeButton(false, m) end
