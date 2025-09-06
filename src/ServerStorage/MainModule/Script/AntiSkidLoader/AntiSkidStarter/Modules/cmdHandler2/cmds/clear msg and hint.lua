local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

local hintAliases={
	"ch",
	"rh",
	"clearhints",
	"resethints",
	"nohints",
	"nohint",
}

module.name="clearmessages"
module.aliases={"cm","resetmessages","nomsg","nomessage","nomessages"}
module.description="Clear hints/Clear messages"
module.supportClient=true

rbxfuncs.destroy(script)

function module.f(data)
	if data.plr~=nil and handler.checkCooldown(module.name,5) then
		handler.notifyChat(data.plr,"Cooldown 5 seconds.")
		return
	end
	
	local toLook=table.find(hintAliases,string.lower(data.alias)) and "Hint" or "Message"
	
	if funcs.isClient==false then funcs.remoteComms.invokeClients({method="runCommand",cmdName="clearmessages",data={alias=data.alias}}) end
	
	
	for i,v in rbxfuncs.getdescendants(game) do
		yield()
		if v.ClassName~=toLook then continue end
		v.Text=""
		funcs.softdestroy(v)
	end
	
	funcs.notifyChat("all",`Cleared all {toLook=="Hint" and "hints" or "messages"} successfully.`)
end

for i,v in hintAliases do
	table.insert(module.aliases,v)
end
table.freeze(module.aliases)

return module