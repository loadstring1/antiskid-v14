local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local tpservice:TeleportService=funcs.getservice("TeleportService")
local reserveServer=tpservice.ReserveServer
local teleportToPrivateServer=tpservice.TeleportToPrivateServer


module.name="privateserver"
module.aliases=table.freeze{"ps"}
module.plrReq=true
module.multiTask=true
module.description="Teleports to private server"

function module.f(data)
	local plr=data.plr
	local success,reserveCode=pcall(reserveServer,tpservice,game.PlaceId)
	
	if success==false then
		handler.notifyChat(plr,`Failed to create private server\nError: {typeof(reserveCode)=="string" and reserveCode or "unknown error"}`)
		return
	end
	
	local success,result=pcall(teleportToPrivateServer,tpservice,game.PlaceId,reserveCode,{plr})
	
	if success==false then
		handler.notifyChat(plr,`Failed to teleport to new private server\nError: {typeof(result)=="string" and result or "unknown error"}`)
		return
	end
	
	handler.notifyChat(plr,`Successfully teleported to a new private server`)
end

return module