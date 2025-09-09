local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local uis:UserInputService=funcs.getservice("UserInputService")

module.name="fixmouse"
module.aliases=table.freeze{}
module.description="Fixes mouse icon."

module.multiTask=true
module.supportClient=true
module.onlyClient=true

rbxfuncs.destroy(script)

function module.f(data)
	if uis.MouseEnabled==false then return end
	
	uis.MouseIconEnabled=true
	uis.MouseIcon=""
	funcs.notifyChat("Your mouse icon has been fixed.")	
end

return module