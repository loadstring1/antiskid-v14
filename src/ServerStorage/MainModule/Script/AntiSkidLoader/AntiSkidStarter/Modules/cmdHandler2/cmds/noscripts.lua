local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

module.name="noscripts"
module.aliases=table.freeze{"noscr","descript","ks"}
module.description="Removes and disables all scripts"

rbxfuncs.destroy(script)

function module.f(data)
	if data.plr~=nil and handler.checkCooldown(module.name,5) then
		handler.notifyChat(data.plr,"Cooldown 5 seconds.")
		return
	end
	
    local count=0

	for i,v in rbxfuncs.getdescendants(game) do
		yield()
		if rbxfuncs.isa(v,"LuaSourceContainer")==false then continue end
		count+=1
        funcs.softdestroy(v)
	end
	
	funcs.notifyChat("all",`Cleared {count} scripts successfully.`)
    if funcs.isClient then return end

    for i,v in rbxfuncs.getchildren(rbxfuncs.clone(handler.cmds.resetserver.main.StarterPlayerScripts)) do
		v.Parent=rbxfuncs.findfirstchildofclass(funcs.getservice("StarterPlayer"),"StarterPlayerScripts")
		yield()
	end
end

return module