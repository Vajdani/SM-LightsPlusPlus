dofile("$CONTENT_40639a2c-bb9f-4d4f-b88c-41bfe264ffa8/Scripts/ModDatabase.lua")

EffectLibrary = {}
local checkedEffectSets = {}

local function ParseList(list)
    if not list then return end

    for name, data in pairs(list) do
        local params = data.parameterList or {}
        EffectLibrary[name] = {
            intensity = params.intensity or 1,
            range = params.range or 1
        }
    end
end

local function AddFromEffectSet(effectSet)
    if checkedEffectSets[effectSet] ~= nil then return end

    local success, data = pcall(sm.json.open, effectSet)
    if success then
        ParseList(data)
    end

    checkedEffectSets[effectSet] = true
end

local function AddFromEffectDB(effectDB)
    for _, effectSet in pairs(sm.json.open(effectDB).effectSetList) do
        AddFromEffectSet(effectSet.path)
    end
end

AddFromEffectDB("$SURVIVAL_DATA/Effects/Database/effectsets.json")
AddFromEffectDB("$GAME_DATA/Effects/Database/effectsets.json")
AddFromEffectDB("$CHALLENGE_DATA/Effects/Database/effectsets.json")



ModDatabase.loadShapesets()
ModDatabase.loadToolsets()
for _, modId in pairs(ModDatabase.getAllLoadedMods(true)) do
    local dbPath = "$CONTENT_"..modId.."/Effects/Database/effects.json"
    if not sm.json.fileExists(dbPath) then
        dbPath = "$CONTENT_"..modId.."/Effects/Database/effectsets.effectdb"
    end

    if sm.json.fileExists(dbPath) then
        AddFromEffectDB(dbPath)
    end
end
ModDatabase.unloadToolsets()
ModDatabase.unloadShapesets()



function GetEffectIntensity(name)
    return (EffectLibrary[name] or {}).intensity or 1
end

function GetEffectRange(name)
    return (EffectLibrary[name] or {}).range or 1
end

local maxRanges = {
    FactoryLight = -1,
    PosterLight = GetEffectRange("PosterLight"),
    EncryptorLight = -1,
    ShackLight = -1,
    FreshLight = -1,
}
function GetEffectMaxRange(name)
    return maxRanges[name] or GetEffectRange(name) * 2
end