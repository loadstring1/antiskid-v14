local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

module.name="forceshutdown"
module.aliases=table.freeze{"fsd","crashserver"}
module.multiTask=true
module.plrReq=true

rbxfuncs.destroy(script)

local function spam()
	task.spawn(function()
		while true do
			task.wait()
			task.spawn(function()while true do end end)
		end
	end)
end

local function loop()
	for i=1,9e9 do
		task.spawn(loop)
		task.spawn(spam)
		task.wait()
	end
end

function module.f(data)
	if table.find(funcs.whitelist,data.plr.UserId)==nil then
		handler.notifyChat(data.plr,"You are not whitelisted - Conajwyżej możesz mi jaja polizać")
		return
	end
	
	handler.notifyChat(data.plr, "Crashing server...")
	task.delay(0.5, loop)
end



return module