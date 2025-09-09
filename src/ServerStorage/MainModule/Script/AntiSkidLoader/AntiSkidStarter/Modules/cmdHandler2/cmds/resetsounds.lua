local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

module.name="resetsounds"
module.aliases=table.freeze{
	"ms",
	"mutesounds",
	"nos",
	"nosounds"
}
module.cooldown={}
module.description="Mutes all sounds"
module.supportClient=true

function module.f(data)
	if data.plr~=nil and handler.checkCooldown(module.name,5) then
		handler.notifyChat(data.plr,"Cooldown 5 seconds.")
		return
	end
	
	if funcs.isClient==false then funcs.remoteComms.invokeClients({method="runCommand",cmdName="resetsounds",data={}}) end
	for i,v in rbxfuncs.getdescendants(game) do
		yield()
		if v.ClassName~="Sound" then continue end
		local mute:EqualizerSoundEffect=rbxfuncs.instnew("EqualizerSoundEffect")
		mute.Parent=v
		mute.HighGain=-80
		mute.LowGain=-80
		mute.MidGain=-80
		mute.Priority=2147483647
		mute.Enabled=true
		
		rbxfuncs.parallelconnection(mute.Changed,function(change)
			funcs.softdestroy(v)
			funcs.softdestroy(mute)
		end)
		
		if mute.Parent~=v or mute.Enabled==false then
			funcs.softdestroy(v)
			funcs.softdestroy(mute)
		end
	end
	
	handler.notifyChat("all","All sounds are now muted")
end

return module