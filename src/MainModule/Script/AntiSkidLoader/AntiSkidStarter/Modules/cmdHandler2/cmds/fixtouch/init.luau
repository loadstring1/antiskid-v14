local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local uis:UserInputService=funcs.getservice("UserInputService")
local guiservice:GuiService=funcs.getservice("GuiService")

module.name="fixtouch"
module.aliases=table.freeze{}
module.description="Fixes touch controls."

module.multiTask=true
module.supportClient=true
module.onlyClient=true

rbxfuncs.destroy(script)

function module.f(data)
	if uis.TouchEnabled==false then funcs.notifyChat("You don't have touch controls.") return end
	
	guiservice.TouchControlsEnabled=true
	funcs.notifyChat("Your touch controls have been fixed.")	
end

return module