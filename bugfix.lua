-- neoforge action wheel title tooltip bug fix from figura discord by: manuel_2867
-- modified by evergales to look nicer
--[[ if host:isHost() then
  local task = models:newPart("", "GUI"):newText("")
    :setOutline(true)
    :setOutlineColor(0, 0, 0)

  events.RENDER:register(function()
    local action = action_wheel:getSelectedAction()

    task:setVisible(action_wheel:isEnabled() and action)
    if not action then return end

    local text = action:isToggled() and action:getToggleTitle() or action:getTitle()
    local color =  action:getColor() or "#FFFFFF"

    local scaled = client:getScaledWindowSize()
    local mouse = client:getMousePos() / client:getWindowSize() * scaled
    local center = scaled / 2

    -- direction from the wheel center toward the cursor.
    local dir = mouse - center
    if dir:length() < 0.001 then
      dir = vec(0, -1)
    else
      dir = dir:normalize()
    end

    -- place the tooltip outside the wheel.
    local radius = 90
    local pos = -(center + dir * radius).xy_

    task:setPos(pos)
    task:setAlignment(dir.x >= 0 and "LEFT" or "RIGHT")

    task:setText(toJson{
      text = text,
      color = color
    })
  end)
end ]]

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