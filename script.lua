require("api.GSAnimBlend")
local patpat = require("api.patpat")
local squapi = require("api.SquAPI")
local axoplate = require("api.axoplate")
local Util = require("util")
local localchatUI = require("localchatUI")
local SwingingPhysics = require("api.swinging_physics")

State = {}
State.clothes = config:load("clothes") or "skin"
State.accessories = { newsboy = config:load("accessories.newsboy") or false }
State.dialogue = true
State.localchat = false
State.pats = false

function pings.syncState(hostState)
  if State.clothes ~= hostState.clothes then Util.setClothes(hostState.clothes) end
  if State.pats ~= hostState.pats then avatar:store("patpat.noPats", not hostState.pats) end
  if State.accessories.newsboy ~= hostState.accessories.newsboy then models.gali.root.Torso.Head.Newsboy:setVisible(hostState.accessories.newsboy) end

  State = hostState
end
if host:isHost() then events.TICK:register(function ()
  if not player:isLoaded() or world.getTime() % 200 ~= 0 then return end
  pings.syncState(State)
end) end

--hide models
vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(false)
vanilla_model.HELMET_ITEM:setVisible(true)
-- models.assets:setVisible(false)
Util.setClothes(config:load("clothes") or "skin")
models.gali.root.Torso.Head.Newsboy:setVisible(config:load("accessories.newsboy") or false)

-- nameplate
axoplate:new(models.gali.root, "nameplate", "${badges}:axolotl: Gali")
axoplate:new(models.gali.root, "afkPlate", toJson({ text = "${afk}", color = "#703aa6"}), nil, vec(0, 3, 0), 0.3)

events.ENTITY_INIT:register(function ()
  nameplate.All:setText(toJson({"Gali", {text = "${afk}", color = "gray"}}))
  nameplate.CHAT:setText("Gali")

  -- this has to be under entity init because the reference can only be accessed after entity init
  ActiveNameplate = axoplate.enoughPerms and axoplate.plates.nameplate.ref or nameplate.ENTITY
end)

SwingingPhysics.swingOnHead(models.gali.root.Torso.Head.Fluff, 0, {-5, 5, 0, 0, -10, 10}, nil, nil, nil)
SwingingPhysics.swingOnHead(models.gali.root.Torso.Head.RightGills.RightGillsRing, -90, {-30, 30, -10, 10, -10, 10}, nil, nil, nil)

SwingingPhysics.swingOnHead(models.gali.root.Torso.Head.Newsboy.Flower, 10, {-10, 10, 0, 0, -10, 10}, nil, nil, nil)
SwingingPhysics.swingOnHead(models.gali.root.Torso.Head.Newsboy.Flower2, -120, {-5, 5, -5, 5, -5, 5}, nil, nil, nil)

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

squapi.ear:new(
    models.gali.root.Torso.Head.LeftGills, --leftEar
    models.gali.root.Torso.Head.RightGills, --(nil) rightEar
    0.35, --(1) rangeMultiplier
    true, --(false) horizontalEars
    1.3, --(2) bendStrength
    false, --(true) doEarFlick
    nil, --(400) earFlickChance
    0.1, --(0.1) earStiffness
    0.8  --(0.8) earBounce
)

-- pings --

function pings.switchClothes(texture)
    if not player:isLoaded() then return end
    Util.ParticleCircle(1, 15, "minecraft:trial_spawner_detection_ominous")
    Util.setClothes(texture)
end

local accessoryParts = { ["newsboycap"] = models.gali.root.Torso.Head.Newsboy }
function pings.toggleAcessory(part, state)
  accessoryParts[part]:setVisible(state)
end

-- Localchat things --
local localchat_action = nil
function pings.dialogue(state)
  State.dialogue = state
  if not State.dialogue and State.localchat then
    localchat_action:setToggled(false)
    State.localchat = false
  end
end

function pings.localchat(state)
  State.localchat = state
  localchatUI.toggleLocalchat(state)
end

function pings.togglePats(state)
  avatar:store("patpat.noPats", not state)
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