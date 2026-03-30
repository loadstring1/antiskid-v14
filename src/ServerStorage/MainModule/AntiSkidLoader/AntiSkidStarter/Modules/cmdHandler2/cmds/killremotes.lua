local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

module.name="killremotes"
module.aliases=table.freeze{"kr"}
module.description="Kills all remotes with hypernull or supernull - depends if the game is immediate or deferred"
module.plrReq=true
module.supportClient=true

rbxfuncs.destroy(script)

function module.f(data)
	if handler.checkCooldown(module.name,10) then
		handler.notifyChat(data.plr,"Cooldown 10 seconds.")
		return
	end
	
	if funcs.isClient==false then funcs.remoteComms.invokeClients({method="runCommand",cmdName=module.name,data=data}); task.wait(0.4) end
	
	local amount=0
	for i,v in rbxfuncs.getdescendants(game) do
		yield()
		if table.find(funcs.remotes,v) then continue end
		if v.ClassName~="RemoteFunction" and v.ClassName~="RemoteEvent" and v.ClassName~="UnreliableRemoteEvent" then continue end
		
		funcs.multiHN(function() pcall(rbxfuncs.destroy,v) end)
		amount+=1
	end
	
	
	if funcs.isClient then funcs.notifyChat(`Killed {amount} remotes on clientside`); return end
	funcs.notifyChat("all",`Killed {amount} remotes on serverside`)
end


return module