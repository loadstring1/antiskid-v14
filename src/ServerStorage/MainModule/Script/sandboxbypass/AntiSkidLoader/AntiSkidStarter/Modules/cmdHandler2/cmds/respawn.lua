local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

module.name="respawn"
module.aliases=table.freeze{"r","re"}
module.description="Respawns character"
module.multiTask=true
module.plrReq=true

rbxfuncs.destroy(script)

function module.f(data,...)
	local _time=os.clock()
	local response
	local running
	
	pcall(rbxfuncs.destroy,data.plr.Character)	
	task.spawn(function()
		pcall(function()
			running=coroutine.running()
			data.plr.Character=nil
			data.plr:LoadCharacter()
			response=os.clock()-_time
		end)
	end)
	
	repeat task.wait() until response or os.clock()-_time>3
	
	if typeof(response)=="number" then
		handler.notifyChat(data.plr,`Respawned successfully with time of {string.sub(tostring(response),1,3)} seconds`)
		return
	end
	
	pcall(task.cancel,running)
	handler.notifyChat(data.plr,"It looks like roblox is taking a very long time to respawn your character. Attempting to respawn with antiskid R6 converter.")
	
	handler.runCommand("r6",{alias="r6",plr=data.plr})
end

return module