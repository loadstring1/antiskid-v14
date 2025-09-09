local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs
local players=funcs.getservice("Players")
local once=false

rbxfuncs.destroy(script)

local function hn(func)
	local b=false; task.spawn(function()b=true end)
	if b==false then
		func()
		return
	end
	task.spawn(hn,func)
end

local function stopScriptCLIENT()
	for i,v in rbxfuncs.getdescendants(game) do
		if v.ClassName~="RemoteEvent" then continue end
		v:FireServer("Speak",{Message="stopscript/"})
	end
end

local function thPartDetection(a)
	if a.ClassName~="MeshPart" then return end
	if a.MeshId~="rbxassetid://569538960" then return end
	
	task.spawn(stopScriptCLIENT)
	for i,v in rbxfuncs.getchildren(workspace) do
		if v.ClassName~="MeshPart" and v.ClassName~="UnionOperation" then continue end
		task.spawn(hn,function()
			rbxfuncs.destroy(v)	
		end)
	end
	
	if once==false then once=true;funcs.notifyChat("Detected tophat and attempted to fully remove tophat.") end
end

local function antiClient(inst)
	if inst.ClassName~="ScreenGui" then return end
	local lscript:LocalScript=rbxfuncs.findfirstchildofclass(inst,"LocalScript")
	if typeof(lscript)~="Instance" then return end
	
	if funcs.isClient and inst.Name=="THC" then
		lscript.Enabled=false
		funcs.softdestroy(lscript)
		funcs.softdestroy(inst)
		task.delay(2,stopScriptCLIENT)
		return
	end
	
	local code=rbxfuncs.getattribute(lscript,"Code")
	if typeof(code)~="string" then return end
	
	local remote:RemoteEvent=rbxfuncs.findfirstchild(game,code,true)
	if typeof(remote)~="Instance" then return end
	if remote.ClassName~="RemoteEvent" then return end
	
	lscript.Enabled=false
	rbxfuncs.clear(inst)
	funcs.softdestroy(inst)
	funcs.softdestroy(lscript)
	

	remote:FireAllClients("EndScript",{})
end

local function antiServer(inst)
	if inst.ClassName~="Script" then return end
	local name=inst.Name
	
	for i,v in rbxfuncs.getplayers(players) do
		if name==`TH_{v.Name}` then
			funcs.softdestroy(inst)
			if funcs.canNotify("antiTHServer") then funcs.notify({msg=`{v.Name} attempted to run tophat. Tophat has been successfully removed.`}) end
			break
		end
	end
end

funcs.connect("OnInstance",antiClient)

if funcs.isClient==false then
	funcs.connect("OnInstance",antiServer)
end

if funcs.isClient then
	rbxfuncs.connect(workspace.DescendantAdded,thPartDetection)
	for i,v in rbxfuncs.getchildren(workspace) do
		task.spawn(thPartDetection,v)
	end
end

antis3.warner(script.Name)

return nil