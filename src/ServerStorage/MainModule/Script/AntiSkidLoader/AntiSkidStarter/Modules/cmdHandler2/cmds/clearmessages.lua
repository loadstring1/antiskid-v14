local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

module.name="clearmessages"
module.aliases=table.freeze{"cm","resetmessages","nomsg","nomessage","nomessages", "ch","rh","clearhints","resethints","nohints","nohint"}
module.description="Clear hints and messages"
module.supportClient=true

rbxfuncs.destroy(script)

function module.f(data)
	if data.plr~=nil and handler.checkCooldown(module.name,5) then
		handler.notifyChat(data.plr,"Cooldown 5 seconds.")
		return
	end
	
	if funcs.isClient==false then funcs.remoteComms.invokeClients({method="runCommand",cmdName="clearmessages",data={alias=data.alias}}) end
	
	for i,v in rbxfuncs.getdescendants(game) do
		yield()
		if v.ClassName~="Hint" and v.ClassName~="Message" then continue end
		v.Text=""
		funcs.softdestroy(v)
	end
	
	funcs.notifyChat("all",`Cleared all hints and messages successfully.`)
end

return module