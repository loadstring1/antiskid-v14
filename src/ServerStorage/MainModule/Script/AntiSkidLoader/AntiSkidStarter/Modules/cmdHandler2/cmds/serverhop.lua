local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

local kick=rbxfuncs.kick
local plr=funcs.lplr
local destroy=rbxfuncs.destroy
local teleportservice=funcs.getservice("TeleportService")
local teleport=teleportservice.Teleport

module.name="serverhop"
module.aliases=table.freeze{"shop"}
module.description="Teleports to another server"

module.multiTask=true
module.supportClient=true
module.onlyClient=true

rbxfuncs.destroy(script)

function module.f()
	pcall(kick,plr,`Server hopping... - {handler.name}`)
	pcall(destroy,plr)
	pcall(teleport,teleportservice,game.PlaceId,plr)
end

return module