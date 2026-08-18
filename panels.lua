-- setup for Panels, an actionwheel replacement
-- this script is host only
if not host:isHost() then return end
local panels = require("panels.main")
local Util = require("util")

-- create new page called main
local main = panels.newPage("main")
panels.setPage(main)

-- Clothes switching --
local skins = {
    { texture = "skin", display = ":axolotl: Default" },
    { texture = "suit", display = ":mci_black_dye: Suit" },
}

local clothesPage = panels.newPage("Clothes")
for _, skin in ipairs(skins) do
    local toggle = clothesPage:newText()
        :setText(skin.display)
    toggle:onPress(function()
        pings.switchClothes(skin.texture)
        config:save("clothes", skin.texture)
    end)
end

clothesPage:newReturnButton()

main:newPageRedirect()
    :setText("Clothes")
    :setPage(clothesPage)
    :setIcon("theme", vec(0, 8, 8, 8), true)

main:newToggle()
    :setText(":hand: Pats")
    :setToggled(true)
    :onToggle(function (toggled)
        pings.togglePats(toggled)
    end)

main:newToggle()
    :setText(":typing: FishText")
    :setToggled(true)
    :onToggle(function (toggled, obj)
        pings.dialogue(toggled)
    end)


main:newToggle()
    :setText(":mcb_calibrated_skulk_sensor: Localchat")
    :onToggle(function (toggled, obj)
        pings.localchat(toggled)
    end)