print("[LIGHTS++] HOOK IN PROGRESS")

MechanicCharacter = MechanicCharacter or {}

oldMechanicClientUpdate = oldMechanicClientUpdate or MechanicCharacter.client_onUpdate
function MechanicCharacter:client_onUpdate(dt)
    oldMechanicClientUpdate(self, dt)

    local char = self.character
    if not sm.exists(char) or char:getPlayer() ~= sm.localPlayer.getPlayer() then return end

    --self.LIGHTSPLUSPLUSpaintHookTimer = nil
    if not self.LIGHTSPLUSPLUSpaintHookTimer then
        self.LIGHTSPLUSPLUSpaintHookTimer = 0
    end

    if self.LIGHTSPLUSPLUSpaintHookTimer == 20 then
        print("[LIGHTS++] HOOK CHARACTER ANIMATION")
        --self.character:bindAnimationCallback( "painttool_idle_select", 0, "cl_onObjectPaintStart" )
        self.character:bindAnimationCallback( "painttool_paint", 0, "cl_onPaintAnimation" )
        self.character:bindAnimationCallback( "painttool_erase", 0, "cl_onPaintAnimation" )
    end
    if self.LIGHTSPLUSPLUSpaintHookTimer < 21 then
        self.LIGHTSPLUSPLUSpaintHookTimer = self.LIGHTSPLUSPLUSpaintHookTimer + 1
    end
end

-- function MechanicCharacter:cl_onObjectPaintStart()
--     local hit, result = sm.localPlayer.getRaycast(7.5)
--     self.shapeToBePainted = result:getShape()
-- end

function MechanicCharacter:cl_onPaintAnimation()
    -- if not self.shapeToBePainted then
    --     self:cl_onObjectPaintStart()
    -- end

    -- if self.shapeToBePainted and sm.exists(self.shapeToBePainted) then
    --     local int = self.shapeToBePainted.interactable
    --     if int and int.type == "scripted" then
    --         sm.event.sendToInteractable(int, "client_onShapePainted")

    --         if sm.isHost then
    --             self.network:sendToServer("sv_onObjectPainted", self.shapeToBePainted)
    --         end
    --     end
    -- end

    -- self.shapeToBePainted = nil



    -- local hit, result = sm.localPlayer.getRaycast(7.5)
    -- local shape = result:getShape()
    -- if not shape or not sm.exists(shape) then return end

    -- local int = shape.interactable
    -- if not int or int.type ~= "scripted" then return end

    -- self.network:sendToServer("sv_onObjectPainted", int)

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

-- function MechanicCharacter:sv_onObjectPainted(int)
--     sm.event.sendToInteractable(int, "server_onShapePainted")
--     self.network:sendToClients("cl_onObjectPainted", int)
-- end

function MechanicCharacter:cl_onObjectPainted(int)
    sm.event.sendToInteractable(int, "client_onShapePainted")
end