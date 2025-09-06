local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs
local yield=funcs.yielder()

local replicatedstorage=funcs.getservice("ReplicatedStorage")

local string=string
local script=script
local rawget=rawget
local rawset=rawset
local getfenv=getfenv
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
local print=print
local Enum=Enum

rbxfuncs.destroy(script)

setfenv(0,table.freeze{})
setfenv(1,table.freeze{})

local mmmmmmmmmmmmmmIhateKohl={}

local function yieldYourselfPlease()
	return coroutine.yield()
end

local opMeta={
	__index=function(_,ind)
		if ind=="GetNetworkPing" or ind=="FireClient" or ind=="unescapeRichText" or ind=="log" then
			return yieldYourselfPlease
		end
		
		if ind=="FrameTime" then
			return 1
		end
		
		return mmmmmmmmmmmmmmIhateKohl
	end,
}

setmetatable(mmmmmmmmmmmmmmIhateKohl,opMeta)
table.freeze(mmmmmmmmmmmmmmIhateKohl)
opMeta.__metatable=table.freeze{}
table.freeze(opMeta)

local function gameAdded(inst)
	if inst.ClassName=="Player" or inst.ClassName=="PlayerGui" then
		return
	end
	
	if inst.Name=="Kohl's Admin Source" and inst.Parent==replicatedstorage then
		task.delay(funcs.isClient and 0 or 5,funcs.softdestroy,inst)
		
		for i,v in rbxfuncs.getdescendants(inst) do
			if funcs.isClient==false and v.ClassName=="Script" and v.RunContext==Enum.RunContext.Client then
				v.Enabled=false
				break
			end
			
			if funcs.isClient and v.ClassName=="ModuleScript" and v.Name=="Clack" then
				task.spawn(function()
					rawset(require(v),"sound",function()return coroutine.yield() end)
				end)
				break
			end
		end
		return
	end
	
	if string.find(string.lower(inst.Name),"hdadmin") then
		funcs.softdestroy(inst)
		if funcs.isClient==false and funcs.canNotify("antihd") then funcs.notify({msg="Attempted to block hd admin from loading."}) end
	end
end

local function removeLeftOverAdminGuis()
	if funcs.isClient==false then return end
	
	local soundservice=funcs.getservice("SoundService")
	local kaSounds=rbxfuncs.findfirstchild(soundservice,"_KASounds")
	
	if kaSounds then
		funcs.softdestroy(kaSounds)
	end
	
	for i,v in rbxfuncs.getchildren(rbxfuncs.findfirstchildofclass(funcs.lplr,"PlayerGui")) do
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
	if typeof(kohl)~="table" then return end
	if kohl==mmmmmmmmmmmmmmIhateKohl then return end
	
	pcall(rawset,shared,"_K_INTERFACE",mmmmmmmmmmmmmmIhateKohl)
	pcall(table.clear,kohl)
	pcall(setmetatable,kohl,opMeta)
	pcall(table.freeze,kohl)
	
	task.spawn(removeLeftOverAdminGuis)
	if funcs.isClient==false and funcs.canNotify("antikohl") then funcs.notify({msg="All kohls commands are now disabled and kohls typing sound disabled"}) end
end

local function checkForHdAdmin()
	local hdadmin=rawget(_G,"HDAdminMain")
	if typeof(hdadmin)~="table" then return end
	if table.isfrozen(hdadmin) then return end
	
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
end

rbxfuncs.connectparallel("onHeartbeat",onHeart)
funcs.connect("onHeartbeat",onHeart)

rbxfuncs.connect(game.DescendantAdded,function(inst)
	if inst.Name=="Adonis_Loader" and inst.ClassName=="Model" then
		funcs.softdestroy(inst)
		if funcs.isClient==false and funcs.canNotify("antiadonis") then funcs.notify({msg="Attempted to block adonis from loading."}) end
		return
	end
end)

funcs.connect("OnInstance",gameAdded)
for i,v in rbxfuncs.getdescendants(game) do
	yield()
	task.spawn(gameAdded,v)
end

antis3.warner(script.Name)

return nil