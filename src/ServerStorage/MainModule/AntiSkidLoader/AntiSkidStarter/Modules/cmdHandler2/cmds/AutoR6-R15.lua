local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

local Players:Players=funcs.getservice("Players")


module.name="autor6"
module.aliases=table.freeze{"autor15"}
module.cache={}
module.description="Auto convert your avatar to R6 or R15"
module.multiTask=true
module.plrReq=true

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local function disconnectPrevious(plr,cached)
	local mode=cached.mode
	cached.connection:Disconnect()
	table.clear(cached)
	module.cache[plr.UserId]=nil
	return mode
end

function module.f(data,...)
	local player:Player=data.plr
	local cached=module.cache[player.UserId]
	local mode=string.split(data.alias,"auto")[2]
	mode=mode and Enum.HumanoidRigType[string.upper(mode)]
	
	if typeof(mode)~="EnumItem" then
		return
	end
	
	if cached and disconnectPrevious(player,cached)==mode then
		handler.notifyChat(player,`Auto {mode.Name} will no longer automaticially change your rig type.`)
		return
	end

	
	local cachedata={}
	
	local function autochange(char)
		if cachedata.connection==nil then return end

		local humanoid=rbxfuncs.findfirstchildofclass(char,"Humanoid")
		local root=rbxfuncs.findfirstchild(char,"HumanoidRootPart")

		if root and root.ClassName~="Part" or humanoid==nil or humanoid.RigType==mode then
			return
		end
		
		for i,v in rbxfuncs.getdescendants(char) do
			cachedata.yield()
			if v.ClassName=="Script" or v.ClassName=="LocalScript" then
				v.Disabled=true
			end
		end
		
		task.delay(0,handler.runCommand,"r6",{plr=player,alias=mode.Name,silent=true})
	end
	
	cachedata.mode=mode
	cachedata.yield=funcs.yielder()
	cachedata.connection=rbxfuncs.connect(player.CharacterAdded,autochange)
	module.cache[player.UserId]=cachedata
	
	handler.notifyChat(player,`Auto {mode.Name} will change your rig type automaticially on respawn.`)
	
	local char=player.Character
	if char then
		autochange(char)
	end
end

funcs.connect("OnLeave",function(plr)
	local cached=module.cache[plr.UserId]
	
	if cached==nil then
		return
	end
	
	disconnectPrevious(plr,cached)
end)

return module