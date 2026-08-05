
---@class axoPlate
local axoPlate = {}
axoPlate.plates = {}

---@class plate
local plate = {}

---@param hex string Hex code formatted as #FFFFFF (no alpha)
function axoPlate.hexToRgbInt(hex)
    hex = hex:gsub("#","")  
    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)    
    return vec(r / 255, g / 255, b / 255)
end

local function getAttribute(attribute_name)
    local attrs = player:getNbt().attributes or {}
    for _, attr in ipairs(attrs) do
        if attr.id == attribute_name then
            return attr.base
        end
    end
    return 1 -- default
end

local permLevel = avatar:getPermissionLevel()
axoPlate.enoughPerms = permLevel == "HIGH" or permLevel == "MAX"
  
---@param root ModelPart The modelpart to attach your nameplate to, ex: models.model.root
---@param name string The identifying name of your nameplate, this is to make sure you can have multiple ex: "nameplate"
---@param text string What text should show up in your nameplate, ex: "${badges} :axolotl: Gali", allows toJson() objects
---@param color? string  Your whole text color, you can also set this in your text string with toJson({{text = "hi" color = "#123456"}})
---@param offset? Vector3 The offset from the default namepalte position above your head ex: vec(0, 5, 0) for slightly up | Default: vec(0, 0, 0)
---@param scale? Vector3 | number The scale of your nameplate | Default: 0.4
---@param shadow? boolean Whether your nameplate should have a shadow | Default: true
---@param outline? boolean Whether your nameplate should have an outline | Default: false
---@param outlineColor? string | Vector3
---@param background? boolean
function axoPlate:new(root, name, text, color, offset, scale, shadow, outline, outlineColor, background)
    ---@class plate
    local self = setmetatable({}, {__index = plate})
    
    assert(root, "§4Your nameplate model part is incorrect.§c")

    if color and type(color) == "string" then
        text = toJson({text = text, color = color})
    end
    if outlineColor and type(outlineColor) == "string" then
        outlineColor = axoPlate.hexToRgbInt(outlineColor)
    end

    self.root = root
    self.text = text
    self.offset = offset or vec(0, 0, 0)
    self.scale = scale or 0.4
    self.shadow = shadow or true
    self.outline = outline
---@diagnostic disable-next-line: param-type-mismatch
    self.outlineColor = outlineColor
    self.background = background or false

    axoPlate.plates[name] = self
    return self
end

local wasCrouching = false
local scaleOffsetModifier = vec(0, 1.0 ,0)
local function tickPlates()
    if wasCrouching ~= player:isCrouching() and player:getVariable("fishText").message == nil then
      for _, data in pairs(axoPlate.plates) do
        local p = data.ref
          if player:isCrouching() then
            p:setOpacity(0.5)
            p:setPos(vec(data.offset.x, data.offset.y - 5, data.offset.z) + scaleOffsetModifier) 
          else
            p:setOpacity(1.0)
            p:setPos(data.offset + scaleOffsetModifier)
          end
          wasCrouching = player:isCrouching()
      end
    end

    if world.getTime() % 10 == 0 then 
        scaleOffsetModifier.y = (1 - getAttribute("minecraft:generic.scale")) * 10
    end
end

if axoPlate.enoughPerms then events.ENTITY_INIT:register(function ()
    nameplate.ENTITY:setVisible(false)

    for name, p_ref in pairs(axoPlate.plates) do
        local root = p_ref.root:newPart(name)
        root:setPivot(0, 38, 0)
        
        local p = root:newText(name)
        root:setParentType("CAMERA")
        p:setAlignment("CENTER")
        p:setPos(p_ref.offset + vec(0, (1 - getAttribute("minecraft:generic.scale")) * 10, 0))
        p:setText(p_ref.text)
        p:setScale(p_ref.scale or 0.4)
        p:setShadow(p_ref.shadow or true)
        p:setOutline(p_ref.outline)
        ---@diagnostic disable-next-line: param-type-mismatch
        p:setOutlineColor(p_ref.outlineColor)
        p:background(p_ref.background)
        if p_ref.background then p:setBackgroundColor(vec(0.3, 0.3, 0.3)) end

        p_ref.ref = p
    end

    events.TICK:register(tickPlates)
end) end

return axoPlate