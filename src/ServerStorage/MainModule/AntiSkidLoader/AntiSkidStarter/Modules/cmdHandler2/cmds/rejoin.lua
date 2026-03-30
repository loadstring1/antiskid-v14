local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

local plr=funcs.lplr
local teleportservice=funcs.getservice("TeleportService")
local toplace=teleportservice.TeleportToPlaceInstance

module.name="rejoin"
module.aliases=table.freeze{"rj"}
module.description="Teleports to the same server"

module.multiTask=true
module.supportClient=true
module.onlyClient=true

rbxfuncs.destroy(script)

function module.f(data)
	funcs.notifyChat("Attempting to rejoin...")
	pcall(toplace,teleportservice,game.PlaceId,game.JobId,plr)
end

return module