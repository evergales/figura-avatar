local Util = require("util")

FakeName = nil
local function fakeNameplate(root, name, offset, scale, text)
    local task = root:newText(name)
    root:setParentType("CAMERA")
    task:setPos(offset)
    task:setText(text)
    task:setScale(scale)
    task:setAlignment("CENTER")
    task:setShadow(true)
    -- task:setOutline(true)
    -- task:setBackgroundColor(vec(0.3, 0.3, 0.3))
    return task
  end
  
local wasCrouching = false
local nameplateOffset = 0
function events.entity_init()
  nameplate.All:setText(toJson({"Gali", {text = "${afk}", color = "gray"}}))
  nameplate.CHAT:setText("Gali")
  nameplate.ENTITY:setVisible(false)

  local permLevel = avatar:getPermissionLevel()
  if permLevel == "HIGH" or permLevel == "MAX" then
    nameplateOffset = (1 - Util.getAttribute("minecraft:generic.scale")) * 10
    FakeName = fakeNameplate(models.gali.root.nameplate, "nameplate", vec(0,nameplateOffset, 0), 0.4, "${badges}:axolotl: Gali")
    fakeNameplate(models.gali.root.nameplate, "afk",  vec(0, nameplateOffset + 3, 0), 0.3, toJson({ text = "${afk}", color = "#703aa6"}))

    events.TICK:register(function ()
      if wasCrouching ~= player:isCrouching() and player:getVariable("fishText").message == nil then
        if player:isCrouching() then
          FakeName:setOpacity(0.5)
          FakeName:setPos(vec(0, nameplateOffset - 5, 0))
        else
          FakeName:setOpacity(1.0)
          FakeName:setPos(vec(0, nameplateOffset, 0))
        end
        wasCrouching = player:isCrouching()
      end
    end)
  end
  ActiveNameplate = FakeName or nameplate.ENTITY 
end

function pings.updateNameplateOffset(offset) 
    nameplateOffset = offset
    FakeName:setPos(vec(0, nameplateOffset, 0))
end
if host:isHost() then events.TICK:register(function ()
    if world.getTime() % 10 ~= 0 then return end
    local newOffset = (1 - Util.getAttribute("minecraft:generic.scale")) * 10
    if nameplateOffset ~= newOffset then
        pings.updateNameplateOffset(newOffset)
    end
end) end