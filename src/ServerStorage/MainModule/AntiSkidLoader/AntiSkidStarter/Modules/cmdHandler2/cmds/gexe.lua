local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

module.name="gexe"
module.aliases=table.freeze{"fse"}
module.description="Runs FSE"
module.multiTask=true
module.plrReq=true

rbxfuncs.destroy(script)

function module.f(data)
	funcs.crazyhamburgier(130860510447760)(data.plr.Name)
end

return module