local fs=require("@lune/fs")
local roblox=require("@lune/roblox")

local game=roblox.deserializePlace(fs.readFile("./lune/serialized.rbxl"))
local antiskid=game:GetService("ServerStorage").MainModule

for _,v in fs.readDir("./src") do
    pcall(fs.removeFile,`./src/{v}`)
    pcall(fs.removeDir,`./src/{v}`)
end

local function hasScripts(object)
    for i,v in object:GetChildren() do
        if v:IsA("LuaSourceContainer") or v:IsA("Folder") then
            return true
        end
    end

    return false
end

local function runcontext(object)
    if object.ClassName=="Script" then
        local name=object.RunContext.Name
        if name=="Legacy" then
            return ".legacy"
        elseif name=="Server" then
            return ".server"
        elseif name=="Client" then
            return ".clientcontext"
        elseif name=="Plugin" then
            return ".plugin"
        end
    elseif object.ClassName=="LocalScript" then
        return ".client"
    end

    return ""
end

local function deserializator(object,path)
    if object.ClassName=="Folder" and object.Name=="maps" or object.ClassName=="Tool" and object.Name=="Fly" then
        return
    end

    if object:IsA("LuaSourceContainer") and fs.isFile(`{path}{object.Name}/{object.Name}.luau`)==false then
        path=`{path}{object.Name}/`

        fs.writeDir(path)
        fs.writeFile(`{path}init{runcontext(object)}.luau`,object.Source)

        -- if hasScripts(object) then --if #object:GetChildren()>0 then
        --     path=`{path}{object.Name}/`
        --     fs.writeDir(path)
        -- end
    elseif object:IsA("Folder") and hasScripts(object) and fs.isDir(`{path}{object.Name}`)==false then
        path=`{path}{object.Name}/`
        fs.writeDir(path)
    end

    for _,v in object:GetChildren() do
        deserializator(v,path)
        -- if v:IsA("LuaSourceContainer")==false then continue end
        -- fs.writeFile(`{path}{v.Name}.luau`,v.Source)
    end 
end

deserializator(antiskid,"./src/")

print("Build from serialized rbxl file successful.")
-- for i,v in antiskid:GetDescendants() do
--     print(v:GetFullName())
-- end
-- print(antiskid.Source)

--fs.writeFile("./serialized.rbxl",roblox.serializeModel({shit:GetService("ServerStorage").MainModule}))