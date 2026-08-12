---=== Ghasty's Freecam Integration v1.2 ===---                \__.'
-- originally made by Just_Ghasty / I'm just Ghasty
-- edited by evergaled
-- changes: cam transform is cached so no useless pings are sent, pings are more frequent
-- added some more configurability and a toggle event
-- returnCam attaches to the player instead of sending update packets (allows for the use of an animation for subtle hover)
-- PATTING

--== Easy Settings, if you do not want to do anything complex, this should be the only thing that needs changing. ==--
local playerFreeCam = models.follower.follower.Follower:parentType("WORLD") -- change to freecam model path
local returnCam = false -- This will return the freecam to the player if TRUE or stay in place after exiting if FALSE.
local hideOnExit = true -- Will hide the freecam after exiting if TRUE.
local showForSelf = false -- Whether to show the camera model for the host
local orbitAngle = -30 -- The position around the player as an angle (in degrees) when it is not being used.
local orbitDistOffset = vectors.vec3(1.3, 0, 0) -- Where the freecam will be when NOT in use, this is in FULL BLOCKS.
local updatesPerSecond = 4

--== Nameplate Settings, for if you want to give your Freecam a little nameplate that also mimics the player nameplate behaviour. ==--
local enableCamNameplate = false -- This will create a little Nameplate above for if you want your freecam to have one.
local camName = "litol" --<< What the freecam's nameplate will display.
local camName_bold = false
local camName_color = "#D54D6A"
local camName_offset = vectors.vec3(0, 10.0, 0) --<< Where the nameplate will be in relation to the model.
local camName_outline = { true, vectors.hexToRGB(camName_color) * 0.25 } --<< The Outline Enable and Colour, it's exactly what it sounds like.

-- == PATTING ==--
local enablePatting = true
local pattingPart = models.follower.follower.Follower.Axolotl -- The modelpart you want to squish and center on
local pattingSound = "entity.axolotl.idle_air"
local hitboxOffset = vec(0, 0, 0) -- offset the hitbox if your model is in a weird place in relation to the camera
local hitboxSize = 0.3 -- size going out in all directions from the center

--== Advanced Settings, for if you want a little more control out of your Freecam. ==--
local clarityDist = 0.0 -- How far BEHIND the camera the model will be IN freecam.
local clarityOffset = vectors.vec3(0, 0.15, 0) -- Where the freecam will be (relative to the Camera) when IN use, this is in FULL BLOCKS.
local delay = 0.10 -- The amount the interpolation will advance per frame (lower = slower but smoother, should never be more than 1)

--== Events ==--
local function onFreecamToggle(state) end

--== Important Variables, DO NOT EDIT ==--
local camIsFree = false
local camWasFree = false
local camNamePlate = nil
local freecamPos, freecamRot = vectors.vec3(0, 0, 0), vectors.vec2(0, 0)
local freecamPos_final, freecamRot_final = vectors.vec3(0, 0, 0),
    vectors.vec2(0, 0) -- Yes I know these could both just be vec, this is just for future-proofing.
local enoughPerms = avatar:getPermissionLevel() == "HIGH" or avatar:getPermissionLevel() == "MAX"
local playerLoaded = false


--== Tell other clients that you're in FreeCam Ping. ==--
---@param state boolean
---@param pos Vector3
---@param rot Vector2
function pings.inFreeCam(state, pos, rot)
  freecamPos = pos
  freecamRot = rot
  if (state) then
    playerFreeCam:setPos(pos * 16):setRot(rot.xy_)
  end
  if not host:isHost() then
    -- viewers derive the freecam state purely from the host's pings
    camIsFree = state
    playerFreeCam:setVisible(state)
  end
end

function pings.updateCamVisible(state)
  playerFreeCam:setVisible(state)
end

--== Entity_Init Event, will run once when the player entity loads, handles the Freecam's nameplate. ==--
function events.entity_init()
  playerFreeCam:visible(camIsFree)
  if enableCamNameplate then
    camNamePlate = playerFreeCam:newPart("namePivot", "CAMERA"):pivot(camName_offset)
        :newText("FCNP"):text(toJson({
          text = camName,
          bold = camName_bold,
          color = camName_color,
        })):alignment("CENTER"):scale(0.2)
        :outline(camName_outline[1]):outlineColor(camName_outline[2]):light(15)
  end
end

local function updateCamNameplate()
  camNamePlate
      ---@diagnostic disable-next-line: undefined-field
      :visible(client.isHudEnabled() and camIsFree)
      :opacity((not player:isCrouching() and 1) or 0.5)
      :outline(not player:isCrouching())
      :seeThrough(not player:isCrouching())
end

-- Cache last sent values
local lastCamPos = nil
local lastCamRot = nil

--== Tick Event, handles the Freecam's presence passively. ==--
function events.tick()
  playerLoaded = player:isLoaded()
  if not playerLoaded then return end

  -- Everything below is host-only: viewers get their state from pings.inFreeCam.
  -- (On a viewer's client, getCameraEntity() is the viewer, not this avatar's
  -- owner, so computing camIsFree locally is meaningless there.)
  if not host:isHost() then
    if (world.getTime() % math.floor(20 / updatesPerSecond) == 0) and enableCamNameplate then
      updateCamNameplate()
    end
    return
  end

  camIsFree = (client.getCameraEntity() ~= player) or (world.getPlayers().FreeCamera ~= nil)

  -- Ping the State, Pos, Rot only when something changed
  if (world.getTime() % math.floor(20 / updatesPerSecond) == 0) and camIsFree then
    if not camWasFree then
      if showForSelf then playerFreeCam:setVisible(true) end
      playerFreeCam:setParentType("WORLD")
    end

    local camPos = client.getCameraPos()
        - clarityOffset
        + (client.getCameraDir() * -clarityDist)

    local camRot = -client.getCameraRot().xy + vec(0, 180)

    local changed =
        (camWasFree ~= camIsFree)
        or (lastCamPos == nil)
        or (lastCamRot == nil)
        or (camPos ~= lastCamPos)
        or (camRot ~= lastCamRot)

    if changed then
      pings.inFreeCam(camIsFree, camPos, camRot)

      lastCamPos = camPos
      lastCamRot = camRot
    end

    if not camWasFree then onFreecamToggle(camIsFree) end
    camWasFree = camIsFree
  end

  -- Return Camera to Player if not in Freecam --
  if not camIsFree and camWasFree then
    if returnCam then
      playerFreeCam:setParentType("BODY")
      local dir = vectors.rotateAroundAxis(orbitAngle, orbitDistOffset, vec(0, 1, 0))
      freecamPos = vec(0, player:getEyeHeight() + orbitDistOffset.y, 0) +
          vectors.rotateAroundAxis(0, dir, vec(0, 1, 0))
      freecamRot = vec(0, 0) -- fixed forward, doesn't follow player
      pings.inFreeCam(false, freecamPos, freecamRot)
    end

    -- Hide Camera if not using Freecam and Hide is Enabled --
    if hideOnExit then pings.updateCamVisible(false) end
    onFreecamToggle(camIsFree)
    camWasFree = false
  end

  if (world.getTime() % math.floor(20 / updatesPerSecond) == 0) and enableCamNameplate then
    updateCamNameplate()
  end
end

--== PATTING ==--
--=======================================================================--
local targetpatScale = vectors.vec3(1, 1, 1)
local currentpatScale = vectors.vec3(1, 1, 1)
local patVelocity = vec(0, 0, 0)

local patReach = 4.5
local patStates = {} -- uuid -> { patting, resetTimer }
local activePats = 0

function pings.startPat()
  activePats = activePats + 1
  sounds:playSound(pattingSound, freecamPos, 1.0, 1.0, false)
  targetpatScale = vectors.vec3(1.2, 0.5, 1.2)
end

function pings.stopPat()
  activePats = math.max(activePats - 1, 0)
  if activePats == 0 then
    targetpatScale = vectors.vec3(1.0, 1.0, 1.0)
  end
end

local function isAimingAtFreecam(entity)
  local startPos = entity:getPos():add(0, entity:getEyeHeight(), 0)
  local endPos = startPos + entity:getLookDir() * patReach
  local lowerBound = freecamPos - vec(hitboxSize, hitboxSize, hitboxSize) + hitboxOffset
  local upperBound = freecamPos + vec(hitboxSize, hitboxSize, hitboxSize) + hitboxOffset
  return raycast:aabb(startPos, endPos, { { lowerBound, upperBound } }) ~= nil
end

local function tickPat()
  if not player:isLoaded() or (hideOnExit and not camIsFree) then return end

  local viewer = client:getViewer()
  local viewerInGui = viewer and (action_wheel:isEnabled() or host:getScreen() ~= nil)
  local seen = {}

  for _, entity in pairs(world.getPlayers()) do
    local uuid = entity:getUUID()
    seen[uuid] = true
    local state = patStates[uuid]

    if (freecamPos - entity:getPos()):length() <= 5 then
      if not state then
        state = { patting = false, resetTimer = 0 }
        patStates[uuid] = state
      end

      local inGui = viewerInGui and viewer:getUUID() == uuid

      if entity:isSwingingArm() and entity:getItem(1).id == "minecraft:air" and not state.patting and not inGui and isAimingAtFreecam(entity) then
        state.patting = true
        state.resetTimer = 5
        pings.startPat()
      end

      if state.resetTimer > 0 then state.resetTimer = state.resetTimer - 1 end
      if state.patting and state.resetTimer == 0 and not entity:isSwingingArm() then
        state.patting = false
        pings.stopPat()
      end
    elseif state then
      if state.patting then pings.stopPat() end
      patStates[uuid] = nil
    end
  end

  -- players that logged off mid-pat
  for uuid, state in pairs(patStates) do
    if not seen[uuid] then
      if state.patting then pings.stopPat() end
      patStates[uuid] = nil
    end
  end
end

--== World Render Event, may not run on Default Permissions. ==--
--=======================================================================--
function events.world_render()
  if playerLoaded then
    -- Freecam lerp position --
    if camIsFree then
      freecamPos_final = math.lerp(freecamPos_final, freecamPos * 16, delay)
      freecamRot_final = math.lerpAngle(freecamRot_final, freecamRot, delay)
      playerFreeCam:pos(freecamPos_final):rot(freecamRot_final.xy_)
    end
  
    -- patting physics
    -- this avatar singlehandedly makes world render instructions get up to 63/64 on default when running, and the patting goes over the limit
    -- so just disable the pat animation if we dont have perms for it
    if enoughPerms and enablePatting then
      -- stiffness = 0.35
      -- damping = 0.7
      patVelocity = (patVelocity + (targetpatScale - currentpatScale) * 0.35) * 0.7
      currentpatScale = currentpatScale + patVelocity
  
      pattingPart:scale(currentpatScale)
    end 
  end
end

--=======================================================================--

function events.entity_init()
  -- register the pat tick event if patting is enabled, and we're the host
  if enablePatting and host:isHost() then events.TICK:register(tickPat, "freecamPat") end
end