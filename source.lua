-- // Localizing globals \\
local loadArgs={...}
local game=game
local workspace=workspace
local setfenv=setfenv
local getfenv=getfenv
local math=math
local print=print
local warn=warn
local error=error
local table=table
local task=task
local Instance=Instance
local setmetatable=setmetatable
local getmetatable=getmetatable
local script=script
local _G=_G
local shared=shared
local xpcall=xpcall
local os=os
local tick=tick
local pcall=pcall
local require=require
local rawset=rawset
local rawequal=rawequal
local rawget=rawget
local typeof=typeof
local type=type
local newproxy=newproxy
local string=string
local loadstring=loadstring
local debug=debug
local NLS=NLS or nls or NEWLOCALSCRIPT or NewLocalScript or newlocalscript or new_local_script
local NS=NS or ns or NEWSCRIPT or NewScript or newscript or new_script
local NMS=NMS or nms or NEWMODULESCRIPT or NewModuleScript or newmodulescript or new_module_script
local owner=owner or OWNER or player or Player
local oldEnv=getfenv()

setfenv(0,table.freeze{})
setfenv(1,table.freeze{})

local branch=loadArgs[2]
owner=typeof(owner)=="Instance" and owner or loadArgs[1]

-- // Localizing roblox functions (part 1) \\
local getservice=game.GetService
local destroy=game.Destroy

-- // in case executor is shit 💀 \\
if typeof(script)=="Instance" and script:IsA("BaseScript") then
    script.Enabled=false
    pcall(destroy,script)
elseif typeof(script)=="Instance" then
    pcall(destroy,script)
end

script=Instance.new("Script")
pcall(table.clear,oldEnv)

-- // Localizing services \\
local function service(name)
    return getservice(game,name)
end

local players=service("Players")
local httpservice=service("HttpService")
local runservice=service("RunService")

-- // Localizing values \\
local isClient=runservice:IsClient()
local isStudio=runservice:IsStudio()
local lplr=players.LocalPlayer

if isClient and lplr then
    owner=lplr
end

-- // Localizing roblox functions (part 2) \\
local requestasync=httpservice.RequestAsync
local getplayers=players.GetPlayers
local findfirstchildofclass=game.FindFirstChildOfClass
local querydescendants=game.QueryDescendants

if branch~="main" and branch~="nightly" then
    branch="nightly"
end

-- // github branch \\
local mainUrl=`https://raw.githubusercontent.com/loadstring1/antiskid-v14/refs/heads/{branch}/`
local assetUrl=`{mainUrl}assets/`
local assetCache={}

local function loadfromrepo(name)
    return ({ pcall(requestasync,httpservice,{
        Url=`{mainUrl}{name}`,
        Method="GET",
    }) })[2]
end

local function loadasset(name)
    if assetCache[name] then
        return assetCache[name]
    end

    local success,result=pcall(requestasync,httpservice,{
        Url=`{assetUrl}{name}`,
        Method="GET",
    })

    if success and result.Success then
        assetCache[name]=result.Body
    end

    return result.Body
end

local function loadfromrepoUntilSuccess(name)
    local result

    repeat
        result=loadfromrepo(name)
        
        if typeof(result)=="table" and result.Success then
            break
        end

        task.wait()
    until nil

    return result.Body
end

local function loadassetUntilCached(name)
    repeat 
        loadasset(name)
        if assetCache[name] then break end
        task.wait()
    until assetCache[name]

    return assetCache[name]    
end

local function newEnv()
    local fakeEnv={
        script=Instance.new("Script"),
        _G=_G,
        shared=shared,
    }
    local meta={}

    function meta:__index(index)
        return oldEnv[index]
    end

    meta.__metatable="The metatable is locked"

    setmetatable(fakeEnv,meta)
    table.freeze(meta)

    return fakeEnv
end

local function loadcode(code,chunk)
    local executable,err=loadstring(code,chunk)

    if typeof(executable)~="function" then
        warn(`AntiSkid failed to compile asset!\nError: {err}`)
        return function()end
    end

    return setfenv(executable,newEnv())
end

-- // antis, commands and funcs \\
local funcs={}

-- function funcs.yielder()
-- 	local Budget = 1/60
-- 	local expireTime = tick()+Budget

-- 	return function()
-- 		if tick() >= expireTime then
-- 			task.wait()
-- 			expireTime = tick() + Budget
-- 		end
-- 	end
-- end

function funcs.timeoutBypassLoop(tbl,func)
    local last=os.clock()
    for i,v in tbl do
        if os.clock()-last>5 then last=os.clock(); task.wait() end
        func(i,v)
    end
end

table.freeze(funcs)

local antis={}
local commands={}
local supportedCommandSyntax={
    "a/",
    "antiskid/",
    "as/",
    ";",
    ":",
    "!",
    "o",
    "/",
}

-- // Loading assets from http (works only on serverside) \\
local clientSource=isClient==false and loadfromrepoUntilSuccess("source.lua") or nil
local serializer=isClient==false and loadcode(loadassetUntilCached("serializer.lua"),"serializer.lua")() or nil
local maps=isClient==false and loadcode(loadassetUntilCached("maps.lua"),"maps.lua")(serializer) or nil

local function onPlayer(plr)
    plr.Chatted:Connect(function(msg)
        if typeof(msg)~="string" then return end
        local currentSyntax

        for _,syntax in supportedCommandSyntax do
            if string.sub(msg,0,#syntax)==syntax then
                currentSyntax=syntax
                break
            end
        end

        if currentSyntax==nil then return end
        msg=string.gsub(msg,currentSyntax,"",1)
        
        local args=string.split(msg,string.sub(currentSyntax,#currentSyntax,#currentSyntax)~="/" and " " or currentSyntax=="/" and " " or "/")
        local cmdName=args[1]

        table.remove(args,1)

        local currentCommand=commands[cmdName]

        if currentCommand==nil then
            for _,cmdData in commands do
                if cmdData.aliases[cmdName] then
                    currentCommand=cmdData
                    break
                end
            end
        end

        if currentCommand==nil then return end
        currentCommand.func(plr,args)
    end)

    if isClient or typeof(NLS)~="function" then return end

    local toparent=findfirstchildofclass(plr,"PlayerGui") or Instance.new("Backpack")

    if toparent.ClassName=="Backpack" then
        toparent.Parent=plr
        task.delay(5,pcall,destroy,toparent)
    end

    local client=NLS(clientSource,toparent,true)
    if typeof(client)~="Instance" or client.ClassName~="LocalScript" then return end

    client.Enabled=true
    task.delay(5,pcall,destroy,client)
end

local function addCommand(data)
    if data.clientAllowed~=true and isClient then return end
    if data.onlyClient and isClient==false then return end

    commands[data.name]=table.freeze(data)
end

local function addAnti(data)
    if data.clientAllowed~=true and isClient then return end
    if data.onlyClient and isClient==false then return end

    antis[data.name]=table.freeze(data)
end

local function valuesToIndex(tbl)
    local manipulated={}

    for index,value in tbl do
        manipulated[value]=true
    end

    return table.freeze(manipulated)
end

-- // Registering commands before connecting to Chatted \\

addCommand({
    name="test",
    description="test",
    aliases=valuesToIndex{"t"},
    func=function(player,args)
        print(player,args,"cool!")
    end,
})

addCommand({
    name="testclient",
    description="test client",
    aliases=valuesToIndex{"tc"},
    clientAllowed=true,
    onlyClient=true,
    func=function(player,args)
        print(isClient,player,args,"this should print only on client")
    end,
})

addCommand({
    name="resetmap",
    description="resets map to a random map from antiskid's map folder",
    aliases=valuesToIndex{"rm"},
    func=function(player,args)
        --local yield=funcs.yielder()
        local mapsChildren=maps:GetChildren()
        local randomMap=mapsChildren[math.random(1,#mapsChildren)]
        local map=randomMap:Clone()

        funcs.timeoutBypassLoop(map:GetDescendants(),function(_,inst)
            if inst.ClassName~="Script" then return end
            if typeof(NS)~="function" then pcall(destroy,inst); return end
            local parent=inst.Parent
            pcall(destroy,inst)

            local server = NS(inst:GetAttribute("Source"),parent,true)
            inst:SetAttribute("Source",nil)
            if typeof(server)~="Instance" or server.ClassName~="Script" then return end
            server.Enabled=true
        end)

        funcs.timeoutBypassLoop(getplayers(players),function(_,player)
            local char=player.Character
            if char==nil then return end

            pcall(destroy,char)
            player.Character=nil
        end)   

        funcs.timeoutBypassLoop(workspace:GetDescendants(),function(_,inst)
            pcall(destroy,inst)
        end)

        map.Parent=workspace

        funcs.timeoutBypassLoop(getplayers(players),function(_,player)
            task.spawn(pcall,player.LoadCharacterAsync,player)
        end)
        print("map reset successfully")
    end,
})

table.freeze(commands)

if isClient==false then
    players.PlayerAdded:Connect(onPlayer)
    for _,player in getplayers(players) do 
        task.spawn(onPlayer,player)
    end
else
    onPlayer(lplr)
end


if isStudio==false then return end
print(`{isClient and "client antiskid loaded" or "server antiskid loaded"}`)
-- local descendantConnection

-- local function descendants(inst)
-- end

-- descendantConnection=game.DescendantAdded:Connect(descendants)