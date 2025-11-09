local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

if funcs.isClient then rbxfuncs.destroy(script) return module end

local flyTool=script.Fly:Clone()
module.name="fly"
module.description="Gives you fly tool"
module.aliases=table.freeze{}
module.multiTask=true
module.plrReq=true

rbxfuncs.destroy(script)

for i,v in flyTool:GetChildren() do
	pcall(function()v.Enabled=true end)
end

function module.f(data)
	if data.plr==nil then return end
	local bp=rbxfuncs.findfirstchildofclass(data.plr,"Backpack")
	
	if bp==nil then
		funcs.notifyChat(data.plr,"Backpack doesn't exist. Please respawn with ;r command")
		return
	end
	
	flyTool:Clone().Parent=bp
	funcs.notifyChat(data.plr,"Successfully given fly tool. (works mobile/PC and supports FE)")
end

return module