local loadArgs={...}
local game=game
local setfenv=setfenv
local getfenv=getfenv
local NLS=NLS or nls or newlocalscript
local loadstring=loadstring
local table=table
local print=print
local Instance=Instance
local oldEnv=getfenv()
local typeof=typeof
local owner=owner
local pairs=pairs
local workspace=workspace
local task=task
local pcall=pcall
local string=string
local Enum=Enum
local tostring=tostring
local math=math

setfenv(0, table.freeze{})
setfenv(1, table.freeze{})

local branch=loadArgs[2]
owner=typeof(owner)=="Instance" and owner or loadArgs[1]

-- // Localizing roblox functions (part 1) \\
local getservice=game.GetService
local destroy=game.Destroy

-- // Localizing services \\
local function service(name)
    return getservice(game,name)
end

local players=service("Players")
local httpservice=service("HttpService")
local requestasync=httpservice.RequestAsync

if branch~="main" and branch~="nightly" then
    branch="nightly"
end

-- // github branch \\
local mainUrl=`https://raw.githubusercontent.com/loadstring1/antiskid-v14/refs/heads/{branch}/`
local assetUrl=`{mainUrl}assets/`
local assetCache={}

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

local function loadassetUntilCached(name)
    repeat 
        loadasset(name)
        if assetCache[name] then break end
        task.wait()
    until assetCache[name]

    return assetCache[name]    
end

local clientSource=loadassetUntilCached("sbunc_client_notify.lua")

--ahhhhhhh noooo messy source code nooooooooooooooo
local function notify(content)
    content=`[AntiSkid's SB unc]: {content}`
    if typeof(NLS)=="function" then
        if typeof(owner)=="Instance" then
            local client=NLS(string.format(clientSource,content),owner:FindFirstChildOfClass("PlayerGui"),true)
            client.Enabled=true
            task.delay(5,pcall,destroy,client)
            return
        end

        --fallback to notify all players in case some dumbass forgot to add owner global
        for i,v in pairs(players:GetPlayers()) do
            local client=NLS(string.format(clientSource,content),v:FindFirstChildOfClass("PlayerGui"),true)
            client.Enabled=true
            task.delay(5,pcall,destroy,client)
        end

        return
    end

    local msg=Instance.new("Message")
    msg.Text=content
    msg.Parent=typeof(owner)=="Instance" and owner:FindFirstChildOfClass("PlayerGui") or workspace
end

if typeof(NLS)~="function" then
    notify("sbunc won't continue running because executor doesn't support NLS (newlocalscript) function.")
    return
end

-- // TESTS \\

local successfulTests=0
local failedTests=0

local function test(name,func)
    local success,result=pcall(func)

    notify(`{name} {success and result==true and "test was successful." or "test failed."}`)

    if success and result==true then
        successfulTests+=1
    else
        failedTests+=1
    end

    if success==false and typeof(result)=="string" then
        notify(`{name} - test error: {result}`)
    end
end

 local isvlua=pcall(function() for i,v in {} do end end)==false

if isvlua==false then
    pairs=function(...) --fallback to native iteration luau if we aren't running in pure lua 5.1
        return ...
    end
end

--owner global check
test("ownerGlobal",function()
    if typeof(owner)~="Instance" or owner.ClassName~="Player" then
        for _,plr in pairs(players:GetPlayers()) do
            if plr.Name==owner or plr.UserId==owner then
                owner=plr
                break
            end
        end

        if typeof(owner)~="Instance" then
            owner="all"
        end

        notify("ownerGlobal: failed - executor doesn't have a owner global (attempted to replace owner global with real player)")
        return false
    end

    return true
end)

--luau check
test("isLuaU",function()
    if isvlua then
        notify("isLuaU: failed - native loadstring is probably disabled therefore sbunc was ran with pure lua 5.1")
    end

    return isvlua==false
end)

--check for NLS already above and its kinda poopy bc im just checking if it exists lol
test("NLS",function()  
    return true
end)

--SURELY no one will copy raw script instead of running it with loadstring and http right? right???
test("httpEnabled",function() 
    return true
end)

test("assetServiceEnabled",function()  
    local success=pcall(function()return service("AssetService"):LoadAssetAsync(111996792824076) end)

    if success==false then
        notify("assetServiceEnabled: AssetService is disabled this means you cannot bypass require(id) printing in console if signalbehavior is deferred and you cannot bypass breakasset easiely. The SB community should consider moving from require(id) to AssetService:LoadAssetAsync(id)")
    end

    return success
end)

test("banAsyncDisabled",function()
    local success,result=pcall(players.UnbanAsync,players,{UserIds={1},ApplyToUniverse=true})  

    if success or success==false and result~="UnbanAsync is disabled due to Players:BanningEnabled being set to false" then
        notify("banAsyncDisabled: BanAsync is literally enabled in this game and any skid can run banasync on you. (if you are game dev i highly suggest disabling BanAsync under Players property BanningEnabled in studio)")
        return false
    end

    return true
end)

test("thirdPartyTeleportsDisabled",function()
    local event=Instance.new("BindableEvent")
    local tpserv=service("TeleportService")
    local initFailed
    
    initFailed=tpserv.TeleportInitFailed:Connect(function(plr,result,err)
        if plr~=owner then return end
        
        if result==Enum.TeleportResult.Unauthorized and string.find(string.lower(err),"universe owned by a different creator") then
            event:Fire(true)
            return
        end
        
        if service("RunService"):IsStudio() then
            event:Fire(true)
            return
        end
        
        notify("thirdPartyTeleportsDisabled: failed - Third party teleports are enabled in this place. (go to game settings -> Security -> Third party teleports and disable them)")
        event:Fire(false)
    end)

    if typeof(owner)~="Instance" then
        notify(`thirdPartyTeleportDisabled: failed - unable to check if teleports are disabled bc owner global died`)
        return false
    end
    
    task.delay(0,pcall,tpserv.Teleport,tpserv,114827002545842,owner)
    
    local success=event.Event:Wait()
    initFailed:Disconnect()
    
    return success
end)

test("streamingDisabled",function()
    local isStreamingEnabled=workspace.StreamingEnabled
    
    if isStreamingEnabled then
        notify(`streamingDisabled: Streaming is enabled in this experience. This means you might experience annoying game paused stuck on your screen garbage for example: if you get voided. (go to workspace -> properties -> StreamingEnabled and disable it)`)
    end
    
    return isStreamingEnabled==false
end)

test("isImmediateSignalBehavior",function()
    local isImmediate=(function()
        local bind=Instance.new("BindableEvent")
        local test=false
        bind.Event:Connect(function()
            test=true
            bind:Destroy()
        end)
        bind:Fire()
        return test
    end)()

    if isImmediate==false then
		notify(`isImmediateSignalBehavior: Immediate is disabled in this experience. This means scripts that rely on hypernull won't work here. (go to workspace -> properties -> SignalBehavior and change it to Immediate)`)
	end
    
    return isImmediate
end)

notify(`Test ended with {tostring(math.round(successfulTests / (successfulTests+failedTests) * 100))}%`)