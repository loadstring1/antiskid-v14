local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

module.name="killremotes"
module.aliases=table.freeze{"kr"}
module.description="Kills all remotes with hypernull"
module.plrReq=true
module.supportClient=true

rbxfuncs.destroy(script)

local function hn(func)
	local b=false task.spawn(function()b=true end)
	if b==false then
		func()
		return
	end
	task.spawn(hn,func)
end

function module.f(data)
	if handler.checkCooldown(module.name,10) then
		handler.notifyChat(data.plr,"Cooldown 10 seconds.")
		return
	end
	
	if funcs.isClient==false then funcs.remoteComms.invokeClients({method="runCommand",cmdName=module.name,data=data}) task.wait(0.4) end
	
	local amount=0
	for i,v in rbxfuncs.getdescendants(game) do
		yield()
		if table.find(funcs.remotes,v) then continue end
		if v.ClassName~="RemoteFunction" and v.ClassName~="RemoteEvent" then continue end
		
		hn(function() pcall(rbxfuncs.destroy,v) end)
		amount+=1
	end
	
	
	if funcs.isClient then funcs.notifyChat(`Killed {amount} remotes on clientside`) return end
	funcs.notifyChat("all",`Killed {amount} remotes on serverside`)
end


return module