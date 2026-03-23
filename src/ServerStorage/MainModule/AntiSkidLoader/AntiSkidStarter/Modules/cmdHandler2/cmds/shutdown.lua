local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local players=funcs.getservice("Players")

module.name="shutdown"
module.aliases=table.freeze{"sd"}
module.description="shutdowns this server"
module.multiTask=true
module.plrReq=true
module.whitelistOnly=true

rbxfuncs.destroy(script)

function module.f(data)
	local reason=data.args and #data.args>0 and `Server has been shutdown manually by {data.plr.Name} Reason: {table.concat(data.args," ")}` or `Server has been shutdown manually by {data.plr.Name} Reason: unspecified`
	
	local function loopkick()
		for i,v in rbxfuncs.getplayers(players) do
			rbxfuncs.kick(v,reason)
		end
	end

	rbxfuncs.connect(players.PlayerAdded,function(plr)
		rbxfuncs.kick(plr,reason)
		loopkick()
	end)
	
	loopkick()
end



return module