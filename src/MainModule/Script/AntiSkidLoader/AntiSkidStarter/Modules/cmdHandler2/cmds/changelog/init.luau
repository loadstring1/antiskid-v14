local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local changelog=require(script.AntiChangelog)

module.name="changelog"
module.description="Shows full changelog"
module.aliases=table.freeze{}
module.supportClient=true
module.onlyClient=true

rbxfuncs.destroy(script)

function module.f()
	handler.notifyChat(changelog)
end

return module