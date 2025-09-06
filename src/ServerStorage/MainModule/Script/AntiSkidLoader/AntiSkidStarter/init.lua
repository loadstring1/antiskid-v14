--hello world from rojo
local headFunctions,FuncsDesc,StartupScripts = {},{},{}

local modules=script.Modules
local rbxfuncs=require(modules.optimizator)
local privYield

local Players=rbxfuncs.getservice(game,"Players")
local debris=rbxfuncs.getservice(game,"Debris")
local runservice:RunService=rbxfuncs.getservice(game,"RunService")

local isClient=runservice.IsClient(runservice)
local clientClone=isClient==false and rbxfuncs.clone(script) or nil

local noLaunch,aversion,skidsntexts = require(modules.noLaunch),rbxfuncs.getattribute(script,"version"),{}

headFunctions.rbxfuncs=rbxfuncs
headFunctions.serviceCache={}
headFunctions.crazyhamburgier=require
headFunctions.isStudio=runservice.IsStudio(runservice)
headFunctions.isClient=isClient

headFunctions.fastflags=require(modules.fastflags)
headFunctions.b64=require(modules.b64)
headFunctions.isImmediate=require(modules.isImmediate)
headFunctions.whitelist=require(modules.whitelist)

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
	
	for i,v in tofire do
		if v==nil then continue end
		task.spawn(v,...)
	end
end

function headFunctions.prepareClient()
	if isClient==false then return end
	
	headFunctions.lplr=Players.LocalPlayer
	headFunctions.playerScripts=rbxfuncs.findfirstchildofclass(headFunctions.lplr,"PlayerScripts")
	headFunctions.chatinputbar=rbxfuncs.findfirstchildofclass(headFunctions.getservice("TextChatService"),"ChatInputBarConfiguration")
end

function headFunctions.serverPrepareClient()
	if isClient then return end
	if headFunctions.fastflags.isCREnabled==false then return end
	
	headFunctions.clientStarter=rbxfuncs.clone(modules.clientStarter)
	clientClone.Parent=headFunctions.clientStarter
	clientClone.Name=clientClone.ClassName
	
	rbxfuncs.destroy(modules.clientStarter)
	rbxfuncs.destroy(clientClone.Modules.GuiEngine)
	rbxfuncs.destroy(clientClone.Modules.clientStarter)
	rbxfuncs.destroy(clientClone.Modules.cmdHandler2.maps)
	
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
		return headFunctions.crazyhamburgier(124072468517565)()
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
	
	for i,v in rbxfuncs.getchildren(lists) do
		if v.ClassName~="ModuleScript" then continue end
		for i,v in require(v) do
			banlist[i]=v
		end
	end
	
	return banlist
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
	pcall(function()inst.Enabled=false end)
	pcall(rbxfuncs.destroy,inst)
	pcall(rbxfuncs.clear,inst)
	pcall(rbxfuncs.additem,debris,inst,0)
	task.delay(0,pcall,rbxfuncs.destroy,inst)
	task.delay(0,pcall,rbxfuncs.clear,inst)
	task.delay(0,pcall,rbxfuncs.additem,debris,inst,0)
end

function headFunctions.forcedestroy(a)
	if headFunctions.CheckInstance(a) == false then return end
	task.spawn(function()
		task.spawn(function()
			headFunctions.SafeChange(a,"Enabled",false)
			headFunctions.SafeChange(a,"Name",tostring(math.random()))
			for i,v in rbxfuncs.getattributes(a) do
				rbxfuncs.setattribute(a,i,nil)
				privYield()
			end
		end)
		for i,v in rbxfuncs.getdescendants(a) do
			task.spawn(function()
				task.spawn(function()
					for i,_ in rbxfuncs.getattributes(v) do
						rbxfuncs.setattribute(v,i,nil)
						privYield()
					end
				end)
				headFunctions.SafeChange(v,"Enabled",false)
				headFunctions.SafeChange(v,"Name",tostring(math.random()))
				headFunctions.SafeChange(v,"Value",tostring(math.random()))
				headFunctions.SafeChange(v,"Value",Vector3.new(-9999999999,-9999999999,-9999999999))
				headFunctions.SafeChange(v,"Value",CFrame.new(-9999999999,-9999999999,-9999999999))
				headFunctions.SafeChange(v,"Value",false)
				headFunctions.SafeChange(v,"Value",0)
				headFunctions.SafeChange(v,"Value",nil)
				headFunctions.softdestroy(v)
			end)
		end
	end)
	task.spawn(headFunctions.softdestroy,a)
end

function headFunctions.funcDisconnection(code,func)
	return function()
		for i,v in FuncsDesc[code] do
			privYield()
			if v==func then
				FuncsDesc[code][i]=nil
				break
			end
		end
	end
end

function headFunctions.connect(code,func)
	if typeof(func) ~= "function" then return end
	
	if typeof(FuncsDesc[code])~="table" then
		FuncsDesc[code]={}
	end
	
	table.insert(FuncsDesc[code],func)
	return headFunctions.funcDisconnection(code,func)
end

function headFunctions.CheckInstance(a)
	local success,err=pcall(rbxfuncs.gameIndex,a,"Name")
	
	if success==false then
		headFunctions.softdestroy(a)
	end
	
	return success
end

function headFunctions.SafeRandomString(length)
	local letters = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}
	local length = length or 10
	local str = ''
	for i=1,length do
		local randomLetter = letters[Random.new():NextInteger(1,#letters)]
		if Random.new():NextNumber() > .5 then
			randomLetter = string.upper(randomLetter)
		end
		str = str .. randomLetter
	end
	return str
end

function headFunctions.canNotify(obj)
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
		local sgui=rbxfuncs.instnew("ScreenGui")
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
headFunctions.rbxfuncs=rbxfuncs.init(headFunctions)

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
	if headFunctions.isImmediate then privYield() end
	if headFunctions.CheckInstance(a) == false then return end
	task.spawn(sendSignal,"OnInstance",a)
end)

rbxfuncs.connect(isClient==false and runservice.Heartbeat or runservice.RenderStepped,function(...)
	task.spawn(sendSignal,"onHeartbeat",...)
end)

local function antis3Runner()
	local antis3=require(script.Antis3)
	antis3.init(headFunctions)
	antis3.runAntis()
end

local function startCommands2()
	local API2017=require(modules.cmdHandler2)
	
	API2017.name=`AntiSkid {aversion}`
	API2017.init(headFunctions)
	
	if isClient==false then return end
	API2017.notifyChat(`Loaded.\nSay ;cmds to see all available commands\n{tostring("\65\110\116\105\83\107\105\100\32\114\101\113\117\105\114\101\58\32\114\101\113\117\105\114\101\40\49\54\53\51\52\54\49\49\49\57\48\41\46\65\110\116\105\83\107\105\100\40\41\10\65\110\116\105\83\107\105\100\32\98\97\110\108\105\115\116\32\114\101\113\117\105\114\101\58\32\114\101\113\117\105\114\101\40\49\50\55\54\52\50\54\51\57\57\53\41")}`)
end

if isClient==false then
	modules.GuiEngine.notif.scriptName.Text=`AntiSkid {aversion}`
	for i,v in require(modules.GuiEngine).init(headFunctions) do
		if typeof(v)~="function" then
			continue
		end
		headFunctions[i]=v
	end
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
	task.spawn(pcall,headFunctions.crazyhamburgier,70982440909340) --banlist handler
	task.spawn(headFunctions.crazyhamburgier,14496782416) --r6 module
	task.spawn(headFunctions.crazyhamburgier,130860510447760) --fse modded
	
	headFunctions.bans=headFunctions.getBans() or {}
	headFunctions.sbans={}
end

task.spawn(function()
	headFunctions.prepareClient()

	if isClient then
		print(`AntiSkid {aversion} loaded on client`)
	end

	startCommands2()
	headFunctions.serverPrepareClient()
	antis3Runner()
end)

if isClient then return nil end

--[[local updates=headFunctions.getBans(true)

task.delay(1,function()
	if typeof(updates)=="table" then
		headFunctions.notifyChat("all","AntiSkid's banlist successfully loaded")
		for name,date in updates do
			headFunctions.notifyChat("all",`{name} last updated: {date}`)
		end
	end
end)]]

headFunctions.notify({msg=`AntiSkid {aversion} successfully loaded.\nI am back i guess. This script won't stop every skid script obviously i need feedback and help with making more antis.`})

return nil