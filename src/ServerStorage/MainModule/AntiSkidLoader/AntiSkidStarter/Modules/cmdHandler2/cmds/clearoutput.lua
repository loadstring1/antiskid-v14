local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local logserv:LogService=funcs.getservice("LogService")
local clearoutput=logserv.ClearOutput

module.name="clearoutput"
module.aliases=table.freeze{"co"}
module.supportClient=true
module.multiTask=true
module.description="Clears output"

rbxfuncs.destroy(script)

function module.f(data)
	clearoutput(logserv)
	if funcs.isClient==false then funcs.remoteComms.invokeClients({method="runCommand",data=data,cmdName=module.name}) return end
	if handler.checkCooldown(module.name,10) then return end
	funcs.notifyChat("Output has been cleared")
end

return module