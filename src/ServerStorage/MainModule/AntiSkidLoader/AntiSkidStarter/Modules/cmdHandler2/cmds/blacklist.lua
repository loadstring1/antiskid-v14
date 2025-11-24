local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local Players:Players=funcs.getservice("Players")

module.name="blacklist"
module.aliases=table.freeze{"bl","cmdbl","commandblacklist"}
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

local function addToBlacklist(uid)
	if table.find(funcs.whitelist,uid) then return false end
	funcs.blacklist[uid]=true
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
	
	local toBlacklist=args[1]
	local success,uid=pcall(tonumber,toBlacklist)
	local doesExist=checkIfExists(success and uid or toBlacklist)
	
	if doesExist==nil then
		local success2,returner=getplayerFromAPI(success and uid or toBlacklist)
        local username=typeof(returner)=="string" and returner or toBlacklist
        uid=typeof(returner)=="number" and returner or uid
		
		if success2==false or typeof(uid)~="number" then
			funcs.notifyChat(data.plr,`Failed to blacklist {toBlacklist}\nError: {tostring(returner)}`)
			return
		end
		
		if addToBlacklist(uid)==false then funcs.notifyChat(data.plr,`Unable to blacklist whitelisted individual. {username} ({tostring(uid)})`); return end
		funcs.notifyChat(data.plr,`Blacklisted {username} ({tostring(uid)}) successfully.`)
		return
	end
	
	if addToBlacklist(doesExist.UserId)==false then funcs.notifyChat(data.plr,`Unable to blacklist whitelisted individual. {doesExist.Name} ({tostring(doesExist.UserId)})`); return end
	funcs.notifyChat(data.plr,`Blacklisted {doesExist.Name} ({tostring(doesExist.UserId)}) successfully.`)
end


return module