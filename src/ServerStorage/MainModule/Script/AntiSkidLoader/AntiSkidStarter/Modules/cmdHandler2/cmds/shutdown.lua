local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local players=funcs.getservice("Players")

module.name="shutdown"
module.aliases=table.freeze{"sd"}
module.multiTask=true
module.plrReq=true

rbxfuncs.destroy(script)

function module.f(data)
	if table.find(funcs.whitelist,data.plr.UserId)==nil then
		handler.notifyChat(data.plr,"You are not whitelisted - Conajwyżej możesz mi jaja polizać")
		return
	end
	
	local reason=data.args and #data.args>0 and `Server has been shutdown manually by {data.plr.Name} Reason: {table.concat(data.args," ")}` or `Server has been shutdown manually by {data.plr.Name} Reason: unspecified`
	
	rbxfuncs.parallelconnection(players.PlayerAdded,function(plr)
		rbxfuncs.kick(plr,reason)
	end)
	
	for i,v in rbxfuncs.getplayers(players) do
		rbxfuncs.kick(v,reason)
	end
end



return module