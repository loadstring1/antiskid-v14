local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

local Players=funcs.getservice("Players")

module.name="resetmap"
module.aliases=table.freeze{"rm"}
module.description="Resets map and clears terrain"
module.supportClient=true

function module.f(data)
	if data.plr~=nil and handler.checkCooldown(module.name,5) then
		handler.notifyChat(data.plr,"Cooldown 5 seconds.")
		return
	end
	
	if funcs.isClient==false then handler.remoteComms.invokeClients({method="runCommand",cmdName="resetmap",data={}}) task.wait(0.4) end

	for i,v in rbxfuncs.getplayers(Players) do
		yield()
		pcall(rbxfuncs,v.Character)
		task.spawn(pcall,function() v.Character=nil end)
	end
	
	local workadded
	workadded=rbxfuncs.connect(workspace.DescendantAdded,function(d)
		if workadded==nil then return end
		task.delay(0,pcall,rbxfuncs.destroy,d)
		pcall(rbxfuncs.destroy,d)
	end)
	
	for i,v in rbxfuncs.getchildren(workspace) do
		yield()
		if funcs.CheckInstance(v)==false then continue end
		pcall(rbxfuncs.clear,v)
		pcall(rbxfuncs.destroy,v)
	end
	
	task.spawn(pcall,workspace.Terrain.Clear,workspace.Terrain)
	rbxfuncs.disconnect(workadded)
	workadded=nil
	
	if funcs.isClient then return end
	
	local maps=handler.maps
	local childrenMaps=rbxfuncs.getchildren(maps)
	
	local randomMap=typeof(data.args[1])=="string" and rbxfuncs.findfirstchild(maps,data.args[1]) or childrenMaps[math.random(1,#childrenMaps)]
	rbxfuncs.clone(randomMap).Parent=workspace
	
	for i,v in rbxfuncs.getplayers(Players) do
		task.spawn(pcall,v.LoadCharacter,v)
	end
	
	handler.notifyChat("all","Map successfully reset.")
end

return module