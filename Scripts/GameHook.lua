dofile "EffectLibrary.lua"

tool_paint = sm.uuid.new( "c60b9627-fc2b-4319-97c5-05921cb976c6" )



---@class GameHook : ToolClass
GameHook = class()

function GameHook:server_onCreate()
    if sm.LIGHTSPLUSPLUSHOOK then return end

    sm.LIGHTSPLUSPLUSHOOK = self.tool
end

function GameHook:sv_toggleDBState(player)
    self.network:sendToClient(player, "cl_toggleDBState")
end

function GameHook:sv_checkMismatch(cl_state, player)
    if cl_state == self.dbState then return end

    self.network:sendToClient(player, "cl_msg", "[#df7f00LIGHTS++#ffffff] #ff0000WARNING! The host has a mismatching light override setting! Please type #ffffff/toggleLightsOverride#ff0000 in the chat, leave the game, and join your friend again.")
    self.network:sendToClient(self.tool:getOwner(), "cl_msg", ("[#df7f00LIGHTS++#ffffff] #ff0000WARNING! #ffffff%s#ff0000 has a mismatching light override setting!"):format(player.name))
end



function GameHook:client_onCreate()
    if g_cl_init then return end

    g_cl_init = true

    self.dbState = sm.json.open("$CONTENT_DATA/Objects/Database/shapesets.shapedb").shapeSetList[1] == "$CONTENT_DATA/Objects/Database/ShapeSets/lights_override.shapeset"
    if not sm.isHost then
        self.network:sendToServer("sv_checkMismatch", self.dbState)
    end
end

function GameHook:cl_toggleDBState()
    self.dbState = not self.dbState
    if self.dbState then
        sm.json.save({ shapeSetList = { "$CONTENT_DATA/Objects/Database/ShapeSets/lights_override.shapeset" } }, "$CONTENT_DATA/Objects/Database/shapesets.shapedb")
        sm.json.save(sm.json.open("$CONTENT_DATA/CraftingRecipes/craftbot_override.json"), "$CONTENT_DATA/CraftingRecipes/craftbot.json")
        self:cl_msg("[#df7f00LIGHTS++#ffffff] Override lights activated! Re-enter the world for the change to take effect.")
    else
        sm.json.save({ shapeSetList = { "$CONTENT_DATA/Objects/Database/ShapeSets/lights_separate.shapeset" } }, "$CONTENT_DATA/Objects/Database/shapesets.shapedb")
        sm.json.save(sm.json.open("$CONTENT_DATA/CraftingRecipes/craftbot_separate.json"), "$CONTENT_DATA/CraftingRecipes/craftbot.json")
        self:cl_msg("[#df7f00LIGHTS++#ffffff] Separate lights activated! Re-enter the world for the change to take effect.")
    end
end

function GameHook:cl_msg(msg)
    sm.gui.chatMessage(msg)
end



oldUUID = oldUUID or sm.uuid.new
function sm.uuid.new(uuid)
    if not gameHooked then
        gameHooked = true

        dofile("$CONTENT_570da70f-dd89-4dbe-abf1-0656ff9f6195/Scripts/vanilla_override.lua")
    end

    return oldUUID(uuid)
end

oldBind = oldBind or sm.game.bindChatCommand
function sm.game.bindChatCommand(command, params, callback, help)
    if not cmdInjected then
        cmdInjected = true

        sm.game.bindChatCommand("/toggleLightsOverride", {}, "cl_onChatCommand", "Toggles whether the Lights++ mod overrides the vanilla lights, or adds it's own lights.")
    end

	return oldBind(command, params, callback, help)
end



oldWorldEvent = oldWorldEvent or sm.event.sendToWorld
function sm.event.sendToWorld(world, callback, args)
    if callback == "sv_e_onChatCommand" then
        local command = args[1]
        if command == "/toggleLightsOverride" then
            sm.event.sendToTool(sm.LIGHTSPLUSPLUSHOOK, "sv_toggleDBState", args.player)
        end
    end

    return oldWorldEvent(world, callback, args)
end