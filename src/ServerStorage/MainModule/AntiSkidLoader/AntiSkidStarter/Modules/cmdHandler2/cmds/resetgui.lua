local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

local Players=funcs.getservice("Players")

module.name="resetgui"
module.aliases=table.freeze{"removegui","cleargui","rg","nog","noguis"}
module.description="Removes all guis"
module.supportClient=true

function module.f(data)
	if handler.checkCooldown(module.name,5) then
		handler.notifyChat(data.plr,"Cooldown 5 seconds.")
		return
	end
	
	if funcs.isClient==false then handler.remoteComms.invokeClients({method="runCommand",cmdName="resetgui",data={}}) end
	task.spawn(pcall,rbxfuncs.clear,funcs.getservice("StarterGui"))
	
	for i,v in rbxfuncs.getplayers(Players) do
		yield()
		local plrgui=rbxfuncs.findfirstchildofclass(v,"PlayerGui")
		
		if plrgui==nil then
			if funcs.isClient and v~=funcs.lplr then continue end
			rbxfuncs.kick(v,"No playergui. Client script will automaticially reconnect you. - AntiSkid")
			continue
		end
		
		for i,v in rbxfuncs.getchildren(plrgui) do
			yield()
			if funcs.CheckInstance(v)==false then continue end
			pcall(rbxfuncs.destroy,v)
		end
		
		task.spawn(pcall,rbxfuncs.clear,plrgui)
	end

	task.wait(0.4)
	
	funcs.ResetEngineGUI()
	handler.notifyChat("all","All guis have been reset. Use ;gexe command to get your executor back if it disappeared.")
end

return module