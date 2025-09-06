local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

local players=funcs.getservice("Players")

module.name="checkremote"
module.aliases=table.freeze{"cr"}
module.description="Checks last remote pings"
module.plrReq=true
module.multiTask=true

rbxfuncs.destroy(script)

function module.f(data)
	local toAnnounce=[[Remote connection status:]]
	for i,v in funcs.remoteComms.clientpings do
		if v==nil then return end
		local plr=rbxfuncs.getplayerbyuserid(players,i)
		if plr==nil then return end
		
		toAnnounce=`{toAnnounce}\n{plr.Name} Last ping: {tostring(os.clock()-v)}`
	end
	
	for i,v in rbxfuncs.getplayers(players) do
		if funcs.remoteComms.clientpings[v.UserId]==nil then
			toAnnounce=`{toAnnounce}\n{v.Name} - remote doesnt work.`
		end
	end
	
	funcs.notifyChat(data.plr,toAnnounce)
end

return module