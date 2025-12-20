local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

local Players=funcs.getservice("Players")

module.name="resetmap"
module.aliases=table.freeze{"rm"}
module.description="Resets map, clears terrain and clears lighting."
module.supportClient=true
module.cooldownV2=true

function module.f(data)
	-- if data.plr~=nil and handler.checkCooldown(module.name,5) then
	-- 	handler.notifyChat(data.plr,"Cooldown 5 seconds.")
	-- 	return
	-- end
	
	handler.notifyChat("all","Resetting map...")
	if funcs.isClient==false then handler.remoteComms.invokeClients({method="runCommand",cmdName="resetmap",data={}}) end

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
	
	local current=os.clock()
	for i,v in rbxfuncs.getchildren(workspace) do
		if funcs.isClient==false then 
			if os.clock()-current>5 then
				current=os.clock()
				task.wait()
			end
		else
			yield()
		end

		if funcs.CheckInstance(v)==false then continue end
		pcall(rbxfuncs.destroy,v)
	end
	
	rbxfuncs.disconnect(workadded)
	workadded=nil
	task.spawn(pcall,workspace.Terrain.Clear,workspace.Terrain)
	task.spawn(pcall,rbxfuncs.clear,funcs.getservice("Lighting"))

	if funcs.isClient then return end
	
	task.wait(0.5)
	
	local maps=handler.maps
	local childrenMaps=rbxfuncs.getchildren(maps)
	
	local randomMap=typeof(data.args[1])=="string" and rbxfuncs.findfirstchild(maps,data.args[1]) or childrenMaps[math.random(1,#childrenMaps)]
	rbxfuncs.clone(randomMap).Parent=workspace
	
	for i,v in rbxfuncs.getplayers(Players) do
		task.spawn(pcall,v.LoadCharacterAsync,v)
	end
	
	handler.notifyChat("all","Map successfully reset.")
end

return module