--!nocheck
local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient or funcs.isBSRE then return nil end

local http=funcs.getservice("HttpService")
local players=funcs.getservice("Players")

if http.HttpEnabled==false then
    funcs.httpdata=table.freeze{bans=table.freeze{}}
    return nil
end

local requestasync=http.RequestAsync
local jsondecode=http.JSONDecode

local PUBLIC_DATA_URL="http://node6.lunes.host:3102/api/getpublicdata"
local headersCache={
    ["Cache-Control"]="",
    ["If-None-Match"]="",
}

local onDataReady=rbxfuncs.instnew("BindableEvent")
local currentData={}

local function waitForData()
    if currentData.bans==nil then
        onDataReady.Event:Wait()
    end
end

local function fetchAPI()
    local success,response=pcall(requestasync,http,{
        Url=PUBLIC_DATA_URL,
        Headers=headersCache,
        Method="GET",
    })

    if success==false or response.StatusCode==304 then
        return nil
    end

    headersCache["Cache-Control"]=response.Headers["cache-control"]
    headersCache["If-None-Match"]=response.Headers.etag

    success,response=pcall(jsondecode,http,response.Body)

    if success==false then
        return nil
    end

    local serialized={}
    
    for name,data in response do
        local ser={}
        
        for _,value in data do
            value._id=nil
            ser[value.userid or value.string]=value
        end

        serialized[name]=ser
    end

    currentData=serialized
    onDataReady:Fire()
    funcs.httpdata=currentData

    return nil
end

local function checkBanned(plr)
    waitForData()
    local ban=currentData.bans[plr.UserId]
    if ban==nil then return end

    rbxfuncs.kick(plr,`Banned by antiskid v14 || {ban.reason} - banned by {ban.bannedby}`)
end

local last=0

funcs.connect("onHeartbeat",function()
    if last~=0 and os.clock()-last<60 then return end
	last=os.clock()

	fetchAPI()
    if currentData.bans==nil then return end
	
    for i,v in rbxfuncs.getplayers(players) do
		task.spawn(checkBanned,v)
	end
end)

funcs.connect("OnJoin",checkBanned)
funcs.httpdata=currentData

return nil