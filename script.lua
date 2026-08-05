local Util = require("util")
local localchatUI = require("localchatUI")
local fishText = require("fishTextAssets.fishText")
local axoplate = require("api.axoplate")

require("api.GSAnimBlend")
local SwingingPhysics = require("api.swinging_physics")
local patpat = require("api.patpat")
local squapi = require("api.SquAPI")
local placeholders = require("api.placeholders")
local swingOnHead = SwingingPhysics.swingOnHead
avatar:color(vec(0.72, 0.12, 0.3)) -- #B8204E

--hide models
vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(false)
vanilla_model.HELMET_ITEM:setVisible(true)
models.assets:setVisible(false)

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

local mainPage = action_wheel:newPage()
action_wheel:setPage(mainPage)

function pings.switchSkin(skin)
    Util.ParticleCircle(1, 15, "minecraft:trial_spawner_detection_ominous")
    models.gali:setPrimaryTexture("CUSTOM", textures[skin])
    models.gali.root.Torso.Head.Face:setPrimaryTexture("CUSTOM", textures["expressions"])
end

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

mainPage:newAction()
    :title("Suit Skin")
    :item("minecraft:netherite_chestplate")
    :hoverColor(0.169, 0.141, 0.153)
    :onLeftClick(function() pings.switchSkin("suit") end)
mainPage:newAction()
    :title("Default Skin")
    :item("minecraft:leather_chestplate")
    :hoverColor(0.89, 0.235, 0.412)
    :onLeftClick(function() pings.switchSkin("skin") end)

localchat_action = mainPage:newAction()
    :title("Local Chat Disabled")
    :toggleTitle("Local Chat Enabled")
    :item("minecraft:blaze_rod")
    :toggleItem("minecraft:breeze_rod")
    :hoverColor(0.86, 1.0, 0.97)
    :toggleColor(0.541, 1.0, 0.769)
    :setOnToggle(pings.localchat)
    :setToggled(USE_LOCALCHAT)
mainPage:newAction()
    :title("Dialogue Disabled")
    :toggleTitle("Dialogue Enabled")
    :texture(textures["assets.chat-bubble-disabled"], nil, nil, nil, nil, 2.5)
    :toggleTexture(textures["assets.chat-bubble"], nil, nil, nil, nil, 2.5)
    :hoverColor(0.86, 1.0, 0.97)
    :toggleColor(0.541, 1.0, 0.769)
    :setOnToggle(pings.dialogue)
    :setToggled(ENABLE_DIALOGUE)

animations.gali.patted:blendTime(2, 10)

table.insert(patpat.onPat, function() -- if you dont specify if event is for player or player head it will use player as default
  animations.gali.patted:play()
  models.gali.root.Torso.Head.Face:setUVPixels(8, 0) -- set blushy face
end)
table.insert(patpat.onUnpat, function() -- if you dont specify if event is for player or player head it will use player as default
  animations.gali.patted:stop()
  models.gali.root.Torso.Head.Face:setUVPixels(0, 0) -- unset the blushy face
end)

-- stupidass create wonky cam fix
if host:isHost() then
  events.WORLD_RENDER:register(function(delta)
    -- checks for freecam
    -- checks if we're specifically sitting on a create seat
    if not ((client.getCameraEntity() ~= player) or (world.getPlayers().FreeCamera ~= nil)) and player:getVehicle() and player:getVehicle():getType() == "create:seat" then
      renderer:setCameraRot(((player:getRot(delta).xy_ + vec(0, renderer:isCameraBackwards() and 180 or 0, 0))) * vec(renderer:isCameraBackwards() and -1 or 1, 1, 1))
    else
      renderer:setCameraRot() -- remove any override if we're not seated or in freecam
    end
  end)
end