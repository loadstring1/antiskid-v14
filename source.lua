-- // Localizing everything \\
local branch=...
local game=game
local setfenv=setfenv
local getfenv=getfenv
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
local pcall=pcall
local rawset=rawset
local rawequal=rawequal
local rawget=rawget
local typeof=typeof
local type=type
local newproxy=newproxy
local string=string
local loadstring=loadstring
local NLS=NLS or nls or newlocalscript
local oldEnv=getfenv()

setfenv(0,table.freeze{})
setfenv(1,table.freeze{})

local getservice=game.GetService
local destroy=game.Destroy

-- // in case executor is shit 💀 \\
if typeof(script)=="Instance" and script.ClassName=="Script" then
    script.Enabled=false
    pcall(destroy,script)
elseif typeof(script)=="Instance" then
    pcall(destroy,script)
end

script=Instance.new("Script")

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

-- // Localizing roblox functions \\
local requestasync=httpservice.RequestAsync
local getplayers=players.GetPlayers
local findfirstchildofclass=game.FindFirstChildOfClass
local querydescendants=game.QueryDescendants

if branch~="main" and branch~="nightly" then
    branch="main"
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
    repeat
        local result=loadfromrepo(name)
        
        if typeof(result)=="table" and result.Success then
            return result.Body
        end

        task.wait()
    until nil
end

local function loadassetUntilCached(name)
    repeat 
        if assetCache[name] then break end
        loadasset(name)
        task.wait()
    until assetCache[name]

    return assetCache[name]    
end

local function newEnv()
    local fakeEnv={script=Instance.new("Script")}
    local meta={}

    function meta:__index(index)
        return oldEnv[index]
    end

    meta.__metatable="The metatable is locked"

    setmetatable(fakeEnv,meta)
    table.freeze(meta)

    return fakeEnv
end

local function loadcode(code)
    local executable,err=loadstring(code)

    if typeof(executable)~="function" then
        warn(err)
        return function()end
    end

    return setfenv(executable,newEnv())
end

-- // antis and commands \\
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
local nestify=isClient==false and loadcode(loadassetUntilCached("yariknestifier.lua"))() or nil

local function onPlayer(plr)
    plr.Chatted:Connect(function(msg)
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

        for _,cmdData in commands do
            if currentCommand then break end

            if cmdData.aliases[cmdName] then
                currentCommand=cmdData
                break
            end
        end

        if currentCommand==nil then return end
        currentCommand.func(plr,args)
    end)

    if isClient or typeof(NLS)~="function" then return end

    local client=NLS(plr,clientSource,nil) --first arg player, second arg source, third arg script parent
    if typeof(client)~="Instance" or client.ClassName~="LocalScript" then return end

    local toparent=findfirstchildofclass(plr,"PlayerGui") or Instance.new("Backpack")

    if toparent.ClassName=="Backpack" then
        toparent.Parent=plr
        task.delay(5,pcall,destroy,toparent)
    end

    client.Enabled=true
    client.Parent=toparent
    task.delay(5,pcall,destroy,client)
end

local function addCommand(data)
    if data.clientAllowed~=true and isClient then return end
    if data.onlyClient and isClient==false then return end

    commands[data.name]=data
end

local function addAnti(data)
    if data.clientAllowed~=true and isClient then return end
    if data.onlyClient and isClient==false then return end

    antis[data.name]=data
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
    aliases=valuesToIndex({"tc"}),
    clientAllowed=true,
    onlyClient=true
    func=function(player,args)
        print(isClient,player,args,"this should print only on client")
    end,
})

if isClient==false then
    players.PlayerAdded:Connect(onPlayer)
    for _,player in getplayers(players) do 
        task.spawn(onPlayer,player)
    end
else
    onPlayer(lplr)
end
-- local descendantConnection

-- local function descendants(inst)
-- end

-- descendantConnection=game.DescendantAdded:Connect(descendants)