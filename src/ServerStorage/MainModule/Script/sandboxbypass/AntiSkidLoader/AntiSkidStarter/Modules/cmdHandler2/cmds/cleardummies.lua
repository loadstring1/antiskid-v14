local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

local players=funcs.getservice("Players")

rbxfuncs.destroy(script)

module.name="cleardummies"
module.aliases=table.freeze{"cd","cleardummy"}
module.plrReq=true
module.multiTask=true
module.description="Clear all dummies"

function module.f(data)
	local amount=0
	for i,v in rbxfuncs.getchildren(workspace) do
		yield()
		if funcs.CheckInstance(v)==false then continue end
		if rbxfuncs.getplayerfromcharacter(players,v) then continue end
		if v.ClassName~="Model" then continue end
		if rbxfuncs.findfirstchildofclass(v,"Humanoid")==nil then continue end
		
		pcall(rbxfuncs.destroy,v)
		task.delay(0,pcall,rbxfuncs.destroy,v)
		amount+=1
	end
	
	funcs.notifyChat(data.plr,`Cleared {amount} dummies successfully.`)
end

return module