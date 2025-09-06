local fs=require("@lune/fs")
local roblox=require("@lune/roblox")

local game=roblox.deserializePlace(fs.readFile("./lune/serialized.rbxl"))

local Scripts={}
local antiskid=game:GetService("ServerStorage").MainModule

local function serializer(path,scriptName)
    local dir=fs.isDir(path) and fs.readDir(path) or nil

    if dir==nil then
        warn(`{path} is not a dir!`)
        return
    end

    for i,v in dir do
        if fs.isDir(`{path}{v}`) then
            serializer(`{path}{v}/`,v)
            continue
        end

        local source=fs.readFile(`{path}{v}`)

        if Scripts[scriptName] then
            warn(scriptName,"DUPLICATE EXISTS IGNORING IT!")
            continue
        end

        Scripts[scriptName]={
            fileName=v,
            Source=source,
        }
        --print(`file: {v} script name: {scriptName}`)
    end
end

serializer("./src/")

if Scripts.MainModule==nil then
    error("mainmodule of antiskid doesnt exist.")
    return 
end

-- antiskid.Source=Scripts.MainModule.Source
-- Scripts.MainModule=nil

local function setSource(object)
    local scr=Scripts[object.Name]

    if scr and object:IsA("LuaSourceContainer") then
        object.Source=scr.Source
    end

    for i,v in object:GetChildren() do
        if v.ClassName=="Folder" and v.Name=="maps" or v.ClassName=="Tool" and v.Name=="Fly" then
            continue
        end

        setSource(v)
    end
end

setSource(antiskid)

fs.writeFile("./lune/serialized.rbxl",roblox.serializePlace(game))
print("Builded from source successfully.")