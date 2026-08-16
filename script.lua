require("api.GSAnimBlend")
local SwingingPhysics = require("api.swinging_physics")
local patpat = require("api.patpat")
local squapi = require("api.SquAPI")
local axoplate = require("api.axoplate")
local Util = require("util")
local localchatUI = require("localchatUI")
local swingOnHead = SwingingPhysics.swingOnHead
avatar:color(vec(0.72, 0.12, 0.3)) -- #B8204E

--hide models
vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(false)
vanilla_model.HELMET_ITEM:setVisible(true)
-- models.assets:setVisible(false)
Util.setClothes(config:load("clothes") or "skin")

-- nameplate
axoplate:new(models.gali.root, "nameplate", "${badges}:axolotl: Gali")
axoplate:new(models.gali.root, "afkPlate", toJson({ text = "${afk}", color = "#703aa6"}), nil, vec(0, 3, 0), 0.3)

events.ENTITY_INIT:register(function ()
  nameplate.All:setText(toJson({"Gali", {text = "${afk}", color = "gray"}}))
  nameplate.CHAT:setText("Gali")

  -- this has to be under entity init because the reference can only be accessed after entity init
  ActiveNameplate = axoplate.enoughPerms and axoplate.plates.nameplate.ref or nameplate.ENTITY
end)

-- eyes
squapi.eye:new(models.gali.root.Torso.Head.Eyes.Irises.LeftIris, 0.2, 1.0, 0.0, 0.0)
squapi.eye:new(models.gali.root.Torso.Head.Eyes.Irises.RightIris, 1.0, 0.2, 0.0, 0.0)

squapi.smoothHead:new(
    {models.gali.root.Torso, models.gali.root.Torso.Head},
		{0.1, 0.8},    --(1) strength(you can make this a table too)
    0.1,    --(0.1) tilt
    0.75,    --(1) speed
    true,    --(true) keepOriginalHeadPos
    nil,     --(true) fixPortrait
    nil,     --(nil) animStraightenList
    nil,     --(0.5) straightenMultiplier
    nil,     --(0.5) straightenSpeed
    nil      --(0.1) blendToConsiderStopped
)

swingOnHead(models.gali.root.Torso.Head.LeftGills, 0, {0,0,0,0,-45,45}, nil, nil, nil)
swingOnHead(models.gali.root.Torso.Head.RightGills, 0, {0,0,0,0,-45,45}, nil, nil, nil)

-- Localchat things --
ENABLE_DIALOGUE = true
USE_LOCALCHAT = false
local localchat_action = nil

function pings.dialogue(state)
  ENABLE_DIALOGUE = state
  if not ENABLE_DIALOGUE and USE_LOCALCHAT then
    localchat_action:setToggled(false)
    USE_LOCALCHAT = false
  end
end

function pings.localchat(state)
  USE_LOCALCHAT = state
  localchatUI.toggleLocalchat(state)
end

animations.gali.patted:blendTime(2, 10)

table.insert(patpat.onPat, function() -- if you dont specify if event is for player or player head it will use player as default
  animations.gali.patted:play()
  models.gali.root.Torso.Head.Face:setUVPixels(8, 0) -- set blushy face
end)
table.insert(patpat.onUnpat, function() -- if you dont specify if event is for player or player head it will use player as default
  animations.gali.patted:stop()
  models.gali.root.Torso.Head.Face:setUVPixels(0, 0) -- unset the blushy face
end)