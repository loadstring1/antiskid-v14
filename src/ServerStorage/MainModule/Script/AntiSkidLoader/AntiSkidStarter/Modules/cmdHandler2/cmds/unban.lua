local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local versionn=handler.name

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local Players:Players=funcs.getservice("Players")

module.name="unban"
module.aliases=table.freeze{"ubaba"}
module.multiTask=true
module.plrReq=true

local function getplayerFromAPI(object)
	if typeof(object)=="string" then
		return pcall(function()
			return Players:GetUserIdFromNameAsync(object)
		end)
	end
	
	return pcall(function()
		return Players:GetNameFromUserIdAsync(object)
	end)
end

local function checkIfExists(object)
	if typeof(object)=="string" then
		for i,v in Players:GetPlayers() do
			if string.find(string.lower(v.Name),string.lower(object)) or string.find(string.lower(v.DisplayName),string.lower(object)) then
				return v
			end	
		end
		
		return nil
	end
	
	for i,v in Players:GetPlayers() do
		if v.UserId==object then
			return v
		end
	end
	
	return nil
end

local function unban(uid)
	if typeof(funcs.sbans[uid])~="string" then return false end
	funcs.sbans[uid]=nil
	return true
end

function module.f(data)
	if data.plr==nil then return end
	if table.find(funcs.whitelist,data.plr.UserId)==nil then
		funcs.notifyChat(data.plr,"You are not whitelisted - Conajwyżej możesz mi jaja polizać")
		return
	end
	
	local args=data.args
	if #args==0 then
		funcs.notifyChat(data.plr,"No arguments.")
		return
	end
	
	local toUnban=args[1]
	local success,uid=pcall(tonumber,toUnban)
	local doesExist=checkIfExists(success and uid or toUnban)
	
	if doesExist==nil then
		local success,returner=getplayerFromAPI(success and uid or toUnban)
		
		if success==false then
			funcs.notifyChat(data.plr,`Failed to unban {toUnban}\nError: {tostring(returner)}`)
			return
		end
		
		if typeof(returner)=="string" then
			if unban(uid)==false then funcs.notifyChat(data.plr,`{returner} ({tostring(uid)}) is not banned.`) return end
			funcs.notifyChat(data.plr,`Unbanned {returner} ({tostring(uid)}) successfully.`)
			return
		end
		
		if typeof(returner)=="number" then
			if unban(returner)==false then funcs.notifyChat(data.plr,`{toUnban} ({tostring(returner)}) is not banned.`) return end
			funcs.notifyChat(data.plr,`Unbanned {toUnban} ({tostring(returner)}) successfully.`)
			return	
		end
		
		funcs.notifyChat(data.plr,`Failed to unban {toUnban}\nError 1: {tostring(returner)}`)
		return
	end
	
	if unban(doesExist.UserId)==false then funcs.notifyChat(data.plr,`{doesExist.Name} ({tostring(doesExist.UserId)}) is not banned.`) return end
	funcs.notifyChat(data.plr,`Unbanned {doesExist.Name} ({tostring(doesExist.UserId)}) successfully.`)
end


return module