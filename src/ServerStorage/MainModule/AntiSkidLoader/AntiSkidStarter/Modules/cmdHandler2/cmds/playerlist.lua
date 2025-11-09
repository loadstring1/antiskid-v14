--!nocheck
local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

local NetworkServer:NetworkServer=funcs.getservice("NetworkServer")
local yield=funcs.yielder()

module.name="playerlist"
module.aliases=table.freeze{"plrlist","net"}
module.description="List all players"
module.multiTask=true

rbxfuncs.destroy(script)

function module.f(data)
	local plrs=[[list of players:]]
	
	for i,v:ServerReplicator in rbxfuncs.getchildren(NetworkServer) do
		yield()
		if funcs.CheckInstance(v)==false then continue end
		if v.ClassName~="ServerReplicator" then continue end
		
		local success,plr:Player=pcall(v.GetPlayer,v)
		if success==false or typeof(plr)~="Instance" then continue end
		
		plrs=`{plrs}\n{plr.Name}{plr.Name~=plr.DisplayName and ` - {plr.DisplayName} ` or ` `}({tostring(plr.UserId)}) - isUsingFakeChar {plr.Character==nil}`
	end
	
	handler.notifyChat(data.plr,plrs)
end

return module