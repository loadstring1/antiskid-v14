local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local Players:Players=funcs.getservice("Players")

module.name="unblacklist"
module.aliases=table.freeze{"unbl","cmdunbl","commandunblacklist"}
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

local function unblacklist(uid)
	if typeof(funcs.blacklist[uid])~="boolean" then return false end
	funcs.blacklist[uid]=nil
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
	
	local toUnblacklist=args[1]
	local success,uid=pcall(tonumber,toUnblacklist)
	local doesExist=checkIfExists(success and uid or toUnblacklist)
	
	if doesExist==nil then
		local success2,returner=getplayerFromAPI(success and uid or toUnblacklist)
		local username=typeof(returner)=="string" and returner or toUnblacklist
		uid=typeof(returner)=="number" and returner or uid

		if success2==false or typeof(uid)~="number" then
			funcs.notifyChat(data.plr,`Failed to unblacklist {toUnblacklist}\nError: {tostring(returner)}`)
			return
		end
		
		if unblacklist(uid)==false then funcs.notifyChat(data.plr,`{username} ({tostring(uid)}) is not blacklisted.`); return end
		funcs.notifyChat(data.plr,`Unblacklisted {username} ({tostring(uid)}) successfully.`)
		return
	end
	
	if unblacklist(doesExist.UserId)==false then funcs.notifyChat(data.plr,`{doesExist.Name} ({tostring(doesExist.UserId)}) is not blacklisted.`); return end
	funcs.notifyChat(data.plr,`Unblacklisted {doesExist.Name} ({tostring(doesExist.UserId)}) successfully.`)
end

return module