print("[LIGHTS++] HOOK IN PROGRESS")

-- MechanicCharacter = MechanicCharacter or {}
if not MechanicCharacter then
    dofile "$SURVIVAL_DATA/Scripts/game/characters/MechanicCharacter.lua"
end

Lightspp_oldMechanicClientUpdate = Lightspp_oldMechanicClientUpdate or MechanicCharacter.client_onUpdate
function MechanicCharacter:client_onUpdate(dt)
    Lightspp_oldMechanicClientUpdate(self, dt)

    local char = self.character
    if not sm.exists(char) or char:getPlayer() ~= sm.localPlayer.getPlayer() then return end

    if not self.LIGHTSPLUSPLUSpaintHookTimer then
        self.LIGHTSPLUSPLUSpaintHookTimer = 0
    end

    if self.LIGHTSPLUSPLUSpaintHookTimer == 20 then
        print("[LIGHTS++] HOOK CHARACTER ANIMATION")
        self.character:bindAnimationCallback( "painttool_paint", 0, "cl_onPaintAnimation" )
        self.character:bindAnimationCallback( "painttool_erase", 0, "cl_onPaintAnimation" )
    end
    if self.LIGHTSPLUSPLUSpaintHookTimer < 21 then
        self.LIGHTSPLUSPLUSpaintHookTimer = self.LIGHTSPLUSPLUSpaintHookTimer + 1
    end
end

function MechanicCharacter:cl_onPaintAnimation()
    self.network:sendToServer("sv_onPaintAnimation", { pos = sm.camera.getPosition(), dir = sm.camera.getDirection() })
end

function MechanicCharacter:sv_onPaintAnimation(args, player)
    local hit, result = sm.physics.raycast(args.pos, args.pos + args.dir * 7.5, player.character)
    local shape = result:getShape()
    if not shape or not sm.exists(shape) then return end

    local int = shape.interactable
    if not int or int.type ~= "scripted" then return end

    sm.event.sendToInteractable(int, "server_onShapePainted")
    self.network:sendToClients("cl_onObjectPainted", int)
end

function MechanicCharacter:cl_onObjectPainted(int)
    sm.event.sendToInteractable(int, "client_onShapePainted")
end