--because ofc for debugging purposes i will use print and getfenv in studio but not in prod
--!nolint
local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs
local yield=funcs.yielder()

local replicatedstorage=funcs.getservice("ReplicatedStorage")

local string=string
local script=script
local rawget=rawget
local rawset=rawset
local shared=shared
local _G=_G
local table=table
local setfenv=setfenv
local typeof=typeof
local pcall=pcall
local task=task
local require=require
local getmetatable=getmetatable
local setmetatable=setmetatable
local game=game
local coroutine=coroutine
local Enum=Enum
local getfenv=getfenv
local print=print

rbxfuncs.destroy(script)
setfenv(1, table.freeze{})

local IhateKohl

local kohlFakeMeta={
	__index=funcs.securefunction(function(_,ind)
		if ind=="GetNetworkPing" or ind=="FireClient" or ind=="unescapeRichText" or ind=="log" then
			return coroutine.yield
		end
		
		if ind=="FrameTime" then
			return 1
		end
		
		return IhateKohl
	end),
}

IhateKohl=funcs.securetable(kohlFakeMeta)

-- the most difficult MR.ROBOT HACK
local donothingSecure=funcs.securefunction(function()end)
local WARN_ABUSE_DETECTION_ONCE=false

--YEARS of gatekeeping this btw - finally leaked it out of my own free will
local ihateAbuseDetection=funcs.isClient==false and funcs.securetable({
	__index=funcs.securefunction(function(self)
		local env=getfenv(2)
		if table.isfrozen(env) or pcall(rawset,env,"test",nil)==false then return nil end

		rawset(env,"require",funcs.securefunction(function(module)
			if typeof(module)=="Instance" and module.Parent then
				local assets=module.Parent
				local moderationModule=assets:FindFirstChild("ModerationModule")

				if moderationModule~=nil and moderationModule.ClassName=="ModuleScript" then 
					rawset(env,"require",nil)
					rawset(env,"task",table.freeze{
						["spawn"]=coroutine.yield,
						["wait"]=coroutine.yield,
					})

					local moderationTable=require(moderationModule)
					if typeof(moderationTable)~="table" or pcall(rawset,moderationTable,"test",nil)==false then return require(module) end

					rawset(moderationTable,"Shutdown",donothingSecure)
					rawset(moderationTable,"Kick",donothingSecure)
					rawset(moderationTable,"Ban",donothingSecure)

					local banning=rawget(moderationTable,"Start")

					if typeof(banning)=="function" and pcall(rawset,getfenv(banning),"test",nil) then
						rawset(getfenv(banning),"pairs",funcs.securefunction(function(possibleBans)
							pcall(table.clear,possibleBans)
							return funcs.securefunction(function()return nil;end),{},nil
						end))
					end

					if WARN_ABUSE_DETECTION_ONCE==false then
						WARN_ABUSE_DETECTION_ONCE=true

						funcs.notify({msg="Abuse detection detected. All shutdown antis are now disabled and some AD loops are now suspended."})
						funcs.notifyChat("all","Abuse detection detected. All shutdown antis are now disabled and some AD loops are now suspended.")
					end
				end
			end

			return require(module)
		end))

		return self
	end),
}) or nil

--in case current code breaks it lol
-- local IhateKohl={}

-- setmetatable(IhateKohl,opMeta)
-- table.freeze(IhateKohl)
-- opMeta.__metatable=table.freeze{}
-- table.freeze(opMeta)

-- local function gameAdded(inst)
-- 	if inst.ClassName=="Player" or inst.ClassName=="PlayerGui" then
-- 		return
-- 	end
	
-- 	if inst.Name=="Kohl's Admin Source" and inst.Parent==replicatedstorage then
-- 		task.delay(funcs.isClient and 0 or 5,funcs.softdestroy,inst)
		
-- 		for i,v in rbxfuncs.getdescendants(inst) do
-- 			if funcs.isClient==false and v.ClassName=="Script" and v.RunContext==Enum.RunContext.Client then
-- 				v.Enabled=false
-- 				break
-- 			end
			
-- 			if funcs.isClient and v.ClassName=="ModuleScript" and v.Name=="Clack" then
-- 				task.spawn(function()
-- 					rawset(require(v),"sound",function()return coroutine.yield() end)
-- 				end)
-- 				break
-- 			end
-- 		end
-- 		return
-- 	end
	
-- 	if string.find(string.lower(inst.Name),"hdadmin") then
-- 		funcs.softdestroy(inst)
-- 		if funcs.isClient==false and funcs.canNotify("antihd") then funcs.notify({msg="Attempted to block hd admin from loading."}) end
-- 	end
-- end

local function removeLeftOverAdminGuis()
	if funcs.isClient==false then return end
	
	local soundservice=funcs.getservice("SoundService")
	local kaSounds=rbxfuncs.findfirstchild(soundservice,"_KASounds")
	
	if kaSounds then
		funcs.softdestroy(kaSounds)
	end
	
	for i,v in rbxfuncs.getchildren(funcs.plrGui) do
		yield()
		if funcs.CheckInstance(v)==false then continue end
		local name=string.lower(v.Name)

		if string.find(name,"flux") or string.find(name,"topbar") then
			funcs.softdestroy(v)
		end
	end
end

local function checkForKohl()
	local kohl=rawget(shared,"_K_INTERFACE")
	if typeof(kohl)~="table"
	or kohl==IhateKohl then return end
	
	pcall(rawset,shared,"_K_INTERFACE",IhateKohl)
	pcall(table.clear,kohl)
	pcall(setmetatable,kohl,kohlFakeMeta)
	pcall(table.freeze,kohl)
	
	task.spawn(removeLeftOverAdminGuis)
	if funcs.isClient==false and funcs.canNotify("antikohl") then funcs.notify({msg="All kohls commands are now disabled and kohls typing sound disabled"}) end
end

local function checkForHdAdmin()
	local hdadmin=rawget(_G,"HDAdminMain")
	if typeof(hdadmin)~="table"
	or table.isfrozen(hdadmin)
	or funcs.isClient==false and hdadmin==ihateAbuseDetection then return end
	
	local meta=getmetatable(hdadmin)
	
	if typeof(meta)=="table" and table.isfrozen(meta)==false then
		pcall(table.clear,meta)
		pcall(table.freeze,meta)
	end
	
	pcall(table.clear,hdadmin)
	pcall(table.freeze,hdadmin)
	
	task.spawn(removeLeftOverAdminGuis)
	if funcs.isClient==false and funcs.canNotify("antihd2") then funcs.notify({msg="All hd admin's commands are now disabled"}) end
end

local function onHeart()
	checkForKohl()
	checkForHdAdmin()

	if funcs.isClient==false then
		pcall(rawset,_G,"HDAdminMain",ihateAbuseDetection)
	end
end

funcs.connect("onHeartbeat",onHeart)

rbxfuncs.connect(game.DescendantAdded,function(inst)
	if inst.Name=="Adonis_Loader" and inst.ClassName=="Model" then
		funcs.softdestroy(inst)
		if funcs.isClient==false and funcs.canNotify("antiadonis") then funcs.notify({msg="Attempted to block adonis from loading."}) end
		return
	end
end)

funcs.queryInstanceAdded({ClassName="ModuleScript",Name="Kohl's Admin Source",Parent=replicatedstorage},function(kohlmain)
	task.delay(funcs.isClient and 0 or 5,funcs.softdestroy,kohlmain)
	--print(kohlmain,"detected on clientside?",funcs.isClient)

	if funcs.isClient then
		funcs.queryInstances({ClassName="ModuleScript",Name="Clack"},kohlmain,function(module)
			rawset(require(module),"sound",coroutine.yield)
		end)
		return
	end

	funcs.queryInstances({ClassName="Script",RunContext=Enum.RunContext.Client},kohlmain,function(client)
		client.Enabled=false
	end)

	funcs.queryInstances({ClassName="Folder",Name="Kohl's Admin"},funcs.getservice("ServerScriptService"),funcs.softdestroy)
	funcs.queryInstances({ClassName="Folder",Name="_KServerAddons"},funcs.getservice("ServerStorage"),funcs.softdestroy)
end)

funcs.queryInstanceAdded({lowerfind="hdadmin",excludeclasses={"PlayerGui","Player"}},function(inst)
	-- if inst.ClassName=="Player" or inst.ClassName=="PlayerGui" then
	-- 	return
	-- end

	--print(inst.ClassName)
	funcs.softdestroy(inst)
	if funcs.isClient==false and funcs.canNotify("antihd") then funcs.notify({msg="Attempted to block hd admin from loading."}) end
end)

-- funcs.connect("OnInstance",gameAdded)
-- for i,v in rbxfuncs.getdescendants(game) do
-- 	yield()
-- 	task.spawn(gameAdded,v)
-- end

antis3.warner(script.Name)

return nil