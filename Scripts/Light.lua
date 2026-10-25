---@class Light : ShapeClass
Light = class()
Light.colorNormal = sm.color.new("#FEEA6D")
Light.colorHighlight = sm.color.new("#FFF19C")
Light.maxParentCount = 2
Light.maxChildCount = 0
Light.connectionInput = 1
Light.connectionOutput = 0
Light.poseWeightCount = 1

local strengthStepsFull = 25
local strengthStepsNormal = 10

function Light:server_onCreate()
    local saved = self.storage:load() or {}
    self.sv_bulbColour = saved.bulbColour or self.shape.color
    self.sv_strength = saved.strength or strengthStepsNormal / 2
    self.sv_range = saved.range or GetEffectRange(self.data.effect)

    local defaultState = saved.defaultState
    if defaultState ~= nil then
        self.sv_defaultState = defaultState
    else
        self.sv_defaultState = true
    end

    self:sv_updateStorage()

    self.sv_paintBulb = false
end

function Light:server_onFixedUpdate()
    -- if not self.sv_paintBulb then return end

    -- if self.sv_originalColour ~= self.shape.color then
    --     self.sv_bulbColour = self.shape.color
    --     self.shape.color = self.sv_originalColour
    --     self:sv_updateStorage()
    -- end

    local colourInput = self.interactable:getParents(2)[1]
    if not colourInput then return end

    local colour = colourInput.shape.color
    if colour ~= self.sv_bulbColour then
        self.sv_bulbColour = colour
        self:sv_updateStorage()
    end
end

function Light:sv_updateStorage()
    local saved = {
        bulbColour = self.sv_bulbColour,
        strength = self.sv_strength,
        range = self.sv_range,
        defaultState = self.sv_defaultState
    }
    self.storage:save(saved)
    self.network:setClientData(saved, 1)
end

function Light:sv_lightStrengthChanged(value)
    self.sv_strength = value
    self:sv_updateStorage()
end

function Light:sv_lightRangeChanged(value)
    self.sv_range = value
    self:sv_updateStorage()
end

function Light:sv_defaultStateChanged(value)
    self.sv_defaultState = value
    self:sv_updateStorage()
end

function Light:sv_colourPaintMode()
    self.sv_paintBulb = not self.sv_paintBulb
    if self.sv_paintBulb then
        self.sv_originalColour = self.shape.color
    end

    self.network:setClientData(self.sv_paintBulb, 2)
end



function Light:client_onCreate()
    self.cl_bulbColour = self.shape.color
    self.cl_strength = 5
    self.cl_range = GetEffectRange(self.data.effect)
    self.cl_paintBulb = false
    self.cl_baseIntensity = GetEffectIntensity(self.data.effect)
    self.cl_defaultState = true
end

function Light:client_onUpdate()
    self:cl_updateLightEffect()

    if sm.exists(self.gui) and self.gui:isActive() then
        self:cl_updateUI()
    end
end

function Light:client_onFixedUpdate()
    if self.lightStrengthChanged then
        self.lightStrengthChanged = self.lightStrengthChanged - 1
        if self.lightStrengthChanged <= 0 then
            self.network:sendToServer("sv_lightStrengthChanged", self.cl_strength)
            self.lightStrengthChanged = nil
        end
    end

    if self.lightRangeChanged then
        self.lightRangeChanged = self.lightRangeChanged - 1
        if self.lightRangeChanged <= 0 then
            self.network:sendToServer("sv_lightRangeChanged", self.cl_range)
            self.lightRangeChanged = nil
        end
    end
end

function Light:client_getAvailableParentConnectionCount(flags)
    if bit.band(flags, 2) > 0 then
        return 1 - #self.interactable:getParents(2)
    end

    return 1
end

function Light:client_onClientDataUpdate(data, channel)
    if channel == 1 then
        self.cl_bulbColour = data.bulbColour
        self.cl_strength = data.strength
        self.cl_range = data.range
        self.cl_defaultState = data.defaultState

        self:cl_updateLightEffect()
    else
        self.cl_paintBulb = data
    end
end

function Light:client_canInteract(char)
    --if sm.localPlayer.getInventory():canSpend(obj_consumable_inkammo, 1) then
    if sm.localPlayer.getActiveItem() == tool_paint then
        if #self.interactable:getParents(2) > 0 then
            sm.gui.setInteractionText("<p textShadow='false' bg='gui_keybinds_bg_white' color='#444444' spacing='9'>#{ALERT_CONTROL_OVERRIDE}</p>")
        else
            sm.gui.setInteractionText(sm.gui.getKeyBinding("Use", true).."#{INTERACTION_USE}\t", sm.gui.getKeyBinding("Tinker", true).."Toggle paint mode", "")
            if self.cl_paintBulb then
                sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Paint the bulb")
            else
                sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Paint the casing")
            end
        end
    else
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true), "#{INTERACTION_USE}\t")
        sm.gui.setInteractionText("")
    end
    --end

    return true
end

function Light:client_onInteract(char, state)
    if not state then return end

    if not self.gui then
        local maxRange = GetEffectMaxRange(self.data.effect)
        local gui
        if maxRange == -1 then
            gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Light_norange.layout")
            gui:createHorizontalSlider("intensity", strengthStepsFull, strengthStepsNormal / 2, "cl_lightStrengthChanged", true)
        else
            gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Light.layout")
            gui:createHorizontalSlider("intensity", strengthStepsFull, strengthStepsNormal / 2, "cl_lightStrengthChanged", true)
            gui:createHorizontalSlider("range", maxRange, GetEffectRange(self.data.effect), "cl_lightRangeChanged", true)
        end

        gui:setButtonCallback("DefaultOn", "cl_toggleDefault")
        gui:setButtonCallback("DefaultOff", "cl_toggleDefault")

        self.gui = gui
        self:cl_updateUI()
    end

    self.gui:open()
end

function Light:client_canTinker(char)
    if #self.interactable:getParents(2) > 0 then return false end

    return --[[sm.localPlayer.getInventory():canSpend(obj_consumable_inkammo, 1) and]] sm.localPlayer.getActiveItem() == tool_paint
end

function Light:client_onTinker(char, state)
    if not state then return end

    sm.audio.play("ConnectTool - Rotate")
    self.network:sendToServer("sv_colourPaintMode")
end

function Light:cl_updateLightEffect()
    if not sm.exists(self.light) then
        self.light = sm.effect.createEffect(self.data.effect, self.interactable)
        self.light:setParameter("maxIntensity", self.cl_baseIntensity * (strengthStepsFull / strengthStepsNormal))
    end

    self.light:setParameter("color", self.cl_bulbColour)
    self.light:setParameter("intensity", self.cl_baseIntensity * (self.cl_strength / strengthStepsNormal))
    self.light:setParameter("range", self.cl_range)

    local parents = self.interactable:getParents(1)
    local isParentActive = false
    for k, v in pairs(parents) do
        if bit.band(v:getConnectionOutputType(), 2) > 0 then --filter out colour block
            parents[k] = nil
        elseif v.active then
            isParentActive = true
        end
    end

    local active, playing = #parents == 0 and self.cl_defaultState or isParentActive, self.light:isPlaying()
    if active and not playing then
        self.light:start()
        self.interactable:setPoseWeight(0, 1)
    elseif not active and playing then
        self.light:stop()
        self.interactable:setPoseWeight(0, 0)
    end
end

function Light:cl_updateUI()
    self.gui:setSliderPosition("intensity", self.cl_strength - 1)
    self.gui:setSliderPosition("range", self.cl_range - 1)

    self.gui:setText("intensityLabel", "Intensity: "..tostring(self.cl_strength))
    self.gui:setText("rangeLabel", "Range: "..tostring(self.cl_range))

    self.gui:setItemIcon("Value", "IconsLampSpritesheet", "IconsLampSpritesheet", tostring(math.min(self.cl_strength - 1, 9)))

    self.gui:setButtonState("DefaultOn", self.cl_defaultState == true)
    self.gui:setButtonState("DefaultOff", self.cl_defaultState == false)
end

function Light:cl_lightStrengthChanged(value)
    self.lightStrengthChanged = 10
    self.cl_strength = value + 1
    self:cl_updateUI()
    self:cl_updateLightEffect()
end

function Light:cl_lightRangeChanged(value)
    self.lightRangeChanged = 10
    self.cl_range = value + 1
    self:cl_updateUI()
    self:cl_updateLightEffect()
end

function Light:cl_toggleDefault(button)
    if button:sub(8, #button) == "On" then
        self.cl_defaultState = true
    else
        self.cl_defaultState = false
    end

    self:cl_updateUI()
    self.network:sendToServer("sv_defaultStateChanged", self.cl_defaultState)
end



--custom event called from mechaniccharacter
function Light:server_onShapePainted()
    --print("SERVER shape painted wowzers")
    if not self.sv_paintBulb then return end

    self.sv_bulbColour = self.shape.color
    self.shape.color = self.sv_originalColour
    self:sv_updateStorage()
end

-- function Light:client_onShapePainted()
--     print("CLIENT shape painted wowzers")
-- end